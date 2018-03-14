-- phpMyAdmin SQL Dump
-- version 4.4.15.10
-- https://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Mar 08, 2018 at 12:44 PM
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
(10, 'rhel3', 'maison.ca', 'Red Hat Enterprise V3', '', '', 1, 1, 1, 1, 'Legacy', 'Retired', 1, 'redhat', 'linux', 'TaroonUpdate9', '3', '3', '2017-11-25 12:01:16', '2017-12-31 11:09:11', '2018-03-03 23:23:14', '2017-12-20 18:54:01', '2.4.21-60', 32, 64, 'VM', '', 499, 1, 2798, 1, 1, 1, '192.168.1.131', 'eth0|192.168.1.131|255.255.255.0|00:0c:29:a4:48:2f', '|n', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 20, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(11, 'aixb50', 'maison.ca', 'Aix 5.3 Dev. Server', '', '', 0, 1, 0, 1, 'Legacy', 'Regular', 0, 'aix', 'aix', 'IBM_AIX', '5.3', '5', '2017-11-26 11:25:45', '2017-12-31 11:00:38', '2017-01-28 00:00:32', '0000-00-00 00:00:00', '3', 32, 32, '7046-B50', '01102DD2F', 1024, 1, 375, 1, 1, 1, '192.168.1.102', 'en0|192.168.1.102|255.255.255.0|00:04:ac:17:9c:b3', 'hdisk0|34715,hdisk1|34715', 'rootvg|34688|33600|1088,datavg|34688|256|34432', 1, 1, 0, 0, '', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'YNNNNNNN', 1, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(12, 'batman', 'maison.ca', 'Aix 7.1 NIM Server', '', '', 0, 1, 0, 1, 'Dev', 'Regular', 0, 'aix', 'aix', 'IBM_AIX', '7.1', '7', '2017-11-26 11:27:51', '2017-12-31 11:00:46', '2017-01-29 11:13:26', '0000-00-00 00:00:00', '1', 64, 64, '7028-6C4', '0110549CA', 1024, 1, 1002, 1, 1, 1, '192.168.1.79', 'en0|192.168.1.79|255.255.255.0|00:02:55:cf:28:39', 'hdisk0|140013,hdisk1|140013,hdisk2|140013', 'rootvg|139776|10752|129024,nimvg|139776|15616|124160', 1, 1, 0, 0, '', 0, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'YNNNNNNN', 1, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(13, 'borg', 'maison.ca', 'Linux Virtual Box Server', '', '', 1, 1, 1, 0, 'Dev', 'Temporary', 0, 'centos', 'linux', 'Core', '7.4.1708', '7', '2017-11-26 11:29:00', '2018-02-08 10:04:46', '2018-01-18 23:55:58', '2018-01-18 09:55:25', '3.10.0-693', 64, 64, 'Precision WorkStation 690', '42D05D1', 15884, 2, 1862, 2, 4, 1, '192.168.1.24', 'enp17s0|192.168.1.24|255.255.255.0|00:1a:a0:cd:54:5d', 'sda|1024000,sdb|1024000', 'rootvg|953354|431637|521717', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 1, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(14, 'centos6', 'maison.ca', 'CentOS 6 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'centos', 'linux', 'Final', '6.9', '6', '2017-11-26 11:32:07', '2017-12-31 11:01:15', '2018-03-07 23:25:23', '2018-02-09 10:36:14', '2.6.32-696', 32, 64, 'VM', '', 1006, 1, 2800, 1, 1, 1, '192.168.1.138', 'eth0|192.168.1.138|255.255.255.0|00:50:56:89:40:e4', 'sda|65945', 'rootvg|57088|52767|4321', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 1, 15, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(15, 'centos7', 'maison.ca', 'CentOS 7 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'centos', 'linux', 'Core', '7.4.1708', '7', '2017-11-26 11:34:06', '2017-12-31 11:01:23', '2018-03-07 23:24:18', '2017-12-30 01:45:14', '3.10.0-693', 64, 64, 'VM', '', 1444, 1, 2800, 1, 2, 1, '192.168.1.140', 'ens192|192.168.1.140|255.255.255.0|00:0c:29:b3:81:eb', 'sda|43929', 'rootvg|40448|25150|15298', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 1, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(16, 'debian7', 'maison.ca', 'Debian V7 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'debian', 'linux', 'wheezy', '7.11', '7', '2017-11-26 11:34:46', '2017-12-31 11:01:36', '2018-03-07 23:24:03', '2017-12-30 02:00:53', '3.2.0-4-amd64', 64, 64, 'VM', '', 1002, 1, 2800, 1, 1, 1, '192.168.1.146', 'eth0|192.168.1.146|255.255.255.0|00:50:56:a8:59:a6', 'sda|38502', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 3, 15, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(17, 'debian8', 'maison.ca', 'Debian 8 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'debian', 'linux', 'jessie', '8.10', '8', '2017-11-26 11:35:29', '2017-12-31 11:01:44', '2018-03-07 23:24:40', '2017-12-30 02:15:14', '3.16.0-4-amd64', 64, 64, 'VM', '', 2010, 1, 2800, 1, 1, 1, '192.168.1.147', 'eth0|192.168.1.147|255.255.255.0|00:50:56:a8:e6:f4', 'sda|38502', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(18, 'fedora25', 'maison.ca', 'Fedora 25 Test Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'fedora', 'linux', 'TwentyFive', '25', '25', '2017-11-26 11:37:32', '2017-12-31 11:01:53', '2018-03-07 23:26:41', '2017-12-30 02:45:09', '4.13.16-100', 64, 64, 'VM', '', 990, 1, 2800, 1, 1, 1, '192.168.1.53', 'ens192|192.168.1.53|255.255.255.0|00:50:56:a8:24:64', 'sda|38502', 'rootvg|35328|23348|11980', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(19, 'gandalf', 'maison.ca', 'CentOS V5 Server', '', 'Old Cluster Server', 1, 0, 1, 1, 'Dev', 'Cluster', 1, 'centos', 'linux', 'Final', '5.11', '5', '2017-11-26 11:38:33', '2017-12-31 11:02:03', '2018-03-07 23:24:35', '2017-12-30 03:00:15', '2.6.18-419', 32, 64, 'VM', '', 502, 1, 2800, 1, 1, 1, '192.168.1.103', 'eth0|192.168.1.103|255.255.255.0|00:50:56:89:6f:95', 'sda|32972', 'rootvg|29982|19261|10721', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 1, 30, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(20, 'gotham', 'maison.ca', 'CentOS 5 Server', '', '', 1, 0, 1, 1, 'Test', 'Temporary', 1, 'centos', 'linux', 'Final', '6.9', '6', '2017-11-26 11:39:26', '2017-12-31 11:07:00', '2018-03-07 23:24:58', '2017-12-30 03:45:07', '2.6.32-696', 32, 64, 'VM', '', 1502, 1, 2800, 1, 1, 1, '192.168.1.108', 'eth4|192.168.1.108|255.255.255.0|00:50:56:89:d0:bf', 'sda|65945,sdb|17612,sdc|17612,sdd|105', 'data2vg|96|0|96,datavg|16373|10250|6123,datavg_sdb|16373|4444|11929,rootvg|57088|52480|4608', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 5, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(21, 'gumby', 'maison.ca', 'Old Sysinfo RHEL 5 Server', '', 'Old Master Server - Sysinfo V5', 1, 0, 1, 1, 'Dev', 'Service', 1, 'redhat', 'linux', 'Tikanga', '5.11', '5', '2017-11-26 11:44:34', '2017-12-31 11:07:12', '2018-03-07 23:25:03', '2017-12-30 04:00:18', '2.6.18-419', 32, 64, 'VM', '', 1010, 1, 2800, 1, 1, 1, '192.168.1.101', 'eth0|192.168.1.101|255.255.255.0|00:50:56:89:6f:93,virbr0|192.168.122.1|255.255.255.0|00:00:00:00:00:00', 'sda|164864', 'rootvg|144988|73186|71802', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 1, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(22, 'nomad', 'maison.ca', 'Old Sysinfo CentOS 6 Server', '', '', 1, 0, 1, 1, 'Prod', 'Service', 1, 'centos', 'linux', 'Final', '6.9', '6', '2017-11-26 11:48:51', '2017-12-31 11:07:53', '2018-03-07 23:26:33', '2017-12-30 04:30:09', '2.6.32-696', 32, 64, 'VM', '', 1893, 1, 2800, 1, 1, 1, '192.168.1.66', 'eth0|192.168.1.66|255.255.255.0|00:50:56:a8:24:78,eth0:2|192.168.1.70|255.255.255.0|00:50:56:a8:24:78,eth0:3|192.168.1.69|255.255.255.0|00:50:56:a8:24:78', 'sda|109568', 'rootvg|100003|47687|52316', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 3, 30, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(23, 'puppet', 'maison.ca', 'Puppet Master and Foreman', '', '', 1, 0, 1, 1, 'Poc', 'Service', 1, 'centos', 'linux', 'Final', '6.9', '6', '2017-11-26 11:50:15', '2017-12-31 11:08:04', '2018-03-07 23:25:00', '2017-12-30 04:45:08', '2.6.32-696', 64, 64, 'VM', '', 1877, 1, 2800, 1, 1, 1, '192.168.1.65', 'eth0|192.168.1.65|255.255.255.0|00:0c:29:ce:49:c3', 'sda|54988', 'rootvg|49633|29502|20131', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 15, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(24, 'raspi0', 'maison.ca', 'Raspberry Zero W', '', '', 1, 0, 1, 1, 'Test', 'Raspberry', 0, 'raspbian', 'linux', 'jessie', '8.0', '8', '2017-11-26 11:51:06', '2017-12-31 11:08:15', '2018-03-07 23:26:42', '2017-12-30 05:02:53', '4.9.35+', 32, 32, 'Raspberry Rev.9000c1', '000000007ecb22d4', 434, 1, 1000, 1, 1, 1, '192.168.1.4', 'wlan0|192.168.1.4|255.255.255.0|b8:27:eb:9e:77:81', 'mmcblk0|7860', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 15, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(25, 'raspi1', 'maison.ca', 'Raspberry Pi V1 Modele B+', '', '', 1, 0, 1, 1, 'Dev', 'Raspberry', 0, 'raspbian', 'linux', 'stretch', '9.3', '9', '2017-11-26 11:51:57', '2018-02-07 15:11:10', '2018-03-07 23:30:48', '2017-12-30 05:16:54', '4.9.59+', 32, 32, 'Raspberry Rev.000e', '0000000003e50ba2', 434, 1, 700, 1, 1, 1, '192.168.1.118', 'eth0|192.168.1.118|255.255.255.0|b8:27:eb:e5:0b:a2', 'mmcblk0|16179', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 30, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(26, 'raspi2', 'maison.ca', 'Raspberry Pi V1 Modele XX', '', '', 1, 0, 1, 1, 'Test', 'Raspberry', 0, 'raspbian', 'linux', 'jessie', '8.0', '8', '2017-11-26 11:53:22', '2017-12-31 11:08:39', '2018-03-07 23:30:37', '2017-12-30 01:08:42', '4.9.35+', 32, 32, 'Raspberry Rev.000e', '00000000bd1adcb3', 434, 1, 700, 1, 1, 1, '192.168.1.77', 'eth0|192.168.1.77|255.255.255.0|b8:27:eb:1a:dc:b3', 'mmcblk0|8010', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(27, 'raspi4', 'maison.ca', 'Raspberry Pi 3 Model B Rev 1', '', '', 1, 0, 1, 1, 'Prod', 'Raspberry', 0, 'raspbian', 'linux', 'jessie', '8.0', '8', '2017-11-26 11:54:10', '2018-01-04 10:52:37', '2018-03-07 23:24:24', '2017-12-30 05:45:49', '4.9.35-v7+', 32, 32, 'Raspberry Rev.a02082', '00000000825f3870', 923, 1, 1200, 1, 4, 1, '192.168.1.19', 'eth0:1|192.168.1.127|255.255.255.0|b8:27:eb:5f:38:70,eth0|192.168.1.19|255.255.255.0|b8:27:eb:5f:38:70', 'sda|3073024,sdb|3073024,mmcblk0|32153', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 3, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(28, 'raspi3', 'maison.ca', 'Raspberry Pi V2 Modele B', '', '', 1, 0, 1, 1, 'Test', 'Raspberry', 0, 'raspbian', 'linux', 'jessie', '8.0', '8', '2017-11-26 11:54:53', '2017-12-31 11:08:51', '2018-03-07 23:25:11', '2017-12-30 05:31:49', '4.9.35-v7+', 32, 32, 'Raspberry Rev.a21041', '00000000b2c74c82', 923, 1, 600, 1, 4, 1, '192.168.1.17', 'eth0|192.168.1.17|255.255.255.0|b8:27:eb:c7:4c:82', 'mmcblk0|15872', '', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 3, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(29, 'rhel4', 'maison.ca', 'Red Hat Enterprise V4', '', '', 1, 1, 1, 1, 'Legacy', 'Retired', 1, 'redhat', 'linux', 'NahantUpdate9', '4', '4', '2017-11-26 11:55:37', '2017-12-31 11:09:43', '2018-03-03 23:23:15', '2017-12-20 18:54:04', '2.6.9-106', 32, 64, 'VM', '', 249, 1, 2804, 1, 1, 1, '192.168.1.132', 'eth0|192.168.1.132|255.255.255.0|00:50:56:89:f2:bd', '|n', 'VolGroup00|8069|8037|32', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 2, 45, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(30, 'ubuntu1404', 'maison.ca', 'Ubuntu 14.04 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'ubuntu', 'linux', 'trusty', '14.04', '14', '2017-11-26 11:56:49', '2017-12-31 11:09:53', '2018-03-07 23:23:33', '2017-12-30 06:30:22', '3.13.0-116-generic', 32, 64, 'VM', '', 1001, 1, 2800, 1, 1, 1, '192.168.1.144', 'eth0|192.168.1.144|255.255.255.0|00:50:56:a8:9c:d6', 'sda|43929', 'rootvg|40468|21524|18944', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(31, 'ubuntu1604', 'maison.ca', 'Ubuntu 16.04 Server', '', '', 1, 0, 1, 1, 'Dev', 'Regular', 1, 'ubuntu', 'linux', 'xenial', '16.04', '16', '2017-11-26 11:57:14', '2017-12-31 11:10:04', '2018-03-07 23:24:39', '2017-12-30 06:45:28', '4.4.0-66-generic', 64, 64, 'VM', '', 1496, 1, 2800, 1, 1, 1, '192.168.1.143', 'ens160|192.168.1.143|255.255.255.0|00:50:56:a8:13:5a', 'sda|43929', 'rootvg|40468|21524|18944', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 30, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(32, 'holmes', 'maison.ca', 'DNS,DHCP,Git,Nagios,Wiki', 'Master Server', 'Must Be UP at all time', 1, 0, 1, 1, 'Prod', 'Service', 0, 'centos', 'linux', 'Core', '7.4.1708', '7', '2017-11-26 12:02:25', '2018-02-09 11:57:02', '2018-03-07 23:23:44', '2017-12-30 08:00:30', '3.10.0-693', 64, 64, 'OptiPlex 7020', 'BJSV942', 7731, 1, 3315, 1, 4, 1, '192.168.1.12', 'em1|192.168.1.12|255.255.255.0|98:90:96:b7:64:a2,em1:1|192.168.1.20|255.255.255.0|98:90:96:b7:64:a2,em1:2|192.168.1.68|255.255.255.0|98:90:96:b7:64:a2,em1:3|192.168.1.13|255.255.255.0|98:90:96:b7:64:a2,em1:4|192.168.1.6|255.255.255.0|98:90:96:b7:64:a2,em1:5|192.168.1.23|255.255.255.0|98:90:96:b7:64:a2,em1:6|192.168.1.126|255.255.255.0|98:90:96:b7:64:a2,em1:7|192.168.1.28|255.255.255.0|98:90:96:b7:64:a2', 'sda|512000,sdb|1024000', 'rootvg|476426|376822|99604', 1, 1, 0, 1, 'S', 0, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNNYNN', 6, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
(33, 'nano', 'maison.ca', 'Laptop Acer Aspire One', '', '', 1, 1, 1, 0, 'Dev', 'Laptop', 0, 'centos', 'linux', 'Final', '6.9', '6', '2017-11-26 12:03:36', '2018-02-03 10:06:52', '2018-02-04 23:25:05', '2018-01-18 09:58:44', '2.6.32-696', 32, 32, 'AOA150', 'LUS050B1278440325F2535', 992, 1, 1333, 1, 1, 2, '192.168.1.113', 'eth0|192.168.1.113|255.255.255.0|00:23:8b:20:9f:64,wlan0|192.168.1.226|255.255.255.0|00:23:4e:2e:bb:ed', 'sda|163840', 'rootvg|152483|34273|118210', 1, 1, 0, 1, 'S', 1, 'YNNNNNNNNNNNN', 'YNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN', 'NNNNYNNN', 4, 0, 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
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
(7, 'Temporary', 'Temporaly in service', 1, '2017-11-07 05:00:00', 0),
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
grant all privileges on sadmin.* to sadmin@localhost identified by 'Nimdas17!';
grant all privileges on squery.* to sadmin@localhost identified by 'Squery18!';
flush privileges;
