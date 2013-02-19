#include        <string.h>
#include        <config.h>
#include        <radiusclient-ng.h>

int radiusclient_check_auth(const char* login, const char* password) {

        int             result;
        char            username[128];
        char            passwd[AUTH_PASS_LEN + 1];
        VALUE_PAIR      *send, *received;
        UINT4           service;
        char            msg[4096], username_realm[256];
        char            *default_realm;
        rc_handle       *rh;

	if ((rh = rc_read_config(RADIUSCLIENT_CONF)) == NULL)
                return ERROR_RC;

        if (rc_read_dictionary(rh, rc_conf_str(rh, "dictionary")) != 0)
                return ERROR_RC;

        default_realm = rc_conf_str(rh, "default_realm");

        strncpy(username, login, sizeof(username));
        strncpy (passwd, password, sizeof (passwd));

        send = NULL;
        /*
         * Fill in User-Name
         */

        strncpy(username_realm, username, sizeof(username_realm));

        /* Append default realm */
        if ((strchr(username_realm, '@') == NULL) && default_realm &&
            (*default_realm != '\0'))
        {
                strncat(username_realm, "@", sizeof(username_realm));
                strncat(username_realm, default_realm, sizeof(username_realm));
        }

        if (rc_avpair_add(rh, &send, PW_USER_NAME, username_realm, -1, 0) == NULL){
		fprintf(stderr, "error av pair \n");
                return ERROR_RC;
	}
        /*
         * Fill in User-Password
         */

        if (rc_avpair_add(rh, &send, PW_USER_PASSWORD, passwd, -1, 0) == NULL)	{
		fprintf(stderr, "error av pair \n");
                return ERROR_RC;
	}

        /*
         * Fill in Service-Type
         */

        service = PW_AUTHENTICATE_ONLY;
        if (rc_avpair_add(rh, &send, PW_SERVICE_TYPE, &service, -1, 0) == NULL) {
		fprintf(stderr, "error av pair \n");
                return ERROR_RC;
	}

        result = rc_auth(rh, 0, send, &received, msg);

        return result;
}

