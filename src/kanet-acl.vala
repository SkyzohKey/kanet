using GLib;
using Gee;
using Kanet.Log;
using Kanet.Conf;

namespace Kanet {

static KLOG_LEVEL LOG_LEVEL = KLOG_LEVEL.DEBUG;
static KanetConfiguration CONF;

public class Main {
    public static int main (string[] args) {
        CONF = new KanetConfiguration();
        string conn_string = CONF.get_configuration_value("database_connection_string");
        if( conn_string == null || conn_string == "") {
            stdout.printf("Unable to get database connstring from config file .. Exit");
            Posix.exit(-1);
        }
        switch(args[1]) {
        case "-l":
        case "--list":
            listAcl(args, conn_string);
            break;
        case "-i":
        case "--insert":
            insertAcl(args, conn_string);
            break;
        case "-d":
        case "--delete":
            deleteAcl(args, conn_string);
            break;
	case "-o":
	    dump(conn_string);
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
    private static void dump(string conn_string) {
	KBase database = new KBaseSqlite(conn_string);
	Acls acls = new Acls(AclType.BLACKLIST);
        acls.load_acls_from_db(database);
        stdout.printf("BLACKLIST\n"+acls.dump()+"\n");
	acls = new Acls(AclType.OPEN);
        acls.load_acls_from_db(database);
        stdout.printf("OPEN\n"+acls.dump()+"\n");
	acls = new Acls(AclType.DEFAULT);
        acls.load_acls_from_db(database);
        stdout.printf("DEFAULT\n"+acls.dump()+"\n");

    }
    private static void deleteAcl(string[] args, string conn_string) {
        if(args.length == 3) {
            KBase database = new KBaseSqlite(conn_string);
            database.remove_acl(args[2]);
        } else {
            getUsage();
        }
    }
    private static void listAcl(string[] args, string conn_string) {
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
    private static void insertAcl(string[] args, string conn_string) {
        Acl a = new Acl();
        switch(args[2].up()) {
        case "BL":
            a.acl_type = AclType.BLACKLIST;
            break;
        case "DEFAULT":
            a.acl_type = AclType.DEFAULT;
            break;
        case "OPEN":
            a.acl_type = AclType.OPEN;
            break;
        default:
            getUsage();
            break;
        }

        if(args[3] == "-h" && (args.length == 5 ||args.length == 6) ) {
            a.address =  args[4];
            if(args.length == 6)
                a.label = args[5];
        } else if (args[3] == "-h" && args[5] == "-p" && (args.length == 7||args.length == 8)) {
            a.address =  args[4];
            a.port = int.parse(args[6]);
            if(args.length == 8)
                a.label = args[7];
        } else if (args[3] == "-p" && (args.length == 5||args.length == 6)) {
            a.port = int.parse(args[4]);
            if(args.length == 6)
                a.label = args[5];
        } else {
            getUsage();
            return;
        }
	a.compute();
        KBase database = new KBaseSqlite(conn_string);
        database.save_acl_to_db(a);
    }
}
}
