/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using GLib;
using Gee;
using Kanet.Log;
using Kanet.Utils;

namespace Kanet {

    public class Session : Object {

        public Session(User user, uint32 ip_src) {
            this.start_time = TimeVal();
            this.ip_src = ip_src;
            this.user = user;
        }
        /*
        	The User
        */
        public User user { get; set;}
        /*
        	Session id used in cookie.
        */
    	public string session_id {get; set; default = Utils.get_id();}
        /*
        	Session start time
        */
        public TimeVal start_time { get; set;}
        /*
        	Last time update
        */
        public TimeVal last_seen { get; set; }

        /*
        	Ip source
        */
        public uint32 ip_src{get; private set;}
        /*
        	The mark return to mark paquet;
        */
        public uint32 mark {get ; set; }
        /*
        	To open rules, a client must send update regularly, pass the kanet session timeout
        	we considere that user is disconnected and no acls should be open
        */
        public bool is_kanet_session_valid(long KANET_SESSION_TIMEOUT) {
            long t = TimeVal().tv_sec - last_seen.tv_sec;
	    klog(@"is_kanet_session_valid with KANET_SESSION_TIMEOUT : $KANET_SESSION_TIMEOUT");
            return t < KANET_SESSION_TIMEOUT;
        }
        /*
        	Web session means the time a user need to re-authenticate
        */
        public bool is_web_session_valid(long WEB_SESSION_TIMEOUT) {
		long t = TimeVal().tv_sec - start_time.tv_sec;
		 klog(@"is_web_session_valid with WEB_SESSION_TIMEOUT : $WEB_SESSION_TIMEOUT and diff = $t");
            return t < WEB_SESSION_TIMEOUT;
        }
        public string to_json() {
            Json.Object object = new Json.Object();
            if(user != null)
                object.set_string_member ("login", user.login);
            object.set_string_member ("last_seen", last_seen.to_iso8601() );
            object.set_string_member ("start_time", start_time.to_iso8601() );
            object.set_int_member ("ip_src", ip_src );
            object.set_int_member ("mark", mark );
            Json.Generator jg = new Json.Generator();
            Json.Node node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(object);
            jg.set_root(node);
            return jg.to_data(null);
        }
    }
    public class Sessions {
        public HashMap<uint32,Session> sessions = new HashMap<uint32,Session>();

        public void add_session(Session s) {
            klog("Add session from : " + s.ip_src.to_string());
            sessions.set(s.ip_src,s);
        }
        public void remove_session(Session s) {
            //TODO fix this unset vs remove depending on gee vapi version
            //sessions.unset(s.mark);
        }
        public void update_session(uint32 ip_src) {
            if(!sessions.has_key(ip_src)) {
                klog("Received update from unknow IP : " + ip_src.to_string());
                return;
            }
            Session s = sessions.get(ip_src);
            s.last_seen = TimeVal();
            klog("Update session : " +s.to_json());
        }
        public bool is_kanet_session_valid (uint32 ip_src, long KANET_SESSION_TIMEOUT, out Session session) {
            if(!sessions.has_key(ip_src)) {
                klog("No session exists for this IP : " + get_ip_from_uint32(ip_src));
                return false;
            }
            session = sessions.get(ip_src);
            return session.is_kanet_session_valid(KANET_SESSION_TIMEOUT);
        }
        public bool is_web_session_valid(uint32 ip_src, string id, long WEB_SESSION_TIMEOUT, out Session session) {
            if(!sessions.has_key(ip_src))
                return false;
            Session s = sessions.get(ip_src);
            if(s.session_id == id && s.is_web_session_valid(WEB_SESSION_TIMEOUT)) {
                session = s;
                return true;
            }
            return false;
        }
    }
}
