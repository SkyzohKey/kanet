/*
	Kanet, Control access to network
	Copyright (C) 2010 Cyrille Colin.
*/
using GLib;

public interface KanetAuthModule : Object {

    public abstract bool check_auth (string login, string password, string domain, string ip, out uint8 group_mark);

}
