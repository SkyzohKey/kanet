/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using GLib;

namespace Kanet.Log {
    public enum KLOG_LEVEL {
        DEBUG,
        INFO,
        ERROR,
        FATAL
    }
    public static void klog(string message, KLOG_LEVEL log_level = KLOG_LEVEL.DEBUG ) {

        stdout.printf("%s",message + "\n");
        k_log("[KANET] " + message, log_level);
    }
    public static void kerrorlog(string message, KLOG_LEVEL log_level = KLOG_LEVEL.DEBUG ) {
        stderr.printf("%s", message + "\n");
        k_log("[KANET-ERROR] " + message, log_level);
    }
    public static void kaccesslog(string message, KLOG_LEVEL log_level = KLOG_LEVEL.INFO ) {
        k_log("[KANET-ACCESS] " + message, log_level);
    }
    private static void k_log(string message, KLOG_LEVEL log_level) {
        if(log_level >= LOG_LEVEL)
            Posix.syslog(Posix.LOG_USER,"%s", message);
    }
}