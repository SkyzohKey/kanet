/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using Soup;
using Kanet.Utils;
using Kanet.Log;

namespace Kanet {
    public class WebServers : Object {

        public signal string? get_users_json_list();
        public signal string? get_user_json(string login);
        public signal bool delete_user(string login);
        public signal bool create_user(string message);
        public signal string get_acls_list(AclType acl_type);
        public signal string get_acl(string id);
        public signal void delete_acl(string id);
        public signal void create_acl(string message);
        public signal string get_blacklist_users_json_list();
        public signal string? get_blacklist_user_json(string login);
        public signal bool delete_blacklist_user(string login);
        public signal bool create_blacklist_user(string message);
        public signal bool check_auth(string login, string password, string domain, string ip, out uint8 group_mark);
        public signal Session start_session (string login, string ip_address, uint8 group_mark);
        public signal string update_session (Session session, string ip);
        public signal bool is_web_session_valid(uint32 ip_src, string id, out Kanet.Session session);
        public signal bool try_recover_session_from_db(string id);
        public signal Session? get_valid_web_session(uint32 ip_src, string id);
        public signal bool check_admin(string login);

        URI login_uri;
        URI server_uri;

        private void rest_users_handler(Soup.Server server, Soup.Message msg, string path,
        GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	What's available ?
            	GET /users : list of all users login
            	GET /users/login : retrieve user info
            	PUT /users/login : update user info
            	POST /users	: create new user
            	DELETE /users/login : delete user
            */
            if(!is_admin (msg, client)) {
                msg.set_status(Soup.KnownStatusCode.FORBIDDEN);
                return;
            }
            var response_json = "";
            string login = "";
            if(path.length > "/resources/users/".length)
                login = path["/resources/users/".length:path.length];
            switch (msg.method) {
            case "GET":
                if(login == "") {
                    response_json = get_users_json_list();
                    msg.set_status(Soup.KnownStatusCode.OK);
                    msg.set_response("application/json",Soup.MemoryUse.COPY,response_json.data);
                } else {
                    response_json = get_user_json(login);
                    msg.set_status(Soup.KnownStatusCode.OK);
                    msg.set_response("application/json",Soup.MemoryUse.COPY,response_json.data);
                }
                break;
            case "PUT":
                // TODO
                //response_json = main_application.update_user(login, msg.request_body.data);
                break;
            case "POST":
                create_user((string)msg.request_body.data);
                break;
            case "DELETE" :
                delete_user(login);
                break;
            }

        }

        private void rest_sessions_handler(Soup.Server server, Soup.Message msg, string path,
                                           GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	What's available ?
            	GET /sessions : list of all session_mark
            	GET /sessions/mark : retrieve a session
            	DELETE /sessions/mark : delete a session
            */
            if(!is_admin (msg, client)) {
                msg.set_status(Soup.KnownStatusCode.FORBIDDEN);
                return;
            }

        }

        /*
            	What's available ?
            	GET /acls : list of all acls ?type=TypeAcl;
            	GET /acls/id : retrieve a acl
            	PUT /acls/id : update a acl
            	POST /acls	=> a : create new acl => a  ?type=TypeAcl;
            	DELETE /acls/id : delete acl
        */


        private void rest_acls_handler(Soup.Server server, Soup.Message msg, string path,
                                       GLib.HashTable? query, Soup.ClientContext client) {

            if(!is_admin (msg, client)) {
                msg.set_status(Soup.KnownStatusCode.FORBIDDEN);
                return;
            }
            string response_json;
            string id = "";
            if(path.length > "/resources/acls/".length)
                id = path["/resources/acls/".length:path.length];

            switch (msg.method) {
            case "GET":
                if(id == "") {
                    AclType acl_type = AclType.UNKNOW;
                    string type = ((HashTable<string,string>)query).lookup("type");
                    //klog(@"type : $type");
                    switch (type) {
                    case "bl" :
                        acl_type = AclType.BLACKLIST;
                        break;
                    case "default" :
                        acl_type = AclType.DEFAULT;
                        break;
                    case "open" :
                        acl_type = AclType.OPEN;
                        break;
                    }
                    if(acl_type == AclType.UNKNOW) return;
                    response_json = get_acls_list(acl_type);
                    if(response_json != null) {
                        msg.set_status(Soup.KnownStatusCode.OK);
                        msg.set_response("application/json",Soup.MemoryUse.COPY,response_json.data);
                    }
                } else {
                    response_json = get_acl(id);
                    if(response_json != null) {
                        msg.set_status(Soup.KnownStatusCode.OK);
                        msg.set_response("application/json",Soup.MemoryUse.COPY,response_json.data);
                    }
                }
                break;
            case "POST":
                create_acl((string)msg.request_body.data);
                msg.set_status(Soup.KnownStatusCode.OK);
                break;
            case "DELETE" :
                delete_acl(id);
                msg.set_status(Soup.KnownStatusCode.OK);
                break;
            }
        }

        private void blacklist_users_handler(Soup.Server server, Soup.Message msg, string path,
                                             GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	What's available ?
            	GET /blacklist_users : list of all session_mark
            	GET /blacklist/login : retrieve a session
            	DELETE /blacklist_users/login : delete a session
            	POST /blacklist_users/ : create a blacklist user
            */
            if(!is_admin (msg, client)) {
                msg.set_status(Soup.KnownStatusCode.FORBIDDEN);
                return;
            }
            string? response_json;
            string login = "";
            if(path.length > "/resources/blacklist_users/".length)
                login = path["/resources/blacklist_users/".length:path.length];
            switch (msg.method) {
            case "GET":
                if(login == "") {
                    response_json = get_blacklist_users_json_list();
                    if(response_json != null) {
                        msg.set_status(Soup.KnownStatusCode.OK);
                        msg.set_response("application/json",Soup.MemoryUse.COPY,response_json.data);
                    }
                } else {
                    response_json = get_blacklist_user_json(login);
                    if(response_json != null) {
                        msg.set_status(Soup.KnownStatusCode.OK);
                        msg.set_response("application/json",Soup.MemoryUse.COPY,response_json.data);
                    }
                }
                break;
            case "PUT":
                // TODO
                //response_json = main_application.update_user(login, msg.request_body.data);
                break;
            case "POST":
                create_blacklist_user((string)msg.request_body.data);
                break;
            case "DELETE" :
                delete_user(login);
                break;
            }
            msg.set_status(Soup.KnownStatusCode.NOT_FOUND);
        }
        private void auto_blacklist_acls_handler(Soup.Server server, Soup.Message msg, string path,
                GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	What's available ?
            	GET /auto_blacklist_acls : list of all acls
            	GET /auto_blacklist_acls/id : retrieve a acl
            	DELETE /auto_blacklist_acls/id : remove a acl
            	POST /auto_blacklist_acls/ : add a acl
            */
            if(!is_admin (msg, client)) {
                msg.set_status(Soup.KnownStatusCode.FORBIDDEN);
                return;
            }

        }
        private void update_handler(Soup.Server server, Soup.Message msg, string path,
                                    GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	this is called by ajax script every X seconds to
            	update last_seen of Session. The response return a message
            	that could be displayed to user page.
            */
            klog("update_handler called");
            Kanet.Session session = null;
            if(!check_session(msg, client, out session)) { // user isn't authenticated
                string error_response = CONF.get_configuration_value("update_error_msg");
                msg.set_response ("text/plain", Soup.MemoryUse.COPY, error_response.data);
                msg.set_status(Soup.KnownStatusCode.FORBIDDEN);
                return;
            }
            string ip_src;
            if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                ip_src = client.get_address().get_physical();
            } else {
                ip_src = msg.request_headers.get("X-Forwarded-For");
            }

            string response_text = update_session (session, ip_src);
            //kerrorlog(response_text);
            msg.set_status(Soup.KnownStatusCode.OK);
            msg.set_response ("text/plain", Soup.MemoryUse.COPY, response_text.data);
        }
        private void login_shibboleth_handler(Soup.Server server, Soup.Message msg, string path,
                                              GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	this handler should be join via /login_shibboleth once user was authenticated with mod_shib
            	headers should contains ID
            */
            klog("Shibboleth Login ...");
            Kanet.Session _session = null;
            if(check_session(msg, client, out _session)) { // user is authenticated
                msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
                return;
            }
            string login = msg.request_headers.get("REMOTE_USER");
            string ip_src;
            if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                ip_src = client.get_address().get_physical();
            } else {
                ip_src = msg.request_headers.get("X-Forwarded-For");
            }
            Kanet.Session s = start_session(login.down(), ip_src, 0x00);
            set_session_cookie(msg, s);
            msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
            msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
            msg.request_headers.foreach(print_header);



        }

        private void login_cas_handler(Soup.Server server, Soup.Message msg, string path,
                                       GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	this handler should received a ticket as param and proceed CAS authentication
            */
            Kanet.Session _session = null;
            if(check_session(msg, client, out _session)) { // user is authenticated
                msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
                return;
            }
            string ticket = null;
            if(query != null)
                ticket = ((HashTable<string,string>)query).lookup("ticket");
            //klog("ticket : " + ticket);
            if(ticket == null) {
                msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                string url = CONF.get_configuration_value("cas_url")
                             + "index.jsp?service="
                             +  CONF.get_configuration_value("server_url")
                             + "/login_cas/";
                //klog("cas-url : " + url);
                msg.response_headers.replace("Location",url);
                return;
            }
            string request_url = CONF.get_configuration_value("cas_url")
                                 + "serviceValidate?service="
                                 + CONF.get_configuration_value("SERVER_URL")
                                 + "/login_cas/&ticket="
                                 + ticket;
            //klog("cas-request : " + request_url	);
            var session = new Soup.SessionAsync ();
            session.timeout = 3;
            var message = new Soup.Message ("GET", request_url);
            session.send_message (message);
            if(!(message.status_code == Soup.KnownStatusCode.OK)) {
                kerrorlog("An error occured requestiong CAS Server with status code : " + message.status_code.to_string());
                msg.set_status(Soup.KnownStatusCode.INTERNAL_SERVER_ERROR);
                return;
            }
            string result = (string)message.response_body.data;
            //klog("cas-return : "  + result);
            try {
                var regex = new Regex ("<cas:authenticationSuccess>");
                if(!regex.match(result)) {
                    msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                    string url = CONF.get_configuration_value("cas_url")
                                 + "index.jsp?service="
                                 +  CONF.get_configuration_value("SERVER_URL")
                                 + "/login_cas/";
                    msg.response_headers.replace("Location",url);
                    return;
                }
            } catch (Error e) {
                kerrorlog("cas_handler : error matching authentication $(e.message)");
                msg.set_status(Soup.KnownStatusCode.INTERNAL_SERVER_ERROR);
                return;
            }

            MatchInfo match;
            try {
                var regex2 = new Regex ("<cas:user>(.*?)</cas:user>");
                regex2.match(result, 0, out match);
                string login = match.fetch(1) + "@cas";
                string ip_src;
                msg.request_headers.foreach(print_header);
                if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                    ip_src = client.get_address().get_physical();
                } else {
                    ip_src = msg.request_headers.get("X-Forwarded-For");
                }
                kerrorlog("session remote address " + ip_src.to_string());
                Kanet.Session s = start_session(login.down(), ip_src, 0x00);
                set_session_cookie(msg, s);
                msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
            } catch (Error e) {
                kerrorlog("cas_handler : error matching user $(e.message)");
                msg.set_status(Soup.KnownStatusCode.INTERNAL_SERVER_ERROR);
            }
        }
        private void print_header(string name,string value) {
            kerrorlog(name + " : " + value);
        }
        private bool is_admin (Soup.Message msg, Soup.ClientContext client) {
            Kanet.Session session = null;
            if(check_session(msg, client, out session)) {
                return check_admin(session.user.login);
            }
            return false;
        }

        private void login_handler(Soup.Server server, Soup.Message msg, string path,
                                   GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	this handler should received a webform with k_login and k_password fields
            	and proceed to authentication depends on choosen method.
            */
            klog("Module Login ...");
            msg.request_headers.foreach(print_header);
            try {
                Kanet.Session session = null;
                if(check_session(msg, client, out session)) { // user is authenticated
                    msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                    msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
                    return;
                }
                HashTable<string,string> hash;
                hash =  Form.decode((string)msg.request_body.data);
                klog("Module Login - decoding hash");
                string login = hash.lookup("k_login");
                string password = hash.lookup("k_password");
                string domain = "";//hash.lookup("k_domain");
                //Soup.header_free_param_list(hash);
                uint8 group_mark = 0x00;
                string ip_src;
                if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                    ip_src = client.get_address().get_physical();
                } else {
                    ip_src = msg.request_headers.get("X-Forwarded-For");
                }
                if(login != null && password != null && check_auth(login,password, domain,ip_src, out group_mark)) {
                    // authentication succeed
                    Kanet.Session s = start_session(login, ip_src, group_mark);
                    set_session_cookie(msg, s);
                    msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                    msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
                } else {
                    // Redirect to login page;
                    msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                    msg.response_headers.replace("Location",CONF.get_configuration_value("login_page"));
                }
            } catch (Error e) {
                kerrorlog("Error in login handler : " + e.message);
                msg.set_status(Soup.KnownStatusCode.SERVICE_UNAVAILABLE);
            }
        }
        /*

        	Static handler : it's a simplistic webserver.

        */
        private void static_handler(Soup.Server server, Soup.Message msg, string path,
                                    GLib.HashTable? query, Soup.ClientContext client) {
            /*
            	[TODO] improved with 304 and other stuff
            	this handler provides a very simplist static file handler.
            */
            Kanet.Session session = null;


            if(check_session(msg, client, out session) && path == login_uri.path) { // user authenticated
                msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                msg.response_headers.replace("Location",CONF.get_configuration_value("captive_portal_page"));
                return;
            }
            if(session == null && path != login_uri.path && path.has_suffix("html")) { // user is unauthenticated
                msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
                msg.response_headers.replace("Location",CONF.get_configuration_value("login_page"));
                return;
            }
            TimeVal start_time = TimeVal();
            string filename = "";
            if(path.length > "/www/".length)
                filename = path["/www/".length:path.length];
            try {
                var file = File.new_for_path (CONF.get_configuration_value("www_path") + filename);
                var file_info = file.query_info ("*", FileQueryInfoFlags.NONE, null);
                TimeVal t;
                t = file_info.get_modification_time();
                if(msg.request_headers.get("If-Modified-Since") == t.to_iso8601()) {
                    msg.set_status(Soup.KnownStatusCode.NOT_MODIFIED);
                    return;
                }
                uint8[] buffer = new uint8[file_info.get_size()];
                var data_stream = new DataInputStream (file.read(null));
                data_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
                data_stream.read (buffer, null);
                msg.set_status(Soup.KnownStatusCode.OK);
                if(path == login_uri.path)
                    msg.set_status(Soup.KnownStatusCode.FORBIDDEN);

                if(!path.has_suffix("html"))
                    msg.response_headers.append("Last-Modified",t.to_iso8601());
                msg.set_response(file_info.get_content_type (),Soup.MemoryUse.COPY, buffer);

                klog("File " + filename + " have been served in : " +  (TimeVal().tv_usec - start_time.tv_usec).to_string());

            } catch (Error e) {
                kerrorlog("Error in static handler : " + e.message);
                msg.set_status(Soup.KnownStatusCode.NOT_FOUND);
            }
        }
        /*

        	Redirect handler
        	is the redirect_server handler (the non-ssl) that should
        	received first request wich have been DNAT from iptables and redirect it to the login page.

        */
        private void redirect_handler(Soup.Server server, Soup.Message msg, string path,
                                      GLib.HashTable? query, Soup.ClientContext client) {
            //TODO check hosts that doesn't need to be redirected like windows update.
            klog("redirect handler called " + msg.request_headers.get("Host") + path);
            msg.set_status(Soup.KnownStatusCode.MOVED_TEMPORARILY);
            msg.response_headers.replace("Location",CONF.get_configuration_value("login_page"));
            return;
        }
        /*
        	Check session
        	1 -Retrieve cookie
        	2 -Check IP/Session ID
        	3- Eventually retrieve session from db
        */


        private bool check_session(Soup.Message msg, Soup.ClientContext client, out Kanet.Session session) {
            SList list = cookies_from_request (msg);
            string id = null;
            list.foreach((a) => {
                if(((Cookie)a).name == "kanet")
                    id = ((Cookie)a).value;
            });
            if(id == null) {
                klog("Webserver - check_session failed unable to find a cookie");
                return false;
	    }
            uint32 ip_src;
            if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                ip_src = Utils.get_ip(client.get_address().get_physical());
            } else {
                ip_src = Utils.get_ip(msg.request_headers.get("X-Forwarded-For"));
            }
	    klog(@"Webserver - check_session for ip : $ip_src and id : $id");
            session = get_valid_web_session(ip_src, id);
            if(session != null) {
		 klog(@"Webserver - find a valid session");
                return true;
	    }
            /*
            	here session is not valid but request have a session cookie,
            	if the server have been stopped, session needs to be recover from db
            */
            klog(@"Webserver - try_recover_session_from_db");
            if(try_recover_session_from_db(id)) {
	
                session = get_valid_web_session(ip_src, id);
                if(session != null) {
		    klog(@"Webserver - try_recover_session_from_db : successful session recovery");
                    return true;
                } else {
		    klog(@"Webserver - try_recover_session_from_db : find a session but it's not valid");
                    //remove cookie
                }
            }
	    klog(@"Webserver - try_recover_session_from_db failed");
            return false;
        }
        /*
        	Set session cookie

        */
        private void set_session_cookie (Soup.Message msg,Kanet.Session session) {
            Cookie cookie = new Cookie("kanet", session.session_id, server_uri.host, "/", -1);
            cookie.http_only = true;
            cookie.secure = true;
            SList<Cookie> list = new SList<Cookie>();
            list.append(cookie.copy());
            Soup.cookies_to_response(list, msg);
        }

        private void request_aborted (Message msg, ClientContext client) {
            if(msg.uri != null)
                klog("Request aborted " + client.get_host() + " -- " + msg.uri.to_string(false) + " status:"+ msg.status_code.to_string());
            client.get_socket().disconnect();
        }

        private void request_finished (Message msg, ClientContext client) {
            if(msg.uri != null)
                klog("Request finished "+ client.get_host() + " -- " + msg.uri.to_string(false) + " status:"+ msg.status_code.to_string());
        }


        private void redirect_request_aborted (Message msg, ClientContext client) {
            if(msg.uri != null)
                klog("Redirect Request aborted " + client.get_host() + " -- " + msg.uri.to_string(false) + " status:"+ msg.status_code.to_string());
            client.get_socket().disconnect();
        }

        private void redirect_request_finished (Message msg, ClientContext client) {
            if(msg.uri != null)
                klog("Redirect Request finished"+ client.get_host() + " -- " + msg.uri.to_string(false) + " status:"+ msg.status_code.to_string());
        }
        private void request_started (Message  msg, ClientContext client) {
            client.get_socket().timeout = 10;
        }

        public void run() {
            try {
                klog("Web servers start");
                Thread.create<void*>(server_run, true);
                if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                    Thread.create<void*>(redirect_server_run, true);
                }
            }  catch (ThreadError e) {
                kerrorlog("Web Servers run error : " + e.message);
            }
        }
        private void* server_run() {
            server.run_async();
            main_loop = new MainLoop(null, false);
            main_loop.run();
            return null;
        }
        public MainLoop main_loop { get ; private set;}

        private void* redirect_server_run() {
            redirect_server.run_async();
            main_loop = new MainLoop(null, false);
            main_loop.run();
            return null;
        }
        public MainLoop redirect_main_loop { get ; private set;}

        private Soup.Server server;
        private Soup.Server redirect_server;

        public WebServers() {


            login_uri = new URI(CONF.get_configuration_value("login_page"));
            server_uri = new URI(CONF.get_configuration_value("SERVER_URL"));

            /*
            	Main server
            	Standalone : server listens on all interfaces and port defined in configuration file. SSl is activated.
            	Behind apache (needs when shibboleth authentication is need via mod_shib) : server listens on internal
            	interface 127.0.0.1 and port defined in configuration file
            */
            if(CONF.get_configuration_value("SERVER_PORT") != null && CONF.get_configuration_value("SERVER_MODE") == "PROXY") {
                Soup.Address addr = new Soup.Address("127.0.0.1",int.parse(CONF.get_configuration_value("SERVER_PORT")));
                addr.resolve_sync(null);
                server = new Soup.Server (
                    Soup.SERVER_INTERFACE, addr,
                    Soup.SERVER_SERVER_HEADER, "kanet-web"
                );
            } else { // default
                server = new Soup.Server (Soup.SERVER_PORT, int.parse(CONF.get_configuration_value("SERVER_PORT")) ,
                                          Soup.SERVER_SSL_CERT_FILE, CONF.get_configuration_value("SSL_CERT_FILE"),
                                          Soup.SERVER_SSL_KEY_FILE, CONF.get_configuration_value("SSL_KEY_FILE"),
                                          Soup.SERVER_SERVER_HEADER, "kanet-web"
                                         );
            }

            /*
            	REST admin handlers
            */
            server.request_started.connect(request_started);
            server.request_aborted.connect(request_aborted);
            if(Config.DEBUG) {
                server.request_finished.connect(request_finished);
            }

            server.add_handler ("/resources/users/", rest_users_handler);
            server.add_handler ("/resources/sessions/", rest_sessions_handler);
            server.add_handler ("/resources/acls/", rest_acls_handler);
            server.add_handler ("/resources/blacklist_users/", blacklist_users_handler);
            server.add_handler ("/resources/auto_blacklist_acls/", auto_blacklist_acls_handler);
            /*
            	user handlers
            */
            server.add_handler ("/update/", update_handler);
            server.add_handler ("/login/", login_handler);
            server.add_handler ("/login_cas/", login_cas_handler);
            server.add_handler ("/login_shibboleth", login_shibboleth_handler);
            server.add_handler ("/www/", static_handler);
            server.add_handler ("/", redirect_handler);
            /*
            	Redirect Server
            */
            if(CONF.get_configuration_value("SERVER_MODE") != "PROXY") {
                redirect_server = new Soup.Server (Soup.SERVER_PORT, int.parse(CONF.get_configuration_value("REDIRECT_SERVER_PORT")),
                                                   Soup.SERVER_SERVER_HEADER, "kanet-web"
                                                  );

                redirect_server.request_started.connect(request_started);
                redirect_server.request_aborted.connect(redirect_request_aborted);

                if(Config.DEBUG) {
                    redirect_server.request_finished.connect(redirect_request_finished);
                }

                redirect_server.add_handler ("/", redirect_handler);
            }
        }
    }
}
