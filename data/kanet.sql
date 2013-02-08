drop table if exists users;
drop table if exists acls;
drop table if exists sessions;

CREATE TABLE users (login VARCHAR(64), passwd VARCHAR(64), upbytes INTEGER, downbytes INTEGER, duration INTEGER, timequota INTEGER, bytesquota INTEGER);
CREATE TABLE acls (address VARCHAR(64), filename VARCHAR(64), id VARCHAR(64), label VARCHAR(64), port INTEGER, type INTEGER);
CREATE TABLE sessions (ip_src INTEGER, device VARCHAR(64), id VARCHAR(64), last_seen INTEGER, login VARCHAR(64), mark INTEGER, start_time INTEGER);
CREATE UNIQUE INDEX users_index1 ON users(login ASC);
CREATE UNIQUE INDEX sessions_index1 ON sessions(id ASC);

