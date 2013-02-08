/*                                                   
	Kanet, Control access to network   
	Copyright (C) 2010 Cyrille Colin.                    
*/

using GLib;
using Gee;
using Kanet.Utils;
using Kanet.Log;


namespace Kanet {
	
	public class User : Object {
		
		public User (string login) {
			this.login = login;
		}
		/*
			the login associated with the user, need to be unique.
		*/
		public string login {get; private set;}
		public uint32 duration {get; set; default=0;}
		
		public uint8 group { get; set;}
		/*
			quota stuff
		*/
		public uint64 up_bytes {get; set; default=0;}
		public uint64 down_bytes {get; set; default=0;}
		public uint32 time_quota {get; set; default=0;}
		public uint64 bytes_quota {get; set; default=0;}
		/*
			Devices associated to a user
		*/
		public ArrayList<Device> devices {get;  private set; default = new ArrayList<Device>(); }
		
		public bool is_over_quota() {
			if(bytes_quota != 0 && bytes_quota < (up_bytes + down_bytes))
				return true;
			if(time_quota != 0 && time_quota < duration)
				return true;
			return false;			
		}
		public string to_json() {
			Json.Object object = new Json.Object();
			object.set_string_member ("login", login);
			//if(up_bytes != null)
				object.set_int_member ("up_bytes", (int64)up_bytes );
			//if(down_bytes != null)
				object.set_int_member ("down_bytes", (int64)down_bytes );
			//if(time_quota != null)
				object.set_int_member ("time_quota", (int)time_quota );
			//if(bytes_quota != null)
				object.set_int_member ("bytes_quota", (int64)bytes_quota );
				object.set_int_member ("duration", (int)duration );
				object.set_int_member ("group", (int)group);
			Json.Generator jg = new Json.Generator();
			Json.Node node = new Json.Node(Json.NodeType.OBJECT);
			node.set_object(object);
			jg.set_root(node);
			return jg.to_data(null);
		}
		public static User? user_from_json(string json) {
			//TODO
			klog(json);
			return null;
		}
		
	}
	public class Users : Object {
		
		public HashMap<string,User> users = new HashMap<string,User>();
		
		public bool add_user(User u) {
			if(users.has_key(u.login))
				return false;
			users.set(u.login, u);
			return true;
		}
		public void update_user(string login, User a) {
			
		}
		public bool delete_user(string login) {
			if(users.has_key(login)) {
				users.unset(login);
				return true;
			}
			return false;
		}
		public User? get_user(string login) {
			if(users.has_key(login))
				return users.get(login);
			return null;
		}
		public string to_json() {
			Json.Object object = new Json.Object();
			Json.Array array = new Json.Array();
			foreach(string key in this.users.keys) {
				Json.Object _node = new Json.Object();
				_node.set_string_member ("id", key);
				array.add_object_element(_node);
			}
			
			
			object.set_array_member("users", array);
			Json.Generator jg = new Json.Generator();
			Json.Node node = new Json.Node(Json.NodeType.OBJECT);
			node.set_object(object);
			jg.set_root(node);
			return jg.to_data(null);
		}
	}
}