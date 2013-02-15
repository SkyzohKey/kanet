/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/

using GLib;
using Gee;
using Kanet.Utils;
using Kanet.Log;


namespace Kanet {

    public enum AclType {
        UNKNOW,
        BLACKLIST,
        DEFAULT,
        OPEN
    }

    public class Acl {

        public Acl(string? label = null) {
            this.label = label;
        }
        /*
        	unique id
        */
    public string id {set; get; default = Utils.get_id(6); }
        /*
        	Acl Type
        */
        public string acl_type {set; get; }
        /*
        	a label associated with an acl
        */
        public string? label {get; set ; }
        /*
        	a string represents address hostname or ip
        */
        public string? address {get; set; }
        /*
        	ip port
        */
    public int port {get; set; default = 0;}
        /*
        	Not yet implemented, the goal is to load computed acls from a file
        	because the first load may be long as all addresses have to be resolved.
        */
        public string? filename {get; set; }
        /*
        	persistent acl comes from config file, they can't be removed.
        */
    public bool persistent { get; set; default =false;}
        /*
        	serialize
        */
        public string to_json() {
            klog("acl_tojson");
            Json.Object object = new Json.Object();
            if(label != null)
                object.set_string_member ("label", label);
            if(address != null)
                object.set_string_member ("address", address );
            object.set_int_member ("port", port );
            if(filename != null)
                object.set_string_member ("filename", filename );
            object.set_string_member("type",acl_type.to_string());
            object.set_string_member("id",id);
            object.set_boolean_member ("persistent", persistent );
            Json.Generator jg = new Json.Generator();
            Json.Node node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(object);
            jg.set_root(node);
            return jg.to_data(null);
        }
        /*
        	deserialize [TODO]
        */
        public static Acl? get_acl_from_json (string json) {
            klog(json);
            return null;
        }
    }
    public class Acls {

        private AclType _acl_type;
        public HashSet<int> open_ports = new HashSet<int>();

        public HashMap<uint32,HashSet<int>> _acls = new HashMap<uint32,HashSet<int>>();

        public ArrayList<Acl> acls = new ArrayList<Acl>();

        public Acls(AclType acl_type) {
            this._acl_type = acl_type;
        }
        public string dump () {
            StringBuilder sb = new StringBuilder();
            sb.append("open ports:\n");
            foreach(int i in open_ports) {
                sb.append(i.to_string() + "\n");
            }
            sb.append("acls hash:\n");
            foreach(uint32 key in _acls.keys) {
                sb.append(get_ip_from_uint32(key)+ "\n");
            }
            return sb.str;
        }
        public void add_acl (Acl a) {
            // Store acl in arraylist
            acls.add(a);
            // Compute acl
            if(a.address == null && a.port == 0) {
                return;
            } else if (a.address == null) {
                open_ports.add(a.port);
                return;
            }  else {
                Resolver r = Resolver.get_default();
                try {
                    GLib.List<InetAddress> _list = r.lookup_by_name(a.address, null);

                    foreach(InetAddress ia in _list) {
                        uint32 ip = Utils.get_ip_from_inet(ia);
                        if(_acls.has_key(ip)) {
                            HashSet<int> _port_hash = _acls.get(ip);
                            _port_hash.add(a.port);
                        } else {
                            HashSet<int> _port_hash = new HashSet<int>();
                            _port_hash.add(a.port);
                            _acls.set(ip, _port_hash);
                        }
                    }
                } catch (Error e) {
                    kerrorlog(@"Acl.add_acl : Unable to resolved $(a.address) with error $(e.message)");
                    return;
                }
            }
        }
        /*
        	this function is needed due to remove acl, if there's 2 vhosts in acls, if one is removed
        	the ip address will be removed (same ip for diff hostname)
        */
        public void rebuild_acls_hash() {
            _acls.clear();
            foreach(Acl a in acls) {
                add_acl(a);
            }
        }
        public void remove_acl(string id) {
            Acl acl = null;
            foreach(Acl a in acls) {
                if(a.id == id) {
                    acl = a;
                    break;
                }
            }
            if(!acls.contains(acl))
                return;
            acls.remove(acl);
            Resolver r = Resolver.get_default();
            try {
                GLib.List<InetAddress> _list = r.lookup_by_name(acl.address, null) ;
                foreach(InetAddress a in _list) {
                    if(_acls.has_key(Utils.get_ip_from_inet(a)))
                        _acls.unset(Utils.get_ip_from_inet(a));
                }
            } catch (Error e) {
                kerrorlog(@"Acls.remove_acl : Unable to resolved $(acl.address) with error $(e.message)");
                return;
            }
        }
        public bool is_match(uint32 ip_dest, int port) {
            if(open_ports.contains(port))
                return true;
            if(_acls.has_key(ip_dest))
                return _acls.get(ip_dest).contains(0) || _acls.get(ip_dest).contains(port);
            return false;
        }
        public bool load_acls_from_config_file() {
            ArrayList<Acl>? _acls = CONF.get_acls (_acl_type.to_string());
            if(	_acls == null)
                return false;
            foreach (Acl a in _acls) {
                add_acl(a);
            }
            return true;
        }
        public string to_json() {
            Json.Object object = new Json.Object();
            Json.Array array = new Json.Array();
            foreach(Acl a in this.acls) {
                klog("acl id : " + a.id);
                Json.Object _node = new Json.Object();
                _node.set_string_member ("id", a.id);
                array.add_object_element(_node);
            }
            object.set_array_member("acls", array);
            Json.Generator jg = new Json.Generator();
            Json.Node node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(object);
            jg.set_root(node);
            return jg.to_data(null);

        }
        public Acl? get_acl(string id) {
            foreach(Acl a in acls) {
                if(a.id == id) return a;
            }
            return null;
        }
    }
}
