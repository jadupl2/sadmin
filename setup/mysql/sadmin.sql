-- phpMyAdmin SQL Dump
-- version 4.4.15.10
-- https://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Mar 08, 2018 at 09:54 AM
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

-- --------------------------------------------------------

--
-- Table structure for table `server`
--

CREATE TABLE IF NOT EXISTS `server` (
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
-- Dumping data for table `server`
--

INSERT INTO `server` (`srv_id`, `srv_name`, `srv_domain`, `srv_desc`, `srv_tag`, `srv_note`, `srv_active`, `srv_sporadic`, `srv_monitor`, `srv_graph`, `srv_cat`, `srv_group`, `srv_vm`, `srv_osname`, `srv_ostype`, `srv_oscodename`, `srv_osversion`, `srv_osver_major`, `srv_date_creation`, `srv_date_edit`, `srv_date_update`, `srv_date_osupdate`, `srv_kernel_version`, `srv_kernel_bitmode`, `srv_hwd_bitmode`, `srv_model`, `srv_serial`, `srv_memory`, `srv_nb_cpu`, `srv_cpu_speed`, `srv_nb_socket`, `srv_core_per_socket`, `srv_thread_per_core`, `srv_ip`, `srv_ips_info`, `srv_disks_info`, `srv_vgs_info`, `srv_backup`, `srv_backup_hour`, `srv_backup_minute`, `srv_update_auto`, `srv_update_status`, `srv_update_reboot`, `srv_update_month`, `srv_update_dom`, `srv_update_dow`, `srv_update_hour`, `srv_update_minute`, `srv_maint`, `srv_maint_date_start`, `srv_maint_date_end`) VALUES
(15, 'centos7', 'maison.ca', 'CentOS 7 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'centos', 'linux', 'Core', '7.4.1708', '7', '2017-11-26 11:34:06', '2017-12-31 11:01:23', '2018-03-07 23:24:18', '2017-12-30 01:45:14', '3.10.0-693', 64, 64, 'VM', '', 1444, 1, 2800, 1, 2, 1, '192.168.1.140', 'ens192|192.168.1.140|255.255.255.0|00:0c:29:b3:81:eb', 'sda|43929', 'rootvg|40448|25150|15298', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 1, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(17, 'debian8', 'maison.ca', 'Debian 8 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'debian', 'linux', 'jessie', '8.10', '8', '2017-11-26 11:35:29', '2017-12-31 11:01:44', '2018-03-07 23:24:40', '2017-12-30 02:15:14', '3.16.0-4-amd64', 64, 64, 'VM', '', 2010, 1, 2800, 1, 1, 1, '192.168.1.147', 'eth0|192.168.1.147|255.255.255.0|00:50:56:a8:e6:f4', 'sda|38502', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(18, 'fedora25', 'maison.ca', 'Fedora 25 Test Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'fedora', 'linux', 'TwentyFive', '25', '25', '2017-11-26 11:37:32', '2017-12-31 11:01:53', '2018-03-07 23:26:41', '2017-12-30 02:45:09', '4.13.16-100', 64, 64, 'VM', '', 990, 1, 2800, 1, 1, 1, '192.168.1.53', 'ens192|192.168.1.53|255.255.255.0|00:50:56:a8:24:64', 'sda|38502', 'rootvg|35328|23348|11980', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(24, 'raspi0', 'maison.ca', 'Raspberry Zero W', '', '', 1, 0, 1, 1, 'Test', 'Raspberry', 0, 'raspbian', 'linux', 'jessie', '8.0', '8', '2017-11-26 11:51:06', '2017-12-31 11:08:15', '2018-03-07 23:26:42', '2017-12-30 05:02:53', '4.9.35+', 32, 32, 'Raspberry Rev.9000c1', '000000007ecb22d4', 434, 1, 1000, 1, 1, 1, '192.168.1.4', 'wlan0|192.168.1.4|255.255.255.0|b8:27:eb:9e:77:81', 'mmcblk0|7860', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 15, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(27, 'raspi4', 'maison.ca', 'Raspberry Pi 3 Model B Rev 1', '', '', 1, 0, 1, 1, 'Prod', 'Raspberry', 0, 'raspbian', 'linux', 'jessie', '8.0', '8', '2017-11-26 11:54:10', '2018-01-04 10:52:37', '2018-03-07 23:24:24', '2017-12-30 05:45:49', '4.9.35-v7+', 32, 32, 'Raspberry Rev.a02082', '00000000825f3870', 923, 1, 1200, 1, 4, 1, '192.168.1.19', 'eth0:1|192.168.1.127|255.255.255.0|b8:27:eb:5f:38:70,eth0|192.168.1.19|255.255.255.0|b8:27:eb:5f:38:70', 'sda|3073024,sdb|3073024,mmcblk0|32153', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 3, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(31, 'ubuntu1604', 'maison.ca', 'Ubuntu 16.04 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'ubuntu', 'linux', 'xenial', '16.04', '16', '2017-11-26 11:57:14', '2017-12-31 11:10:04', '2018-03-07 23:24:39', '2017-12-30 06:45:28', '4.4.0-66-generic', 64, 64, 'VM', '', 1496, 1, 2800, 1, 1, 1, '192.168.1.143', 'ens160|192.168.1.143|255.255.255.0|00:50:56:a8:13:5a', 'sda|43929', 'rootvg|40468|21524|18944', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 30, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(34, 'yoda', 'maison.ca', 'Laptop Ubuntu 16.04', '', '', 1, 1, 1, 1, 'Dev', 'Laptop', 0, 'ubuntu', 'linux', 'xenial', '16.04', '16', '2017-11-26 12:04:56', '2018-02-05 09:28:35', '2018-03-01 23:23:35', '2018-02-12 11:30:58', '4.4.0-116-generic', 64, 64, 'Latitude D630', 'HSD0PH1', 3942, 1, 1200, 1, 2, 1, '192.168.1.10', 'enp9s0|192.168.1.10|255.255.255.0|00:21:70:b2:b7:21,wlx000f13280a37|192.168.1.18|255.255.255.0|00:0f:13:28:0a:37', 'sda|122880', 'rootvg|113981|33802|80179', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 5, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `server_category`
--

CREATE TABLE IF NOT EXISTS `server_category` (
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
(2, 'Legacy', 'Legacy Unsupported Server', 1, '2017-11-07 05:00:00', 0),
(3, 'Dev', 'Development Environment', 1, '2017-11-07 05:00:00', 1),
(5, 'Poc', 'Proof Of Concept env.', 1, '2017-11-07 05:00:00', 0),
(6, 'Prod', 'Production Environment', 1, '2017-11-07 05:00:00', 0),
(11, 'Temporary', 'Temporary Server', 1, '2017-12-06 16:23:26', 0);

-- --------------------------------------------------------

--
-- Table structure for table `server_group`
--

CREATE TABLE IF NOT EXISTS `server_group` (
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
(2, 'Cluster', 'Clustered Server', 1, '2017-11-22 16:55:50', 0),
(3, 'Service', 'Infrastructure Service', 1, '2017-11-07 05:00:00', 0),
(4, 'Retired', 'Server not in use', 1, '2017-11-07 05:00:00', 0),
(5, 'Raspberry', 'Raspberry Pi', 1, '2017-11-07 05:00:00', 0),
(6, 'Regular', 'Normal App. Server', 1, '2017-11-23 17:33:43', 1),
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
