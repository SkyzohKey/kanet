/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using GLib;
using Json;
using Gee;
using Kanet.Utils;
using Kanet.Log;

namespace Kanet.Conf {
    class KanetConfiguration {

        private Gee.HashMap<string,string> config_hash = new Gee.HashMap<string,string>();
        private string config_filename;

        public KanetConfiguration(string config_filename = Config.KANET_CONF) {

            this.config_filename = config_filename;

        }

        public string? get_configuration_value(string name) {
            if(config_hash.has_key(name))
                return config_hash.get(name);
            string? t = get_value(name);
            if(t != null)
                config_hash.set(name,t);
            return t;
        }
        /*
        	Retrieve a configuration value, string only.
        */
        private string? get_value (string name) {
            Parser parser = new Parser();
            string result;
            try {
                parser.load_from_file (config_filename);
                // check in lowercase
                result = parser.get_root().get_object().get_string_member(name.down());
                // check in uppercase
                if(result == null)
                    result = parser.get_root().get_object().get_string_member(name.up());
            } catch (Error e) {
                kerrorlog(e.message);
                return null;
            }
            return result;
        }

        /*
        	Check all mandatory field from config file
        */
        public bool check_config_mandatory() {
            // TODO Check mandatory PROXY vs STANDALONE
            string[] list = {"SERVER_URL",
                             "SERVER_PORT",
                             "REDIRECT_SERVER_PORT",
                             "SSL_CERT_FILE",
                             "SSL_KEY_FILE",
                             "login_page",
                             "captive_portal_page",
                             "www_path",
                             "module_path",
                             "auth_module_name",
                             "default_blacklist_message",
                             "bytes_quota",
                             "time_quota",
                             "update_msg",
                             "over_quota_msg",
                             "blacklist_msg",
                             "update_error_msg"
                            };
            foreach(string s in list) {
                string? val = get_configuration_value (s);
                if(val != null && val != "") {
                    config_hash.set(s,val);
                } else {
                    kerrorlog(@"check_config_mandatory : missing mandatory field : $s");
                    return false;
                }
            }
            return true;
        }
        /*
        	Load persistent Acls from config file
        */
        public ArrayList<Acl> get_acls (string acls_group) {
            Parser parser = new Parser();
            ArrayList<Acl> acls = new ArrayList<Acl>();
            try {
                parser.load_from_file (config_filename);
                var n = parser.get_root().get_object();
                foreach (var node in n.get_array_member(acls_group).get_elements ()) {
                    var _acl = node.get_object ();
                    Acl a = new Acl();
                    if(_acl.has_member("port"))
                        a.port = (int)_acl.get_int_member ("port");
                    if(_acl.has_member("address"))
                        a.address = _acl.get_string_member ("address");
                    a.persistent = true;
                    acls.add(a);
                }
            } catch (Error e) {
                kerrorlog(e.message);
            }
            return acls;
        }
        /*
        	Load persistent blacklist users from config file
        */
        public HashMap<string,BlacklistUser> get_blacklist_users () {
            Parser parser = new Parser();
            HashMap<string,BlacklistUser> hash = new HashMap<string,BlacklistUser>();
            try {
                parser.load_from_file (config_filename);
                var n = parser.get_root().get_object();
                foreach (var node in n.get_array_member("blacklist_users").get_elements ()) {
                    var _u = node.get_object ();
                    if(!_u.has_member("login"))
                        continue;
                    BlacklistUser u = new BlacklistUser(_u.get_string_member ("login"));
                    if(_u.has_member("message"))
                        u.message = _u.get_string_member ("message");
                    u.persistent = true;
                    hash.set(u.login,u);
                }
            } catch (Error e) {
                kerrorlog(e.message);
            }
            return hash;
        }
    }


}
