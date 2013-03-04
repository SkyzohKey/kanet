CREATE TABLE IF NOT EXISTS 'user' (
  'login' TEXT PRIMARY KEY,
  'password' TEXT,
  'upbytes' INTEGER UNSIGNED,
  'downbytes' INTEGER UNSIGNED,
  'duration' INTEGER UNSIGNED,
  'bytesquota' INTEGER UNSIGNED,
  'timequota' INTEGER UNSIGNED
);
CREATE TABLE IF NOT EXISTS 'acl' (
  'id' TEXT PRIMARY KEY,
  'address' TEXT,
  'ipaddresses' TEXT,
  'label'  TEXT NOT NULL,
  'port'  INTEGER UNSIGNED,
  'type'  INTEGER UNSIGNED
);
CREATE TABLE IF NOT EXISTS 'session' (
  'id' TEXT PRIMARY KEY,
  'ip_src' INTEGER,
  'last_seen' NUMERIC,
  'login' TEXT,
  'mark' NUMERIC,
  'start_time' NUMERIC
);
CREATE UNIQUE INDEX IF NOT EXISTS users_index1 ON user(login ASC);
CREATE UNIQUE INDEX IF NOT EXISTS sessions_index1 ON session(id ASC);
