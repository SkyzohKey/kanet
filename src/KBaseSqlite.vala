/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using Gee;
using Kanet.Utils;
using Kanet.Log;

namespace Kanet {
    class KBaseSqlite : KBase, GLib.Object {

        Sqlite.Database db;
	private string TAG = "Database :\t";
        public KBaseSqlite(string connection_string) {

            int rc = Sqlite.Database.open (connection_string, out db);
            if (rc != Sqlite.OK) {
                kerrorlog(@"$TAG Can't open database : " + db.errmsg (),KLOG_LEVEL.ERROR);
            }
        }
        public void close() {
			
		}
        /*
        	Users
        */
        public User? get_user_from_db (string login) {
            Sqlite.Statement stmt;
	    klog(@"$TAG get_user_from_db login : $login", KLOG_LEVEL.DEBUG);
            int rc;
            string sql = @"select login,upbytes,downbytes,duration,bytesquota,timequota from user where login='$(login)' LIMIT 1;";
		 klog(@"$TAG request $sql", KLOG_LEVEL.DEBUG);
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1) {
		
                return null;
		}
            rc = stmt.step();
            if(rc == Sqlite.ROW) {
                User u = new User(login);
                u.up_bytes = stmt.column_int64(1);
                u.down_bytes = stmt.column_int64(2);
                u.duration = stmt.column_int(3);
                u.bytes_quota = stmt.column_int64(4);
                u.time_quota = stmt.column_int(5);
                return u;
            }
            return null;
        }
        public void save_user_to_db(User user) {
            int rc;
            string sql = @"insert into user ('login','password') values ('$(user.login)','');";
            if ((rc = db.exec(sql)) == 1) {
                kerrorlog (@"$TAG SQL error: "+ db.errmsg ());
            }
        }
        public void update_user(User user) {
            int rc;
            string sql = @"update user set upbytes=$(user.up_bytes), downbytes=$(user.down_bytes), duration=$(user.duration), bytesquota=$(user.bytes_quota) , timequota=$(user.time_quota) where login='$(user.login)';";
            if ((rc = db.exec (sql)) == 1) {
                kerrorlog (@"$TAG SQL error: "+ db.errmsg ());
            }
        }
        public void remove_user(User user) {
            int rc;
            string sql = @"delete from user where login='$(user.login)';";
            if ((rc = db.exec (sql)) == 1) {
                kerrorlog (@"$TAG SQL error: "+ db.errmsg ());
            }
        }
        /*
        	Sessions
        */

        /**
        	this function should be call if server restart to retrieve session information and prevent
        	users need to reauthenticate.
        */
        public Session? get_session_from_db (string id, out User? user) {
            Sqlite.Statement stmt;
		klog(@"$TAG get_session_from_db id : $id", KLOG_LEVEL.DEBUG);
            int rc;
            string sql = @"select login, mark, start_time, ip_src from session where id='$(id)' LIMIT 1;";
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1)
                return null;
            rc = stmt.step();
            if(rc == Sqlite.ROW) {
                string login = stmt.column_text(0);
                user = get_user_from_db (login);
                if(user == null) {
		    klog(@"$TAG get_session_from_db : failed to retrieve a user");
                    return null;
		}
                Session s = new  Session(user, stmt.column_int(3));
                s.session_id = id;
                s.mark = stmt.column_int(1);
                TimeVal t = TimeVal();
                t.tv_sec = (long)stmt.column_int64(2);
                s.start_time = t;
		klog(@"$TAG get_session_from_db : successfully session recover");
                return s;
            }
       	klog(@"$TAG get_session_from_db : failed to retrieve a session");
            return null;
        }
        public void update_session(Session s) {}
        public void remove_session(Session s) {}
        public void save_session_to_db(Session s) {
            int rc;
            string sql = @"insert into session ('id','ip_src','mark','start_time','login') values ('$(s.session_id)',$(s.ip_src),$(s.mark),$(s.start_time.tv_sec),'$(s.user.login)');";
            klog(@"$TAG request : $sql", KLOG_LEVEL.DEBUG);
            if ((rc = db.exec(sql)) == 1) {
                kerrorlog (@"$TAG SQL error: "+ db.errmsg ());
            }
        }
        /*
        	Acls
        */
        public ArrayList<Acl> get_acls_from_db(AclType type) {
            ArrayList<Acl> acls = new ArrayList<Acl>();
            Sqlite.Statement stmt;
            int rc;
            string sql = @"select address,ipaddresses,id,label,port,type from acl where type=$((int)type);";
            klog(@"$TAG request $sql", KLOG_LEVEL.DEBUG);
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1) {
                kerrorlog(@"$TAG get_acls_from_db() :" + db.errmsg());
                return acls;
            }
            while((rc = stmt.step()) == Sqlite.ROW) {
            	Acl a = new Acl();
            	a.address = stmt.column_text(0);
            	a.setIpAddressesFromString(stmt.column_text(1));
            	a.id = stmt.column_text(2);
            	a.label = stmt.column_text(3);
            	a.port = stmt.column_int(4);
            	a.acl_type = (AclType)stmt.column_int(5);
                acls.add(a);
            }
            return acls;
        }

        public void remove_acl(string id) {
			 string sql = @"delete from acl where id ='$(id)';";
             db.exec(sql);
        }

        public Acl? get_acl_from_db(string id) {
        	Sqlite.Statement stmt;
            int rc;
            string sql = @"select address,ipaddresses,id,label,port,type from acl where id='$(id)' LIMIT 1;";
            klog(@"$TAG request $sql", KLOG_LEVEL.DEBUG);
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1)
                return null;
            rc = stmt.step();
            if(rc == Sqlite.ROW) {
            	Acl a = new Acl();
            	a.address = stmt.column_text(0);
            	a.setIpAddressesFromString(stmt.column_text(1));
            	a.id = stmt.column_text(2);
            	a.label = stmt.column_text(3);
            	a.port = stmt.column_int(4);
            	a.acl_type = (AclType)stmt.column_int(5);
                return a;
            }
            return null;
        }
        public void save_acl_to_db(Acl acl) {
        	int rc;
			string sql = @"insert into acl ('address', 'id', 'label', 'port', 'type', 'ipaddresses') values ('$(acl.address)', '$(acl.id)','$(acl.label)',$(acl.port), $((int)acl.acl_type), '$(acl.getIpAddressesToString())');";
			klog(@"$TAG request $sql", KLOG_LEVEL.DEBUG);
			if ((rc = db.exec(sql)) == 1) {
				kerrorlog (@"$TAG SQL error: "+ db.errmsg ());
			}
        }
        /*
        	blacklist_user
        */
        public HashMap<string,BlacklistUser> get_blacklist_users_from_db() {
            HashMap<string,BlacklistUser> list = new HashMap<string,BlacklistUser>();
            return list;
        }
    }
}
