/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using GLib;
using Kanet.Log;

namespace Kanet.Utils {

    public static string get_id(int length = 36) {
        string CHARS = "0123456789ABCDEF";
        string id = "";
        int r;
        for (int i = 0; i < length; i++) {
            if (id[i] == 0) {
                r = Random.int_range(0,(int32)CHARS.length);
                id += CHARS[r:r+1];
            }
        }
        return id;
    }

    public static string format_seconds(uint32 sec) {
        int day = (int)(sec/(24*60*60));
        int hour = (int)(sec/(60*60))%24;
        int minutes = (int)(sec/60)%60;
        string min = minutes.to_string();
        if(minutes <10) min = "0" + min;
        int seconds = (int)sec%60;
        string secs = seconds.to_string();
        if(seconds < 10) secs = "0" + secs;
        return  @"$day $hour:$min:$secs";
    }
    public static string format_bytes(uint64 bytes) {
        StringBuilder filesize = new StringBuilder();
        if (bytes >= 1073741824) {
            double size = (double)bytes/1073741824;
            filesize.printf("%.2f GB", size);
        } else if (bytes >= 1048576) {
            double size = (double)bytes/1048576;
            filesize.printf("%.2f MB", size);
        } else if (bytes >= 1024) {
            double size = (double)bytes/1048576;
            filesize.printf("%.2f KB", size);
        } else if (bytes > 0 & bytes < 1024) {
            filesize.printf("%d Bytes" ,(int)bytes);
        } else {
            filesize.printf("0 Byte");
        }
        return filesize.str;
    }
    public static uint32 get_mark(string ip_address, uint8 group = 0x00) {
        InetAddress a = new InetAddress.from_string(ip_address);
        uint8 *bytes = (uint8*)a.bytes;
        uint32 result = (group << 24 | (bytes[1] & 0xFF) << 16 | (bytes[2] & 0xFF) << 8 | (bytes[3] & 0xFF));
        klog(@"mark : $result from $ip_address");
        return result;
    }
    public static uint32 get_ip(string ip_address) {
        InetAddress a = new InetAddress.from_string(ip_address);
        return get_ip_from_inet(a);
    }
    public static uint32 get_ip_from_inet(InetAddress a) {
        uint8 *bytes = (uint8*)a.bytes;
        return ((bytes[0] & 0xFF) << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3]);
    }
    public static string get_ip_from_uint32(uint32 ip) {
        return @"$((uint8)(ip >> 24)).$((uint8)(ip >> 16)).$((uint8)(ip >> 8)).$((uint8)ip)";
    }
}
