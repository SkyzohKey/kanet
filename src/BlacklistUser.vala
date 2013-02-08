/*                                                   
	Kanet, Control access to network   
	Copyright (C) 2010 Cyrille Colin.                    
*/
using GLib;

namespace Kanet {
	
	public class BlacklistUser {
		
		public BlacklistUser(string login) {
			this.login = login;
		}
		
		public string login { get ; private set;}
		public string message { get; set; default = "";}
		public bool persistent { get; set; default = false;}
		public string to_json() {
			Json.Object object = new Json.Object();
			object.set_string_member ("login", login);
			object.set_string_member ("message", message );
			object.set_boolean_member("persistent", persistent);
			Json.Generator jg = new Json.Generator();
			Json.Node node = new Json.Node(Json.NodeType.OBJECT);
			node.set_object(object);
			jg.set_root(node);
			return jg.to_data(null);
		}
	}
}
