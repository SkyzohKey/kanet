/*                                                   
	Kanet, Control access to network   
	Copyright (C) 2010 Cyrille Colin.                    
*/

using Gee;
using Kanet.Utils;
using Kanet.Log;
using Mysql;

namespace Kanet {
	class KBaseMysql : KBase, GLib.Object {
		
		Mysql.Database db;
		string Host {get; set; default="localhost";}
		string UserName {get; set; default="root";}
		string Pwd {get; set; default="";}
		string DbName {get; set; default="kanet";}
		int Port {get; set; default=3306;}

		public KBaseMysql(string h, string u, string p, string d, int port) {
			int rc = 0;
			
			
  			this.Host = h;
  			this.UserName = u;
  			this.Pwd = p;
  			this.DbName= d;
  			this.Port = port;
  			
	       	if (! Connect() ) {
	            kerrorlog("Can't open database : " + db.error(),KLOG_LEVEL.ERROR);
            }
            else
            {
            	klog("Connection to " + this.Host + "." + this.DbName + " Successfull !");
            }
		}
		
		public bool Connect()
		{
			ClientFlag cflag    = 0;
			string     socket   = null;
			
			db = new Mysql.Database ();
  			var isconnected = db.real_connect(Host, UserName, Pwd, DbName, Port, socket, cflag);
  			
  			return isconnected;

		}
		
		/*
			Users
		*/
		public User? get_user_from_db (string login) {
			int rc;
			string sql = @"select login,upbytes,downbytes,duration,bytesquota,timequota from users where login='$(login)' LIMIT 1;";
			rc = db.query(sql);
  			if ( rc != 0 ) {
	    		stdout.printf("ERROR %u: Query failed: %s\n", db.errno(), db.error());
    			return null;
  			}

  			Result ResultSet = db.use_result();

  			string[] MyRow;
  			while ( (MyRow = ResultSet.fetch_row()) != null ) {
    			klog(@"Got from database : id: $(MyRow[0]) | data: $(MyRow[1]) | ts: $(MyRow[2])\n");
				User u = new User(login);
				u.up_bytes = uint64.parse(MyRow[1]);
				u.down_bytes = uint64.parse(MyRow[2]);
				u.duration = int.parse(MyRow[3]);
				u.bytes_quota = uint64.parse(MyRow[4]);
				u.time_quota = int.parse(MyRow[5]);
				return u;
			}
			return null;
		}
		
		public void save_user_to_db(User user){
			int rc;
			string sql = @"insert into users (login,passwd) values ('$(user.login)','');";
			if ((rc = db.query(sql)) == 1) {
				kerrorlog ("SQL error: "+ db.error() );
			}
		}	
		public void update_user(User user) {
			int rc;
			string sql = @"update users set upbytes=$(user.up_bytes), downbytes=$(user.down_bytes), duration=$(user.duration), bytesquota=$(user.bytes_quota) , timequota=$(user.time_quota) where login='$(user.login)';";
			if ((rc = db.query (sql)) == 1) {
				kerrorlog ("SQL error: "+ db.error() );
			}
		}
		public void remove_user(User user) {
			int rc;
			string sql = @"delete from users where login='$(user.login)';";
			if ((rc = db.query(sql)) == 1) {
				kerrorlog ("SQL error: "+ db.error() );
			}
		}
		/*
			Sessions
		*/
		
		/**
			this function should be call if server restart to retrieve session information and prevent
			users need to reauthenticate.
		*/
		public Session? get_session_from_db (string id, out User? user){
			int rc;
			string sql = @"select device, login, mark, start_time, ip_src from sessions where id='$(id)' LIMIT 1;";
			db.query(sql);
			Result ResultSet = db.use_result();
  			string[] MyRow;
  			while ( (MyRow = ResultSet.fetch_row()) != null ) {
				string login = MyRow[1];
				user = get_user_from_db (login);
				if(user == null)
					return null;
				Session s = new  Session(user, int.parse(MyRow[4]), null);
				s.session_id = id;
				s.mark = int.parse(MyRow[2]);
				TimeVal t = TimeVal();
				t.tv_sec = (long)uint64.parse(MyRow[3]);
				s.start_time = t;
				return s;
			}
			return null;
		}
		
		public void update_session(Session s){}
		
		public void remove_session(Session s){}
		
		public void save_session_to_db(Session s){
			int rc;
			string sql = @"insert into sessions (id,ip_src,mark,start_time,login) values ('$(s.session_id)',$(s.ip_src),$(s.mark),$(s.start_time.tv_sec),'$(s.user.login)');";
			klog(sql);
			if ((rc = db.query(sql)) == 1) {
				kerrorlog ("SQL error: "+ db.error ());
			}
		}
		/*
			Acls
		*/
		public ArrayList<string> get_acls_from_db(AclType type) {
			ArrayList<string> acls = new ArrayList<string>();
			//Sqlite.Statement stmt;
			int rc;
			string sql = @"select id from acls where type=$type;";
			db.query(sql);
			Result ResultSet = db.use_result();
  			string[] MyRow;
  			while ( (MyRow = ResultSet.fetch_row()) != null )
			{
				acls.add(MyRow[0]);
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
