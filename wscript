#! /usr/bin/env python

NAME = 'kanet'
VERSION = '0.4.0'
APPNAME = 'kanet'
WEBSITE = 'http://code.google.com/p/kanet/'
COPYRIGHT = 'Copyright \xc2\xa9 2010 Cyrille Colin'

RADIUSCLIENT_CONF = '/etc/radiusclient-ng/radiusclient.conf'

top = '.'
out = 'build'

def options(opt):
        opt.load('compiler_c')
        opt.load('vala')

def configure(conf):
	conf.load('compiler_c vala')
	conf.check_cfg(package='glib-2.0', uselib_store='GLIB', atleast_version='2.10.0', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='gio-2.0', uselib_store='GIO', atleast_version='2.16.0', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='gee-1.0', uselib_store='GEE', atleast_version='0.3', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='sqlite3', uselib_store='SQLITE3', atleast_version='3.6.16', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='libsoup-2.4', uselib_store='LIBSOUP', atleast_version='2.28.1', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='json-glib-1.0', uselib_store='JSON', atleast_version='0.7.6', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='gobject-2.0', uselib_store='GOBJECT', atleast_version='2.16.0', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='gmodule-2.0', uselib_store='GMODULE', atleast_version='2.16.0', args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='gthread-2.0', uselib_store="GTHREAD", args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='libdaemon', uselib_store="DAEMON", args='--cflags --libs', mandatory=True)
	conf.check_cfg(package='libvala-0.18', uselib_store='VALA', atleast_version='0.18', args='--cflags --libs', mandatory=True)
	conf.check(lib='radiusclient-ng', uselib_store='radiusclient-ng', mandatory=True)
	conf.check(lib='netfilter_conntrack', uselib_store='netfilter_conntrack', mandatory=True)
	conf.check(lib='netfilter_queue', uselib_store='netfilter_queue', mandatory=True)

	prefix = conf.env['PREFIX']
	if prefix == '/usr' or prefix == '/usr/' :
        	kanetconf = '/etc/kanet/kanet.conf'
	else:
        	kanetconf = prefix + '/etc/kanet/kanet.conf'
	conf.define ('KANET_CONF', kanetconf)
	conf.define ('RADIUSCLIENT_CONF', RADIUSCLIENT_CONF)
	conf.define ('COPYRIGHT', COPYRIGHT)
	conf.define ('APPNAME', NAME)
	conf.define ('DEBUG', -1)
	conf.write_config_header ('config.h')

def build(bld):
        bld.recurse('src shlib conf data www utils')
