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
    	public string id {set; get; default = Utils.get_id(8); }
        /*
        	Acl Type
        */
        public AclType acl_type {set; get; }
        /*
        	a label associated with an acl
        */
        public string? label {get; set ; }
        /*
        	a string represents address hostname or ip
        */
        private string? _address;
        public string? address {
			get {
				return this._address;
				}
			set {
				resolveAddress(value);
				this._address = value;
			} 
		}
        /*
        	ip port
        */
    	public int port {get; set; default = 0;}
        /*
        	Resolved address ... all addresses need to be translate into IP address to be persisted
        */
		public uint32[] ipAddresses{get; set;}
		
		public string getIpAddressesToString() {
			string result = "";
			for (int i = 0; i < ipAddresses.length ; i++) {
				result += ipAddresses[i].to_string();
				if(i < ipAddresses.length - 1)
					result += "|";
			}
			return result;
		}
		public void setIpAddressesFromString(string ipaddresses) {
			string[] ips = ipaddresses.split("|");
			uint32[] result = new uint32[ips.length];
			for(int i = 0; i < ips.length ; i++) {
				try {
					result[i] = (uint32)int.parse(ips[i]);
				} catch (Error e) {
					klog("setIpAddressesFromString : an error occured parsing address");
				}
			}
			ipAddresses = result;
		}
		public void resolveAddress(string host) {
			Resolver r = Resolver.get_default();
				try {
                    GLib.List<InetAddress> _list = r.lookup_by_name(host, null);
                    ipAddresses = new uint32[_list.length()];
                    int x=0;
                    foreach(InetAddress ia in _list) {
                        ipAddresses[x] = Utils.get_ip_from_inet(ia);
                        x++;
                    }
                } catch (Error e) {
                    kerrorlog(@"Acl.add_acl : Unable to resolved $(address) with error $(e.message)");
                    return;
                }
         }
        /*
        	serialize
        */
        public Json.Object getJsonObject() {
            Json.Object object = new Json.Object();
            if(label != null)
                object.set_string_member ("label", label);
            if(address != null)
                object.set_string_member ("address", address );
            object.set_int_member ("port", port );
            object.set_string_member("type",acl_type.to_string());
            object.set_string_member("id",id);
            object.set_string_member("ipaddresses", getIpAddressesToString() );
            return object;
        }        
        public string to_json() {
            Json.Generator jg = new Json.Generator();
            Json.Node node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(getJsonObject());
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
                    foreach(uint32 ip in a.ipAddresses) {
                        if(_acls.has_key(ip)) {
                            HashSet<int> _port_hash = _acls.get(ip);
                            _port_hash.add(a.port);
                        } else {
                            HashSet<int> _port_hash = new HashSet<int>();
                            _port_hash.add(a.port);
                            _acls.set(ip, _port_hash);
                        }
                    }
            }
        }
 
        public bool is_match(uint32 ip_dest, int port) {
            if(open_ports.contains(port))
                return true;
            if(_acls.has_key(ip_dest))
                return _acls.get(ip_dest).contains(0) || _acls.get(ip_dest).contains(port);
            return false;
        }
        public string to_json() {
            Json.Object object = new Json.Object();
            Json.Array array = new Json.Array();
            foreach(Acl a in this.acls) {
                array.add_object_element(a.getJsonObject());
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
        public void load_acls_from_db(KBase database) {
        	ArrayList<Acl> acls = database.get_acls_from_db(this._acl_type);
        	foreach(Acl a in acls) {
				klog(@"add acl $(a.label)");
				add_acl(a);
			}
        }
    }
}
