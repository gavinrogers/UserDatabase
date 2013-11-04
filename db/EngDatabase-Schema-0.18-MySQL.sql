-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu Sep 26 16:02:17 2013
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `PP_ATTRIBUTES`;

--
-- Table: `PP_ATTRIBUTES`
--
CREATE TABLE `PP_ATTRIBUTES` (
  `ATTRIBUTE_ID` integer NOT NULL,
  `ATTRIBUTE_NAME` text NOT NULL,
  PRIMARY KEY (`ATTRIBUTE_ID`),
  UNIQUE `PP_ATTRIBUTES_ATTRIBUTE_NAME` (`ATTRIBUTE_NAME`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `PP_GROUPS`;

--
-- Table: `PP_GROUPS`
--
CREATE TABLE `PP_GROUPS` (
  `GROUP_ID` integer NOT NULL,
  `GID` integer NOT NULL,
  `GROUP_NAME` text NULL,
  `GROUP_DESC` text NULL,
  PRIMARY KEY (`GROUP_ID`),
  UNIQUE `PP_GROUPS_GROUP_NAME_GID` (`GROUP_NAME`, `GID`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `PP_STATUSES`;

--
-- Table: `PP_STATUSES`
--
CREATE TABLE `PP_STATUSES` (
  `STATUS_ID` integer NOT NULL,
  `STATUS_NAME`  NULL,
  `AD_PASSWORD`  NULL,
  `AUTOMOUNTER`  NULL,
  `AD_ENABLED`  NULL,
  `TRUST_ALLOWED`  NULL,
  `UNIX_PASSWD`  NULL,
  `UNIX_ENABLED`  NULL,
  `PROP_DEPT`  NULL,
  `PROP_MAIL`  NULL,
  `PROP_DIVA`  NULL,
  `PROP_DIVB`  NULL,
  `PROP_DIVF`  NULL,
  `PROP_FLUID`  NULL,
  `PROP_STRUCT`  NULL,
  `PROP_WHITTLE`  NULL,
  `PROP_WORKS`  NULL,
  `PROP_TEST`  NULL,
  PRIMARY KEY (`STATUS_ID`),
  UNIQUE `PP_STATUSES_STATUS_NAME` (`STATUS_NAME`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `PP_USERS`;

--
-- Table: `PP_USERS`
--
CREATE TABLE `PP_USERS` (
  `USER_ID` integer NOT NULL,
  `CRSID` text NOT NULL,
  `ENGID` text NULL,
  `UID` integer NOT NULL,
  `GECOS`  NULL,
  `HOMEDIR`  NULL,
  `PASSWORD_EXPIRY_DATE`  NULL,
  `PROPAGATION`  NULL,
  `STATUS_ID` integer NOT NULL,
  `STATUS_DATE`  NULL,
  INDEX `PP_USERS_idx_STATUS_ID` (`STATUS_ID`),
  PRIMARY KEY (`USER_ID`),
  UNIQUE `PP_USERS_ENGID_CRSID_UID` (`ENGID`, `CRSID`, `UID`),
  CONSTRAINT `PP_USERS_fk_STATUS_ID` FOREIGN KEY (`STATUS_ID`) REFERENCES `PP_STATUSES` (`STATUS_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `PP_USER_CAPABILITIES`;

--
-- Table: `PP_USER_CAPABILITIES`
--
CREATE TABLE `PP_USER_CAPABILITIES` (
  `CAPABILITIES_ID` integer NOT NULL,
  `USER_ID` integer NOT NULL,
  `STATUS_NAME`  NULL,
  `AD_PASSWORD`  NULL,
  `AUTOMOUNTER`  NULL,
  `AD_ENABLED`  NULL,
  `TRUST_ALLOWED`  NULL,
  `UNIX_PASSWD`  NULL,
  `UNIX_ENABLED`  NULL,
  `PROP_DEPT`  NULL,
  `PROP_MAIL`  NULL,
  `PROP_DIVA`  NULL,
  `PROP_DIVB`  NULL,
  `PROP_DIVF`  NULL,
  `PROP_FLUID`  NULL,
  `PROP_STRUCT`  NULL,
  `PROP_WHITTLE`  NULL,
  `PROP_WORKS`  NULL,
  `PROP_TEST`  NULL,
  INDEX `PP_USER_CAPABILITIES_idx_USER_ID` (`USER_ID`),
  PRIMARY KEY (`CAPABILITIES_ID`),
  UNIQUE `PP_USER_CAPABILITIES_CAPABILITIES_ID_USER_ID` (`CAPABILITIES_ID`, `USER_ID`),
  CONSTRAINT `PP_USER_CAPABILITIES_fk_USER_ID` FOREIGN KEY (`USER_ID`) REFERENCES `PP_USERS` (`USER_ID`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `PP_GROUP_MEMBERSHIPS`;

--
-- Table: `PP_GROUP_MEMBERSHIPS`
--
CREATE TABLE `PP_GROUP_MEMBERSHIPS` (
  `GROUP_MEMBERSHIP_ID` integer NOT NULL,
  `USER_ID` integer NOT NULL,
  `GROUP_ID` integer NOT NULL,
  `PRIMARY_GROUP` integer NOT NULL,
  `AFFILIATION_GROUP` integer NOT NULL,
  INDEX `PP_GROUP_MEMBERSHIPS_idx_GROUP_ID` (`GROUP_ID`),
  INDEX `PP_GROUP_MEMBERSHIPS_idx_USER_ID` (`USER_ID`),
  PRIMARY KEY (`GROUP_MEMBERSHIP_ID`),
  CONSTRAINT `PP_GROUP_MEMBERSHIPS_fk_GROUP_ID` FOREIGN KEY (`GROUP_ID`) REFERENCES `PP_GROUPS` (`GROUP_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `PP_GROUP_MEMBERSHIPS_fk_USER_ID` FOREIGN KEY (`USER_ID`) REFERENCES `PP_USERS` (`USER_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `PP_USER_ATTRIBUTES`;

--
-- Table: `PP_USER_ATTRIBUTES`
--
CREATE TABLE `PP_USER_ATTRIBUTES` (
  `USER_ATTRIBUTE_ID` integer NOT NULL,
  `USER_ID` text NOT NULL,
  `ATTRIBUTE_ID` integer NOT NULL,
  `ATTRIBUTE_VALUE`  NULL,
  `ATTRIBUTE_EFFECTIVE_DATE`  NULL,
  `ATTRIBUTE_EXPIRY_DATE`  NULL,
  INDEX `PP_USER_ATTRIBUTES_idx_ATTRIBUTE_ID` (`ATTRIBUTE_ID`),
  INDEX `PP_USER_ATTRIBUTES_idx_USER_ID` (`USER_ID`),
  PRIMARY KEY (`USER_ATTRIBUTE_ID`),
  CONSTRAINT `PP_USER_ATTRIBUTES_fk_ATTRIBUTE_ID` FOREIGN KEY (`ATTRIBUTE_ID`) REFERENCES `PP_ATTRIBUTES` (`ATTRIBUTE_ID`),
  CONSTRAINT `PP_USER_ATTRIBUTES_fk_USER_ID` FOREIGN KEY (`USER_ID`) REFERENCES `PP_USERS` (`USER_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;
