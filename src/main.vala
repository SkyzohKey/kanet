/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
// project created on 15/03/2010 at 22:02
using GLib;
using Json;
using Kanet;
using Kanet.Utils;
using Kanet.Log;
using Kanet.Conf;
using Daemon;
using Posix;

namespace Kanet {

    static KanetConfiguration CONF;
    static KLOG_LEVEL LOG_LEVEL = KLOG_LEVEL.INFO;
    static KanetApplication k;

    public static int main (string[] args) {
        /*
        	Check for thread support
        */
        if (!Thread.supported ()) {
            kerrorlog ("Cannot run without thread support.",KLOG_LEVEL.FATAL);
            return 1;
        }
        bool background = false;

        foreach (string arg in args) {
            if(arg == "-b" || arg == "--background") {
                background = true;
            }

        }
        if(!background) {
            int ret = start_kanet();
            new MainLoop (null, true).run ();
            return ret;
        }

        /*
        	Daemon Stuff
        */

        pid_t pid;
        pid_file_ident = log_ident = ident_from_argv0(args[0]);

        /* Check that the daemon is not rung twice a the same time */
        if ((pid = pid_file_is_running()) >= 0) {
            Daemon.log(LogPriority.ERR, "Daemon already running on PID file %u", pid);
            return 1;
        }

        retval_init();

        if ((pid = Daemon.fork()) < 0) {
            /* Exit on error */
            retval_done();
            return 1;
        } else if (pid > 0) {
            /* The parent */
            int ret;
            if ((ret = retval_wait(20)) < 0) {
                Daemon.log(LogPriority.ERR, "Could not recieve return value from daemon process.");
                return 255;
            }
            return ret;
        } else {
            /* The daemon */
            int fd = 0;
            fd_set fds = fd_set();

            /* Create the PID file */
            if (pid_file_create() < 0) {
                Daemon.log(LogPriority.ERR, "Could not create PID file (%s).", Posix.strerror(Posix.errno));
                /* Send the error condition to the parent process */
                retval_send(1);
                pid_file_remove();
                return 0;
            }
            /* Initialize signal handling */
            if (signal_init(Sig.INT, Sig.QUIT, Sig.HUP, 0) < 0) {
                Daemon.log(LogPriority.ERR, "Could not register signal handlers (%s).", Posix.strerror(Posix.errno));
                retval_send(2);
                pid_file_remove();
                return 0;
            }

            /* Send OK to parent process */
            retval_send(0);


            /*
            	APPLICATION STUFF
            */
            start_kanet();
            /*
            	END APPLICATION STUFF
            */

            FD_ZERO(out fds);
            FD_SET(fd = signal_fd(),ref fds);

            bool quit = false;
            while(!quit) {

                fd_set fds2 = fds;

                /* Wait for an incoming signal */
                Posix.timeval tm = Posix.timeval();
                tm.tv_sec = 10;
                if (select(1024, &fds2, null, null, tm) < 0) {
                    /* If we've been interrupted by an incoming signal, continue */
                    if (Posix.errno == EINTR)
                        continue;

                    Daemon.log(LogPriority.ERR, "select(): %s", Posix.strerror(Posix.errno));
                    break;
                }
                /* Check if a signal has been recieved */
                if (FD_ISSET(fd, fds) > 0) {
                    int sig;

                    /* Get signal */
                    sig = signal_next();
                    if (sig < 0) {
                        Daemon.log(LogPriority.ERR, "daemon_signal_next() failed.");
                        break;
                    }

                    /* Dispatch signal */
                    switch (sig) {

                    case SIGINT:
                    case SIGQUIT:
                        kerrorlog ("Got SIGINT or SIGQUIT",KLOG_LEVEL.ERROR);
                        //TODO exit stuff
                        quit = true;
                        break;
                        //TODO catch other sig
                    case SIGHUP:

                        break;

                    }
                }


            }

            signal_done();
            pid_file_remove();
            return 0;

        }
    }
    public static int start_kanet() {
        CONF = new KanetConfiguration();
        if(!CONF.check_config_mandatory()) {
            return 1;
        }
        if(CONF.get_configuration_value("DEBUG") == "1") LOG_LEVEL = KLOG_LEVEL.DEBUG;
        k = new KanetApplication();
        return 0;
    }
}
