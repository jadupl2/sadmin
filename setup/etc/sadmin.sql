-- phpMyAdmin SQL Dump
-- version 5.2.0-1.el9
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost
-- Généré le : ven. 04 nov. 2022 à 12:53
-- Version du serveur : 10.5.16-MariaDB
-- Version de PHP : 8.0.13

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `sadmin`
--
CREATE DATABASE IF NOT EXISTS `sadmin` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
USE `sadmin`;

-- --------------------------------------------------------

--
-- Structure de la table `script`
--

CREATE TABLE IF NOT EXISTS `script` (
  `scr_id` mediumint(8) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Script ID',
  `scr_name` varchar(40) DEFAULT NULL COMMENT 'Script Name',
  `scr_desc` varchar(80) DEFAULT NULL COMMENT 'Script Description',
  `scr_version` varchar(10) NOT NULL COMMENT 'Script version',
  `scr_alert_grp` varchar(15) DEFAULT NULL COMMENT 'Default Alert Group\r\n',
  `scr_alert_type` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Alert Type (1,2,3,4)',
  `scr_sysadm_email` varchar(50) NOT NULL COMMENT 'Email Address to Alert',
  `scr_multiple_exec` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Run multiple instance',
  `scr_use_rch` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Update RCH file',
  `scr_log_type` varchar(1) NOT NULL DEFAULT 'B' COMMENT 'Log type (L,S,B)',
  `scr_log_append` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Append Log ?',
  `scr_log_header` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Generate header in log',
  `scr_log_footer` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Generate footer in log',
  `scr_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Script active ?',
  `scr_max_logline` int(11) NOT NULL DEFAULT 500 COMMENT 'Max. Lines in log',
  `scr_max_rchline` int(11) NOT NULL DEFAULT 35 COMMENT 'Max. lines in RCH',
  `scr_pid_timeout` int(11) NOT NULL DEFAULT 7200 COMMENT 'PID max. TTL',
  `src_max_inactive_days` int(3) NOT NULL DEFAULT 31 COMMENT 'Days without run threshold before alert (0=Do not check)\r\n\r\n',
  `scr_root_exec` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Need root(1) or not(0)',
  `scr_run_sadmin` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Run on SADMIN Server Only(1) or nay system(0)',
  `scr_os` varchar(10) NOT NULL DEFAULT 'any' COMMENT 'OS on whitch script can be run',
  `scr_last_activity` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'Last Activity date',
  `scr_severity` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Alert severity (1,2,3,4) Error, Warning, Info, None',
  `scr_exclude` set('0','1') NOT NULL DEFAULT '0' COMMENT '1=Exclude from report',
  `scr_log_keepdays` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Nb days to keep inactive log',
  `scr_rch_keepdays` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Nb. Days to keep inactive rch',
  PRIMARY KEY (`scr_id`),
  UNIQUE KEY `scr_name_key` (`scr_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Main Scripts Table';

-- --------------------------------------------------------

--
-- Structure de la table `script_rch`
--

CREATE TABLE IF NOT EXISTS `script_rch` (
  `scrdet_host` varchar(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Script Host Name',
  `scrdet_name` varchar(40) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Script Name',
  `srcdet_start` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Start Date_Time',
  `srcdet_end` timestamp NULL DEFAULT NULL COMMENT 'End Date Time',
  `scrdet_status` tinyint(2) NOT NULL DEFAULT 0 COMMENT 'Status last execution',
  `scrdet_active` int(1) NOT NULL DEFAULT 1 COMMENT '1=Show in Monitor\r\n0=Was acknowledge by Sysadmin don''t show in Monitor',
  `srcdet_elapse` time DEFAULT NULL COMMENT 'Execution Elapse  Time',
  `scrdet_alertcode` tinyint(3) UNSIGNED DEFAULT NULL COMMENT 'Script alert code',
  `scrdet_alertgroup` varchar(30) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Script alert group',
  PRIMARY KEY (`scrdet_host`,`scrdet_name`,`srcdet_start`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


--
-- Structure de la table `server`
--

CREATE TABLE IF NOT EXISTS `server` (
  `srv_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Server ID',
  `srv_name` varchar(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Name',
  `srv_domain` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Domain',
  `srv_desc` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Description',
  `srv_tag` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Server Tag',
  `srv_note` varchar(30) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Server Notes',
  `srv_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Server Active 0=No 1=Yes',
  `srv_sporadic` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Server Sporadically ON?',
  `srv_monitor` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Monitor the Server?',
  `srv_alert_group` varchar(15) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'default' COMMENT 'Alert Group',
  `srv_graph` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Display Performance Graph?',
  `srv_cat` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Category',
  `srv_group` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Group',
  `srv_vm` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'True=VM, False=Physical',
  `srv_osname` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'O/S Name (Fedora,Ubuntu)',
  `srv_ostype` varchar(10) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'linux' COMMENT 'O/S Type linux/aix',
  `srv_oscodename` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'O/S Code Name (Alias)',
  `srv_osversion` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'O/S Version',
  `srv_osver_major` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'O/S Major Version No.',
  `srv_date_creation` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Server Creation Date',
  `srv_date_edit` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Last Edit Date',
  `srv_date_update` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Last Update Date',
  `srv_date_osupdate` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Date of Update',
  `srv_kernel_version` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srv_kernel_bitmode` smallint(11) NOT NULL DEFAULT 64 COMMENT 'Kernel is 32 or 64 bits',
  `srv_hwd_bitmode` smallint(11) NOT NULL DEFAULT 64 COMMENT 'Hardware is 32 or 64 bits',
  `srv_model` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srv_serial` varchar(25) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Hardware Serial No.',
  `srv_memory` int(11) DEFAULT NULL COMMENT 'Amount of Memory in MB',
  `srv_nb_cpu` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Number of Cpu',
  `srv_cpu_speed` int(11) DEFAULT NULL COMMENT 'CPU Speed in MHz',
  `srv_nb_socket` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Number of CPU Socket',
  `srv_core_per_socket` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Number of core per Socket',
  `srv_thread_per_core` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Number of thread per core',
  `srv_ip` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Server Main IP',
  `srv_ips_info` varchar(1024) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'All Server IPS',
  `srv_disks_info` varchar(1024) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Disks Size Info',
  `srv_vgs_info` varchar(1024) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Volume Groups INfo',
  `srv_backup` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Daily Backup 0=No 1=Yes',
  `srv_backup_compress` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Compress backup (tgz)',
  `srv_backup_month` varchar(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNNNNNNN' COMMENT 'Backup Month YNNYNNYNNYNN',
  `srv_backup_dom` varchar(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN' COMMENT 'Backup DayofMonth YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN',
  `srv_backup_dow` varchar(8) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNN' COMMENT 'Backup DayOfWeek YNNNNNNN',
  `srv_backup_hour` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Start Hour of Backuo',
  `srv_backup_minute` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Start Minute of Backup',
  `srv_update_auto` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'OS_Update_Auto (Y=1 N=0)',
  `srv_update_status` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Last O/S Update Status(R/F/S)',
  `srv_update_reboot` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Reboot After Update',
  `srv_update_month` varchar(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNNNNNNN' COMMENT 'Update Month YNNYNNYNNYNN',
  `srv_update_dom` varchar(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN' COMMENT 'Date of Update (1/31) YNNYNNYNNYNN...',
  `srv_update_dow` varchar(8) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNN' COMMENT 'Day of Update Any/Sun/Sat YNNNNNN',
  `srv_update_hour` smallint(6) NOT NULL DEFAULT 1 COMMENT 'Update Start Hour',
  `srv_update_minute` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Update Start Minute',
  `srv_maint` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Activate Maintenance Mode',
  `srv_maint_date_start` datetime DEFAULT NULL COMMENT 'Start Date/Time of Maint. Mode',
  `srv_maint_date_end` datetime DEFAULT NULL COMMENT 'End date/Time of Maintenance Mode',
  `srv_sadmin_dir` varchar(45) COLLATE utf8_unicode_ci NOT NULL DEFAULT '/opt/sadmin' COMMENT 'SADMIN Root Dir. on Client',
  `srv_ssh_port` int(2) NOT NULL DEFAULT 22 COMMENT 'SSH Port to access server',
  `ssh_sudo_user` varchar(10) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'sadmin' COMMENT 'ssh sudo user to server',
  `srv_img_backup` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'ReaR Backup 0=No 1=Yes',
  `srv_img_month` varchar(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNNNNNNN' COMMENT 'Image Backup Backup Month',
  `srv_img_dom` varchar(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN' COMMENT 'Image Backup Day of the month',
  `srv_img_dow` varchar(8) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNN' COMMENT 'Image Backup Day of the Week',
  `srv_img_hour` smallint(6) NOT NULL DEFAULT 4 COMMENT 'Image Backup Start Hour',
  `srv_img_minute` smallint(6) NOT NULL DEFAULT 0 COMMENT 'Image Backup Start Minute',
  `srv_uptime` varchar(25) COLLATE utf8_unicode_ci DEFAULT NULL,
  `srv_arch` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'System Architecture',
  `srv_rear_ver` varchar(7) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'unknown' COMMENT 'Rear Version',
  `srv_boot_date` datetime DEFAULT NULL,
  `srv_reboot_time` int(11) NOT NULL DEFAULT 600 COMMENT 'Nb. Sec, after reboot for App. to be avail.',
  `srv_lock` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'Unlock(0) Lock(1)',
  PRIMARY KEY (`srv_id`),
  UNIQUE KEY `idx_srv_name` (`srv_name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Server Table Information';


--
-- Structure de la table `server_category`
--

CREATE TABLE IF NOT EXISTS `server_category` (
  `cat_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Category ID',
  `cat_code` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Category Code',
  `cat_desc` varchar(25) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Category Description',
  `cat_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Category Active ?',
  `cat_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp() COMMENT 'Cat. Upd. TimeStamp',
  `cat_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Default Category ?',
  PRIMARY KEY (`cat_id`),
  UNIQUE KEY `key_cat_code` (`cat_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Category Table';


--
-- Structure de la table `server_group`
--

CREATE TABLE IF NOT EXISTS `server_group` (
  `grp_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Server Group ID',
  `grp_code` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Groupe Code',
  `grp_desc` varchar(25) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Grp Des.',
  `grp_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Server Active ?',
  `grp_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Group Activity Date',
  `grp_default` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Default Group',
  PRIMARY KEY (`grp_id`),
  UNIQUE KEY `idx_grp_code` (`grp_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Server Group Table';


--
-- Structure de la table `server_network`
--

CREATE TABLE IF NOT EXISTS `server_network` (
  `net_ip` text COLLATE utf8_unicode_ci NOT NULL COMMENT 'IP Address',
  `net_ip_wzero` text COLLATE utf8_unicode_ci NOT NULL COMMENT 'IP with zero included',
  `net_hostname` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'IP Hostname',
  `net_mac` text COLLATE utf8_unicode_ci NOT NULL COMMENT 'IP Mac Address',
  `net_man` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Card Manufacturer (Vendor)',
  `net_ping` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1=Responded to ping, 0=Didn''t',
  `net_date_ping` datetime NOT NULL COMMENT 'Last Ping Respond Date',
  `net_date_update` datetime NOT NULL COMMENT 'Date Last Change',
  PRIMARY KEY (`net_ip`(15)),
  UNIQUE KEY `key_ip_zero` (`net_ip_wzero`(15))
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
