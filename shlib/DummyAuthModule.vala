using GLib;

public class DummyAuthModule : Object, KanetAuthModule {
    public DummyAuthModule() {}
    public bool check_auth (string login, string password, string domain, string ip, out uint8 group_mark) {
        group_mark = (uint8)Random.int_range(0, uint8.MAX);
        return true;
    }
}

//[ModuleInit]
public KanetAuthModule get_plugin () {
    return new DummyAuthModule();
}
