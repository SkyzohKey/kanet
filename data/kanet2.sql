CREATE TABLE users (login VARCHAR, passwd VARCHAR, upbytes NUMERIC, downbytes NUMERIC, duration NUMERIC, timequota NUMERIC, bytesquota NUMERIC);
CREATE TABLE acls (address VARCHAR, filename VARCHAR, id VARCHAR, label VARCHAR, port NUMERIC, type NUMERIC);
CREATE TABLE sessions (ip_src NUMERIC, device VARCHAR, id VARCHAR, last_seen NUMERIC, login VARCHAR, mark NUMERIC, start_time NUMERIC);
CREATE UNIQUE INDEX users_index1 ON users(login ASC);
CREATE UNIQUE INDEX sessions_index1 ON sessions(id ASC);

