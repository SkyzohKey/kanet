/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using Gee;
using Kanet.Utils;

namespace Kanet {
    public interface KBase : GLib.Object {
		
		public abstract void close();
        /*
        	Users
        */
        public abstract User? get_user_from_db (string login);
        public abstract void update_user(User user);
        public abstract void remove_user(User user);
        public abstract void save_user_to_db(User user);
        /*
        	Sessions
        */
        public abstract Session? get_session_from_db (string id, out User? user);
        public abstract void update_session(Session s);
        public abstract void remove_session(Session s);
        public abstract void save_session_to_db(Session s);
        /*
        	Acls
        */
        public abstract ArrayList<Acl> get_acls_from_db(AclType type) ;
        public abstract void remove_acl(string id) ;
        public abstract Acl? get_acl_from_db(string id);
        public abstract void save_acl_to_db(Acl acl);
        /*
        	blacklist_user
        */
        public abstract HashMap<string,BlacklistUser> get_blacklist_users_from_db();
    }
}
