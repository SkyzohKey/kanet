using GLib;

public class RadiusAuthModule : Object, KanetAuthModule {
	public RadiusAuthModule() {}
	public bool check_auth (string login, string password, string domain, string ip, out uint8 group_mark) {
		if(radiusclient_check_auth(login,password) == 0) 
			return true;
		return false;
	}
}

//[ModuleInit]
public KanetAuthModule get_plugin () {
    return new RadiusAuthModule();
}
