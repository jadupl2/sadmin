-- phpMyAdmin SQL Dump
-- version 4.4.15.10
-- https://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 05, 2018 at 06:57 PM
-- Server version: 5.5.56-MariaDB
-- PHP Version: 5.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sadmin`
--
CREATE DATABASE IF NOT EXISTS `sadmin` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
USE `sadmin`;

-- --------------------------------------------------------

--
-- Table structure for table `server`
--

DROP TABLE IF EXISTS `server`;
CREATE TABLE `server` (
  `srv_id` int(11) NOT NULL COMMENT 'Server ID',
  `srv_name` varchar(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Name',
  `srv_domain` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Domain',
  `srv_desc` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Description',
  `srv_tag` varchar(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Tag',
  `srv_note` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Notes',
  `srv_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Server Active ?',
  `srv_sporadic` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Server Sporadically ON?',
  `srv_monitor` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Monitor the Server?',
  `srv_graph` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Display Performance Graph?',
  `srv_cat` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Category',
  `srv_group` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Group',
  `srv_vm` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'True=VM, False=Physical',
  `srv_osname` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'O/S Name (Fedora,Ubuntu)',
  `srv_ostype` varchar(10) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'linux' COMMENT 'O/S Type linux/aix',
  `srv_oscodename` text COLLATE utf8_unicode_ci NOT NULL COMMENT 'O/S Code Name (Alias)',
  `srv_osversion` varchar(12) COLLATE utf8_unicode_ci NOT NULL COMMENT 'O/S Version',
  `srv_osver_major` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'O/S Major Version No.',
  `srv_date_creation` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Server Creation Date',
  `srv_date_edit` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Last Edit Date',
  `srv_date_update` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Last Update Date',
  `srv_date_osupdate` datetime NOT NULL COMMENT 'Date of Update',
  `srv_kernel_version` varchar(30) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Kernel Version',
  `srv_kernel_bitmode` smallint(11) NOT NULL DEFAULT '64' COMMENT 'Kernel is 32 or 64 bits',
  `srv_hwd_bitmode` smallint(11) NOT NULL DEFAULT '64' COMMENT 'Hardware is 32 or 64 bits',
  `srv_model` varchar(25) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Hardware Model',
  `srv_serial` varchar(25) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Hardware Serial No.',
  `srv_memory` int(11) NOT NULL COMMENT 'Amount of Memory in MB',
  `srv_nb_cpu` smallint(6) NOT NULL DEFAULT '1' COMMENT 'Number of Cpu',
  `srv_cpu_speed` int(11) NOT NULL COMMENT 'CPU Speed in MHz',
  `srv_nb_socket` smallint(6) NOT NULL DEFAULT '1' COMMENT 'Number of CPU Socket',
  `srv_core_per_socket` smallint(6) NOT NULL DEFAULT '1' COMMENT 'Number of core per Socket',
  `srv_thread_per_core` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Number of thread per core',
  `srv_ip` varchar(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Main IP',
  `srv_ips_info` varchar(1024) COLLATE utf8_unicode_ci NOT NULL COMMENT 'All Server IPS',
  `srv_disks_info` varchar(1024) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Disks Size Info',
  `srv_vgs_info` varchar(1024) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Volume Groups INfo',
  `srv_backup` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Execute Backup Script',
  `srv_backup_hour` smallint(6) NOT NULL DEFAULT '1' COMMENT 'Start Hour of Backuo',
  `srv_backup_minute` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Start Minute of Backup',
  `srv_update_auto` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'O/S Update Auto Schedule',
  `srv_update_status` varchar(1) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Last O/S Update Status(R/F/S)',
  `srv_update_reboot` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Reboot After Update',
  `srv_update_month` varchar(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YYYYYYYYYYYYY' COMMENT 'Update Month YNNYNNYNNYNN',
  `srv_update_dom` varchar(32) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'NYNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN' COMMENT 'Date of Update (1/31) YNNYNNYNNYNN...',
  `srv_update_dow` varchar(8) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'YNNNNNNN' COMMENT 'Day of Update Any/Sun/Sat YNNNNNN',
  `srv_update_hour` smallint(6) NOT NULL DEFAULT '1' COMMENT 'Update Start Hour',
  `srv_update_minute` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Update Start Minute',
  `srv_maint` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Activate Maintenance Mode',
  `srv_maint_date_start` datetime NOT NULL COMMENT 'Start Date/Time of Maint. Mode',
  `srv_maint_date_end` datetime NOT NULL COMMENT 'End date/Time of Maintenance Mode'
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Server Table Information';

--
-- Table structure for table `server_category`
--

DROP TABLE IF EXISTS `server_category`;
CREATE TABLE `server_category` (
  `cat_id` int(11) NOT NULL COMMENT 'Category ID',
  `cat_code` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Category Code',
  `cat_desc` varchar(25) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Category Description',
  `cat_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Category Active ?',
  `cat_date` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP COMMENT 'Cat. Upd. TimeStamp',
  `cat_default` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Default Category ?'
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Category Table';

--
-- Dumping data for table `server_category`
--

INSERT INTO `server_category` (`cat_id`, `cat_code`, `cat_desc`, `cat_active`, `cat_date`, `cat_default`) VALUES
(3, 'Dev', 'Development Environment', 1, '2017-11-07 05:00:00', 1),
(5, 'Poc', 'Proof Of Concept env.', 1, '2017-11-07 05:00:00', 0),
(6, 'Prod', 'Production Environment', 1, '2017-11-07 05:00:00', 0),
(11, 'Temp', 'Temporary Server', 1, '2017-12-06 16:23:26', 0);

-- --------------------------------------------------------

--
-- Table structure for table `server_group`
--

DROP TABLE IF EXISTS `server_group`;
CREATE TABLE `server_group` (
  `grp_id` int(11) NOT NULL COMMENT 'Server Group ID',
  `grp_code` varchar(10) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Groupe Code',
  `grp_desc` varchar(25) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Grp Des.',
  `grp_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Server Active ?',
  `grp_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Group Activity Date',
  `grp_default` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Default Group'
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Server Group Table';

--
-- Dumping data for table `server_group`
--

INSERT INTO `server_group` (`grp_id`, `grp_code`, `grp_desc`, `grp_active`, `grp_date`, `grp_default`) VALUES
(2, 'Legacy', 'Legacy O/S version', 1, '2017-11-22 16:55:50', 0),
(3, 'Service', 'Infrastructure Service', 1, '2017-11-07 05:00:00', 0),
(4, 'Retired', 'Server not in use', 1, '2017-11-07 05:00:00', 0),
(5, 'Raspberry', 'Raspberry Pi', 1, '2017-11-07 05:00:00', 0),
(6, 'Regular', 'App. Server', 1, '2017-11-23 17:33:43', 1),
(8, 'Laptop', 'Linux Laptop', 1, '2017-11-07 05:00:00', 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `server`
--
ALTER TABLE `server`
  ADD PRIMARY KEY (`srv_id`),
  ADD UNIQUE KEY `idx_srv_name` (`srv_name`) USING BTREE;

--
-- Indexes for table `server_category`
--
ALTER TABLE `server_category`
  ADD PRIMARY KEY (`cat_id`),
  ADD UNIQUE KEY `key_cat_code` (`cat_code`) USING BTREE;

--
-- Indexes for table `server_group`
--
ALTER TABLE `server_group`
  ADD PRIMARY KEY (`grp_id`),
  ADD UNIQUE KEY `idx_grp_code` (`grp_code`) USING BTREE;

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `server`
--
ALTER TABLE `server`
  MODIFY `srv_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Server ID',AUTO_INCREMENT=35;
--
-- AUTO_INCREMENT for table `server_category`
--
ALTER TABLE `server_category`
  MODIFY `cat_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Category ID',AUTO_INCREMENT=12;
--
-- AUTO_INCREMENT for table `server_group`
--
ALTER TABLE `server_group`
  MODIFY `grp_id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Server Group ID',AUTO_INCREMENT=9;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
