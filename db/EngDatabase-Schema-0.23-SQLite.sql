-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Nov  5 14:04:41 2013
-- 

BEGIN TRANSACTION;

--
-- Table: PP_ATTRIBUTES
--
DROP TABLE PP_ATTRIBUTES;

CREATE TABLE PP_ATTRIBUTES (
  ATTRIBUTE_ID INTEGER PRIMARY KEY NOT NULL,
  ATTRIBUTE_NAME varchar2(100) NOT NULL
);

CREATE UNIQUE INDEX name ON PP_ATTRIBUTES (ATTRIBUTE_NAME);

--
-- Table: PP_GROUPS
--
DROP TABLE PP_GROUPS;

CREATE TABLE PP_GROUPS (
  GROUP_ID INTEGER PRIMARY KEY NOT NULL,
  GID integer(11) NOT NULL,
  GROUP_NAME varchar2(50),
  GROUP_DESC varchar2(100)
);

CREATE UNIQUE INDEX GID ON PP_GROUPS (GID);

--
-- Table: PP_STATUSES
--
DROP TABLE PP_STATUSES;

CREATE TABLE PP_STATUSES (
  STATUS_ID INTEGER PRIMARY KEY NOT NULL,
  STATUS_NAME varchar2(100),
  AD_PASSWORD integer(1),
  AUTOMOUNTER integer(1),
  AD_ENABLED integer(1),
  TRUST_ALLOWED integer(1),
  UNIX_PASSWD integer(1),
  UNIX_ENABLED integer(1),
  PROP_TEACH integer(1),
  PROP_MAIL integer(1),
  PROP_DIVA integer(1),
  PROP_DIVB integer(1),
  PROP_DIVF integer(1),
  PROP_FLUID integer(1),
  PROP_STRUCT integer(1),
  PROP_WHITTLE integer(1),
  PROP_WORKS integer(1),
  PROP_TEST integer(1)
);

CREATE UNIQUE INDEX PP_STATUSES_STATUS_NAME ON PP_STATUSES (STATUS_NAME);

--
-- Table: PP_USERS
--
DROP TABLE PP_USERS;

CREATE TABLE PP_USERS (
  USER_ID INTEGER PRIMARY KEY NOT NULL,
  CRSID varchar2(10) NOT NULL,
  ENGID text,
  UID integer(11) NOT NULL,
  GECOS varchar2(100),
  HOMEDIR varchar2(100),
  PASSWORD_EXPIRY_DATE varchar2(100),
  PROPAGATION varchar2(100),
  STATUS_ID integer(11) NOT NULL,
  STATUS_DATE date,
  FOREIGN KEY (STATUS_ID) REFERENCES PP_STATUSES(STATUS_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX PP_USERS_idx_STATUS_ID ON PP_USERS (STATUS_ID);

CREATE UNIQUE INDEX CRSID ON PP_USERS (CRSID);

CREATE UNIQUE INDEX ENGID ON PP_USERS (ENGID);

CREATE UNIQUE INDEX both ON PP_USERS (ENGID, CRSID);

--
-- Table: PP_USER_CAPABILITIES
--
DROP TABLE PP_USER_CAPABILITIES;

CREATE TABLE PP_USER_CAPABILITIES (
  CAPABILITIES_ID INTEGER PRIMARY KEY NOT NULL,
  USER_ID integer(11) NOT NULL,
  AD_ENABLED integer(1),
  AD_PASSWORD integer(1),
  AUTOMOUNTER integer(1),
  TRUST_ALLOWED integer(1),
  UNIX_PASSWD integer(1),
  UNIX_ENABLED integer(1),
  PROP_TEACH integer(1),
  PROP_MAIL integer(1),
  PROP_DIVA integer(1),
  PROP_DIVB integer(1),
  PROP_DIVF integer(1),
  PROP_FLUID integer(1),
  PROP_STRUCT integer(1),
  PROP_WHITTLE integer(1),
  PROP_WORKS integer(1),
  PROP_TEST integer(1),
  FOREIGN KEY (USER_ID) REFERENCES PP_USERS(USER_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX PP_USER_CAPABILITIES_idx_USER_ID ON PP_USER_CAPABILITIES (USER_ID);

CREATE UNIQUE INDEX PP_USER_CAPABILITIES_CAPABILITIES_ID_USER_ID ON PP_USER_CAPABILITIES (CAPABILITIES_ID, USER_ID);

--
-- Table: PP_GROUP_MEMBERSHIPS
--
DROP TABLE PP_GROUP_MEMBERSHIPS;

CREATE TABLE PP_GROUP_MEMBERSHIPS (
  GROUP_MEMBERSHIP_ID INTEGER PRIMARY KEY NOT NULL,
  USER_ID integer(11) NOT NULL,
  GROUP_ID integer(11) NOT NULL,
  PRIMARY_GROUP integer(1) NOT NULL,
  AFFILIATION_GROUP integer(1) NOT NULL,
  FOREIGN KEY (GROUP_ID) REFERENCES PP_GROUPS(GROUP_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (USER_ID) REFERENCES PP_USERS(USER_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX PP_GROUP_MEMBERSHIPS_idx_GROUP_ID ON PP_GROUP_MEMBERSHIPS (GROUP_ID);

CREATE INDEX PP_GROUP_MEMBERSHIPS_idx_USER_ID ON PP_GROUP_MEMBERSHIPS (USER_ID);

CREATE UNIQUE INDEX affiliationgroup ON PP_GROUP_MEMBERSHIPS (GROUP_MEMBERSHIP_ID, AFFILIATION_GROUP);

CREATE UNIQUE INDEX both02 ON PP_GROUP_MEMBERSHIPS (GROUP_MEMBERSHIP_ID, PRIMARY_GROUP, AFFILIATION_GROUP);

CREATE UNIQUE INDEX primarygroup ON PP_GROUP_MEMBERSHIPS (GROUP_MEMBERSHIP_ID, PRIMARY_GROUP);

--
-- Table: PP_USER_ATTRIBUTES
--
DROP TABLE PP_USER_ATTRIBUTES;

CREATE TABLE PP_USER_ATTRIBUTES (
  USER_ATTRIBUTE_ID INTEGER PRIMARY KEY NOT NULL,
  USER_ID integer(11) NOT NULL,
  ATTRIBUTE_ID integer(11) NOT NULL,
  ATTRIBUTE_VALUE varchar2(100),
  ATTRIBUTE_EFFECTIVE_DATE date,
  ATTRIBUTE_EXPIRY_DATE date,
  FOREIGN KEY (ATTRIBUTE_ID) REFERENCES PP_ATTRIBUTES(ATTRIBUTE_ID),
  FOREIGN KEY (USER_ID) REFERENCES PP_USERS(USER_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX PP_USER_ATTRIBUTES_idx_ATTRIBUTE_ID ON PP_USER_ATTRIBUTES (ATTRIBUTE_ID);

CREATE INDEX PP_USER_ATTRIBUTES_idx_USER_ID ON PP_USER_ATTRIBUTES (USER_ID);

CREATE UNIQUE INDEX both03 ON PP_USER_ATTRIBUTES (USER_ID, ATTRIBUTE_EFFECTIVE_DATE, ATTRIBUTE_EXPIRY_DATE);

CREATE UNIQUE INDEX effective ON PP_USER_ATTRIBUTES (USER_ID, ATTRIBUTE_EFFECTIVE_DATE);

CREATE UNIQUE INDEX expiry ON PP_USER_ATTRIBUTES (USER_ID, ATTRIBUTE_EXPIRY_DATE);

COMMIT;
