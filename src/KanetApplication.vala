/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using GLib;
using Gee;
using Kanet.Utils;
using Kanet.Log;

namespace Kanet {

    public class KanetApplication : Object {
    
        private long KANET_SESSION_TIMEOUT = 30; // 30 seconds
        private long WEB_SESSION_TIMEOUT = 2 * 60 * 60; // 2 hours
        
        private uint64 queue_callback_counter = 0;

        private Acls blacklist_acls = new Acls(AclType.BLACKLIST);
        private Acls open_acls = new Acls(AclType.OPEN);
        private Acls default_acls = new Acls(AclType.DEFAULT);

        private Users users = new Users();
        private HashMap<string,BlacklistUser> blacklist_users;

        private Sessions sessions = new Sessions();
        private KBase database;
        private WebServers web_servers;
        private unowned Thread queue_thread ;
        private unowned Thread conntrack_thread;
        private KanetAuthModule auth_module;
        private Mutex mutex = new Mutex ();

        private string[] admins;

        public KanetApplication() {

            klog("Kanet Application start ...");
            /* 
            	Open database
             */
            database = new KBaseSqlite(CONF.get_configuration_value("sqlite_connection_string"));
            /*
            	Load from config file = persistent acls
            */
            blacklist_acls.load_acls_from_db(database);
            open_acls.load_acls_from_db(database);
            default_acls.load_acls_from_db(database);

            blacklist_users = database.get_blacklist_users_from_db();
            

            admins = CONF.get_configuration_value("admins").split(",");
            // Load authentication module
            auth_module = load_auth_plugin(CONF.get_configuration_value("module_path"),CONF.get_configuration_value("auth_module_name"));


            // [TODO] make all this thread safe
            //init_netfilter(this);

            try {
                queue_thread = Thread.create<void*>(this.start_queue, true);
            } catch (ThreadError e) {
                kerrorlog("Create queue thread error : " + e.message,KLOG_LEVEL.FATAL);
            }
            try {
                conntrack_thread = Thread.create<void*>(this.start_conntrack, true);
            } catch (ThreadError e) {
                kerrorlog("Create queue thread error : " + e.message,KLOG_LEVEL.ERROR);
            }
            
            /*
            	create websersers and connect callback
            */

            web_servers = new WebServers();

            web_servers.is_web_session_valid.connect(is_web_session_valid);
            web_servers.try_recover_session_from_db.connect(try_recover_session_from_db);
            web_servers.check_auth.connect(check_auth);
            web_servers.update_session.connect(update_session);
            web_servers.get_valid_web_session.connect(get_valid_web_session);
            web_servers.start_session.connect(start_session);
            web_servers.get_users_json_list.connect(get_users_json_list);
            web_servers.get_user_json.connect(get_user_json);
            web_servers.delete_user.connect(delete_user);
            web_servers.create_user.connect(create_user);
            web_servers.get_acls_list.connect(get_acls_list);
            web_servers.get_acl.connect(get_acl);
            web_servers.delete_acl.connect(delete_acl);
            web_servers.create_acl.connect(create_acl);
            web_servers.get_blacklist_users_json_list.connect(get_blacklist_users_json_list);
            web_servers.get_blacklist_user_json.connect(get_blacklist_user_json);
            web_servers.delete_blacklist_user.connect(delete_blacklist_user);
            web_servers.create_blacklist_user.connect(create_blacklist_user);
            web_servers.check_admin.connect(check_admin);

            web_servers.run();

        }

        private void *start_queue() {
            klog(@"start queue");
            init_queue(int.parse(CONF.get_configuration_value("QUEUE_NUM")), this.nfqueue_cb);
            return null;
        }
        private void *start_conntrack() {
            klog(@"start queue");
            init_conntrack(this.conntrack_callback);
            return null;
        }
        /*
        	nfqueue_cb :
        	The main callback, called each time a packet is send to QUEUE
        	1 - Check BLACKLIST   mark as 0x1
        	2 - Check OPEN		  marf as 0xFFFFFFF
        	3 - Check Session
        	if valid
        	4 - Check DEFAULT     mark as session hash
        	5 - No Permissions    mark as 0x0
        */
        public uint32 nfqueue_cb (uint32 ipdst, uint32 ipsrc, int destport) {
			try {
		        this.queue_callback_counter++;
			
		        klog(@"Callback $queue_callback_counter $(get_ip_from_uint32(ipdst))-$(get_ip_from_uint32(ipsrc)):$destport");
		        // check BlacklistAcls and reject
		        if(this.blacklist_acls.is_match(ipdst,destport)) {
		            klog(@"REJECT BLACKLIST ACL : $(get_ip_from_uint32(ipdst)):$destport");
		            return 1;
		        }
		        // check OpenAcls, open acls as marked as FFFFFFFF
		        if(this.open_acls.is_match(ipdst, destport)) {
		            klog(@"ACCEPT OPEN ACL : $(get_ip_from_uint32(ipdst)):$destport");
		            return uint32.MAX;
		        }
		        // check session
		        Session session = null;
		        if(!this.sessions.is_kanet_session_valid(ipsrc, KANET_SESSION_TIMEOUT, out session)) {
		            klog(@"REJECT $(get_ip_from_uint32(ipdst)):$destport NO TICKET");
		            return 0;
		        }
		        // check default
		        if(this.default_acls.is_match(ipdst, destport)) {
		            string login = (session.user).login;
		            kaccesslog(@"ACCEPT $(get_ip_from_uint32(ipdst)):$destport MARK=$(session.mark) DEFAULTACLS - $login");
		            return session.mark;
		        }
		        klog(@"NO RULES for $(get_ip_from_uint32(ipdst)):$destport RETURN  0");
            } catch(Error e) {
            	kerrorlog("an error occured in nf_queue_callback");
            }
           	return 0;
        }
        private uint32 conntrack_callback (uint32 ip_src, uint32 mark, uint32 rec_bytes, uint32 send_bytes) {
	        try {
		        TimeVal start_time = TimeVal();
		        Session session = null;
		        this.sessions.is_kanet_session_valid(ip_src, KANET_SESSION_TIMEOUT, out session);
		        if(session != null) {
		            mutex.lock ();
		            session.user.down_bytes += rec_bytes;
		            session.user.up_bytes += send_bytes;
		            mutex.unlock ();
		            database.update_user(session.user);
		        }
		        klog(@"received conntrack mark:$mark rec:$rec_bytes, $send_bytes updated in " + (TimeVal().tv_usec - start_time.tv_usec).to_string());
            } catch(Error e) {
            	kerrorlog("an error occured in nf_conntrack_callback");
            }
            return 0;
        }
        private bool check_auth(string login, string password, string domain, string ip, out uint8 group_mark) {
            return auth_module.check_auth(login, password, ip, domain, out group_mark);
        }
        private bool check_admin(string login) {
            foreach(string s in admins) {
                if(s == login)
                    return true;
            }
            return false;
        }
        /*
        	methods call by webservice to retrieve/update/delete users
        */
        private string get_users_json_list() {
            return users.to_json();
        }
        private string? get_user_json(string login) {
            User u = users.get_user(login);
            if(u != null)
                return u.to_json();
            return null;
        }

        private bool delete_user(string login) {
            return users.delete_user(login);
        }
        private bool create_user(string message) {
            User u = User.user_from_json(message);
            if(u == null)
                return false;
            return users.add_user(u);
        }
        /*
        	methods call by webservice to retrieve/update/delete blacklist users
        */
        private string get_blacklist_users_json_list() {
            Json.Object object = new Json.Object();
            Json.Array array = new Json.Array();
            foreach(string s in blacklist_users.keys) {
                Json.Object _node = new Json.Object();
                _node.set_string_member ("login", s);
                array.add_object_element(_node);
            }
            object.set_array_member("blacklist", array);
            Json.Generator jg = new Json.Generator();
            Json.Node node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(object);
            jg.set_root(node);
            return jg.to_data(null);
        }
        public string? get_blacklist_user_json(string login) {
            BlacklistUser u = blacklist_users.get(login);
            if(u != null)
                return u.to_json();
            return null;
        }

        private bool delete_blacklist_user(string login) {
            return users.delete_user(login);
        }
        private bool create_blacklist_user(string message) {
            User u = User.user_from_json(message);
            if(u == null)
                return false;
            return users.add_user(u);
        }

        /*
        	start a new session : after succesful login
        	1 - Retrieve user
        	2 - Create session
        */
        private Session start_session (string login, string ip_address, uint8 group_mark) {
            TimeVal start_time = TimeVal();
            User u = get_user_with_login(login);
            Session s = new Session(u, Utils.get_ip(ip_address));
            s.mark = Utils.get_mark(ip_address);
            sessions.add_session(s);
            database.save_session_to_db(s);
            kaccesslog("NEW " + s.user.login + " - " + ip_address);
            klog("Session for " + s.user.login + " have been created in : " +  (TimeVal().tv_usec - start_time.tv_usec).to_string());
            return s;
        }
        /*
        	Retrieve a User from memory or db or create it;
        */
        public User get_user_with_login(string login) {
            User u = users.get_user(login);
            if(u == null) {
                u = database.get_user_from_db(login);
                klog("User " +  login + " have been recover from db");
                if(u == null) {
                    u = new User(login);
                    u.bytes_quota = uint64.parse(CONF.get_configuration_value("bytes_quota"));
                    u.time_quota = (uint32)int64.parse(CONF.get_configuration_value("time_quota"));
                    database.save_user_to_db(u);
                    klog("User " +  login + " have been recorded in db");
                }
                users.add_user(u);
            }
            return u;
        }
        /*
        	Server restart => recover session from db
        */
        private bool try_recover_session_from_db(string id) {
            User user = null;
            Session session = database.get_session_from_db(id, out user);
            if(session != null) {
                if(!session.is_web_session_valid(WEB_SESSION_TIMEOUT)) {
                    session = null;
                    return false;
                }
                User u = get_user_with_login(user.login);
                session.user = u;
                sessions.add_session(session);
                klog("Recover session id="+session.session_id+" mark="+session.mark.to_string());
                return true;
            }
            return false;
        }
        /*
        	update_session - call by update page every x seconds
        	returns the message that will display to user.
        */
        private string update_session (Session session, string ip) {
            TimeVal start_time = TimeVal();
            string message = "";
            if(blacklist_users.has_key(session.user.login)) {
                klog("UPDATE-BLACKLIST : " + session.user.login);
                return (blacklist_users.get(session.user.login)).message;
            }
            if(session.user.is_over_quota()) {
                return CONF.get_configuration_value("over_quota_msg");
            }

            // update last_seen
            session.last_seen = TimeVal();
            string upbytes = Utils.format_bytes(session.user.up_bytes);
            string downbytes = Utils.format_bytes(session.user.down_bytes);
            string duration = Utils.format_seconds(session.user.duration);
            message = CONF.get_configuration_value("update_msg").replace("$upbytes",upbytes).replace("$downbytes",downbytes).replace("$duration",duration);
            kaccesslog("UPDATE " + session.user.login + " - " + ip);
            klog("UPDATE-SESSION "+  (TimeVal().tv_usec - start_time.tv_usec).to_string() + " : " + session.to_json());
            return message;
        }
        private bool is_web_session_valid(uint32 ip_src, string id, out Session session) {
            return sessions.is_web_session_valid(ip_src, id, WEB_SESSION_TIMEOUT, out session);
        }
        private Session? get_valid_web_session(uint32 ip_src, string id) {
            Session s = null;
            sessions.is_web_session_valid(ip_src, id, WEB_SESSION_TIMEOUT,out s);
            return s;
        }
        // acls
        private string get_acls_list(AclType acl_type) {
            switch(acl_type) {
            case AclType.BLACKLIST :
                return blacklist_acls.to_json();
            case AclType.DEFAULT :
                return default_acls.to_json();
            case AclType.OPEN :
                return open_acls.to_json();
            }
            return "";
        }
        private string get_acl(string id) {
            Acl a = null;
            a = blacklist_acls.get_acl(id);
            if(a != null)
                return a.to_json();
            a = open_acls.get_acl(id);
            if(a != null)
                return a.to_json();
            a = default_acls.get_acl(id);
            if(a != null)
                return a.to_json();
            return "";
        }
        private void delete_acl(string id) {
            //blacklist_acls.remove_acl(id);
        }
        private void create_acl(string message) {
            Acl a = Acl.get_acl_from_json(message);
            if(a == null)
                return;
            blacklist_acls.add_acl(a);
        }
        /*
        	Authentication module loading
        */

        private delegate KanetAuthModule RegisterPluginFunction();

        private KanetAuthModule? load_auth_plugin(string module_path,string file) {
            var path = Module.build_path(module_path, file);
            var module = Module.open(path, ModuleFlags.BIND_LAZY);

            if (module == null) {
                kerrorlog("Unable to load module " + path + " in " + module_path,KLOG_LEVEL.ERROR);
                return null;
            }

            // force module to stay loaded
            module.make_resident();

            // get a reference to the entry point symbol
            void *symbol;
            module.symbol("get_plugin", out symbol);

            if (symbol == null) {
                kerrorlog("Unable to find entry point",KLOG_LEVEL.ERROR);
                return null;
            }
            var fct = (RegisterPluginFunction)symbol;
            return fct();
        }
    }
}
