/*                                                   
	Kanet, Control access to network   
	Copyright (C) 2010 Cyrille Colin.                    
*/
using Gee;
using Kanet.Utils;

namespace Kanet {	
	public interface KBase : GLib.Object {
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
		public abstract ArrayList<string> get_acls_from_db(AclType type) ;
		public abstract void remove_acl(string id) ;
		public abstract Acl? get_acl_from_db(string id);
		/*
			blacklist_user
		*/
		public abstract ArrayList<BlacklistUser> get_blacklist_users_from_db();
		/*
			auto_blacklist_acls
		*/
		public abstract ArrayList<AutoBlacklistAcl> get_auto_blacklist_acls_from_db();
	}
}
