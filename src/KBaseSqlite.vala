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

        public KBaseSqlite(string connection_string) {

            int rc = Sqlite.Database.open (connection_string, out db);
            if (rc != Sqlite.OK) {
                kerrorlog("Can't open database : " + db.errmsg (),KLOG_LEVEL.ERROR);
            }
        }
        /*
        	Users
        */
        public User? get_user_from_db (string login) {
            Sqlite.Statement stmt;
            int rc;
            string sql = @"select login,upbytes,downbytes,duration,bytesquota,timequota from users where login='$(login)' LIMIT 1;";
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1)
                return null;
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
            string sql = @"insert into users ('login','passwd') values ('$(user.login)','');";
            if ((rc = db.exec(sql)) == 1) {
                kerrorlog ("SQL error: "+ db.errmsg ());
            }
        }
        public void update_user(User user) {
            int rc;
            string sql = @"update users set upbytes=$(user.up_bytes), downbytes=$(user.down_bytes), duration=$(user.duration), bytesquota=$(user.bytes_quota) , timequota=$(user.time_quota) where login='$(user.login)';";
            if ((rc = db.exec (sql)) == 1) {
                kerrorlog ("SQL error: "+ db.errmsg ());
            }
        }
        public void remove_user(User user) {
            int rc;
            string sql = @"delete from users where login='$(user.login)';";
            if ((rc = db.exec (sql)) == 1) {
                kerrorlog ("SQL error: "+ db.errmsg ());
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
            int rc;
            string sql = @"select device, login, mark, start_time, ip_src from sessions where id='$(id)' LIMIT 1;";
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1)
                return null;
            rc = stmt.step();
            if(rc == Sqlite.ROW) {
                string login = stmt.column_text(1);
                user = get_user_from_db (login);
                if(user == null)
                    return null;
                Session s = new  Session(user, stmt.column_int(4), null);
                s.session_id = id;
                s.mark = stmt.column_int(2);
                TimeVal t = TimeVal();
                t.tv_sec = (long)stmt.column_int64(3);
                s.start_time = t;
                return s;
            }
            return null;
        }
        public void update_session(Session s) {}
        public void remove_session(Session s) {}
        public void save_session_to_db(Session s) {
            int rc;
            string sql = @"insert into sessions ('id','ip_src','mark','start_time','login') values ('$(s.session_id)',$(s.ip_src),$(s.mark),$(s.start_time.tv_sec),'$(s.user.login)');";
            klog(sql);
            if ((rc = db.exec(sql)) == 1) {
                kerrorlog ("SQL error: "+ db.errmsg ());
            }
        }
        /*
        	Acls
        */
        public ArrayList<string> get_acls_from_db(AclType type) {
            ArrayList<string> acls = new ArrayList<string>();
            Sqlite.Statement stmt;
            int rc;
            string sql = @"select id from acls where type=$type;";
            if((rc = db.prepare (sql, -1, out stmt, null)) == 1) {
                kerrorlog("get_acls_from_db() :" + db.errmsg());
                return acls;
            }
            while((rc = stmt.step()) == Sqlite.ROW) {
                acls.add(stmt.column_text(0));
            }
            return acls;
        }

        public void remove_acl(string id) {
        }

        public Acl? get_acl_from_db(string id) {
            return null;
        }
        /*
        	blacklist_user
        */
        public ArrayList<BlacklistUser> get_blacklist_users_from_db() {
            ArrayList<BlacklistUser> list = new ArrayList<BlacklistUser>();
            return list;
        }
        /*
        	auto_blacklist_acls
        */
        public ArrayList<AutoBlacklistAcl> get_auto_blacklist_acls_from_db() {
            ArrayList<AutoBlacklistAcl> list = new ArrayList<AutoBlacklistAcl>();
            return list;
        }
    }
}
