using GLib;
using Curses;
using Gee;
using Kanet.Log;
using Kanet.Conf;

namespace Kanet {

	static KLOG_LEVEL LOG_LEVEL = KLOG_LEVEL.INFO;
	static KanetConfiguration CONF;
	static string conn_string="data/kanet4.sqlite";
	
	public class Main
	{
	  public static int main (string[] args)
	  {
		CONF = new KanetConfiguration(); 
		switch(args[1]) {
			case "-l":
			case "--list":
				listAcl(args);
			break;
			case "-i":
			case "--insert":
				insertAcl(args);				
			break;
			case "-d":
			case "--delete":
				deleteAcl(args);
			break;
			default :
				getUsage();
				break;
		}
		return 0;
	  }
	  private static void getUsage() {
		  stdout.printf("usage : kanet-acl command [option] \n");
			stdout.printf("\n");
			stdout.printf("\t-l | --list [acltype] : list all acls, or of a specified type [bl|open|default]\n");
			stdout.printf("\t-i | --insert acltype [-h host/address] [-p port] [label]: create the specified acl\n");
			stdout.printf("\t-d | --delete id : delete acl\n");
			stdout.printf("\n");
			Posix.exit(-1);
	  }
	  private static void deleteAcl(string[] args) {
		if(args.length == 3) {
			KBase database = new KBaseSqlite(conn_string);
			database.remove_acl(args[2]);
		} else {
			getUsage();
		}
	  } 
	  private static void listAcl(string[] args) {
		  stdout.printf("Acl list\n");
		  KBase database = new KBaseSqlite(conn_string);
		  if(args.length == 2) { // just -l
				Acls acls = new Acls(AclType.BLACKLIST);
				acls.load_acls_from_db(database);
				foreach(Acl a in acls.acls) {
					stdout.printf(a.to_json()+"\n");
				}
				acls = new Acls(AclType.OPEN);
				acls.load_acls_from_db(database);				
				foreach(Acl a in acls.acls) {
					stdout.printf(a.to_json()+"\n");
				}
				acls = new Acls(AclType.DEFAULT);
				acls.load_acls_from_db(database);
				foreach(Acl a in acls.acls) {
					stdout.printf(a.to_json()+"\n");
				}
		  } else if (args.length == 3) {
			  switch(args[2].up()) {
				  case "BL":
				Acls acls = new Acls(AclType.BLACKLIST);
				acls.load_acls_from_db(database);
				foreach(Acl a in acls.acls) {
					stdout.printf(a.to_json()+"\n");
				}
				  break;
				  case "OPEN":
				Acls acls = new Acls(AclType.OPEN);
				acls.load_acls_from_db(database);
				foreach(Acl a in acls.acls) {
					stdout.printf(a.to_json()+"\n");
				}
				  break;
				  case "DEFAULT":
				Acls acls = new Acls(AclType.DEFAULT);
				acls.load_acls_from_db(database);
				foreach(Acl a in acls.acls) {
					stdout.printf(a.to_json()+"\n");
				}
				  break;
				  default:
					getUsage();
					break;
			  }
		  }
	  }
	  private static void insertAcl(string[] args) {
		  Acl a = new Acl();
		  if(args[2] == "-h" && (args.length == 4 ||args.length == 5) ) {
			   a.address =  args[3];
			   if(args.length == 5)
				a.label = args[4];
		  } 
		  else if (args[2] == "-h" && args[4] == "-p" && (args.length == 6||args.length == 7))
		  {
			  a.address =  args[3];
			  a.port = int.parse(args[5]);
			   if(args.length == 7)
				a.label = args[6];
		  }
		  else if (args[2] == "-p" && (args.length == 4||args.length == 5)) {
			  a.port = int.parse(args[3]);
			   if(args.length == 5)
				a.label = args[4];
		  } else {
			  getUsage();
			  return;
		  }
		  KBase database = new KBaseSqlite(conn_string);
		  database.save_acl_to_db(a);
	  }
	}
}
