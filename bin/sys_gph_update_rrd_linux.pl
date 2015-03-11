#!/usr/bin/perl -w
#
# Script: gph_update_rrd_linux.pl
# Version: 1.1
# Author: Marco Ponton
#
# History:
#  1.1 - 2005/02/02 - Marco Ponton
#        - Added swapping stats
#  1.0 - 2005/01/31 - Marco Ponton
#        - Initial release
#
#
# Information:
#
#   This script updates the RRD file for Linux systems.
#
#
# Usage:
#
#   gph_update_rrd_linux.pl <input_file> <rrd_file>
#
# Example:
#
#   gph_update_rrd_linux.pl perfdata20 lxmq1001.rrd
#
#
# Exit codes:
#
#   0: No error
#   1: Error. Details are printed on stderr.
#
#####################################################################


#####################################################################
#
# Modules
#
#####################################################################

use strict;
no strict "vars";

use English;
use File::Basename;


#####################################################################
#
# Global Variables and Constants
#
#####################################################################

my $BASENAME = basename($0);

my $PERFDATA_FILE = "";
my $RRD_FILE = "";
my $RRDTOOL_CMD = "/usr/bin/rrdtool";

# RAW Performance data (perf. data file content)
my @PERFDATA = ();
# Current index into raw performance data
my $PERFDATA_IDX = 0;

# Hash where key is timestamp in epoch time and value is a second
# hash where the key is a datasource name and the corresponding
# value is the value of this datasource for the timestamp.
# i.e.: { timestamp => { datasource => ds_value } }
# This hash is updated by the "parser functions".
my %PARSED_PERFDATA = ();

# If PRINT_ONLY is true, rrdtool is not run and the update commands
# that would be sent to it are printed on stdout instead. Useful
# for debugging.
my $PRINT_ONLY = 0;


#####################################################################
#
# gph_update_rrd_linux Functions
#
#####################################################################

#--------------------------------------------------------------------
# Function: usage( [ specific_msg ] )
#
# Description: Print usage information and optionally a more specific
#              error message.
#
# Returns: Nothing
#--------------------------------------------------------------------
sub usage(;$)
{
  my $message = shift(@_);

  # If specific error message specified, output it
  defined($message) and ($message ne "" and print("\n$message\n"));
  # Standard usage
  print("\nUsage:\n\n  $BASENAME <input_file> <rrd_file>\n\n");

  exit(255);
}

#--------------------------------------------------------------------
# Function: perfdata_eof()
#
# Description: Return true if there is no more perf. data to be read
#              (i.e. at EOF) else, return false.
#
#
# Returns: True if at perf. data EOF else false.
#--------------------------------------------------------------------
sub perfdata_eof()
{
  return( $PERFDATA_IDX >= @PERFDATA );
}

#--------------------------------------------------------------------
# Function: read_perfdata_line()
#
# Description: Return a line from the perf. data file or "undef" if
#              at EOF.
#
#
# Returns: Line or undef.
#--------------------------------------------------------------------
sub read_perfdata_line()
{
  if (! perfdata_eof())
  {
    my $line = $PERFDATA[$PERFDATA_IDX];
    return($line);
  }
  else
  {
    return(undef);
  }
}

#--------------------------------------------------------------------
# Function: next_perfdata_line()
#
# Description: Skip to next perf. data line.
#
#
# Returns: Nothing. PERFDATA_IDX is updated.
#--------------------------------------------------------------------
sub next_perfdata_line()
{
  if (! perfdata_eof())
  {
    $PERFDATA_IDX++;
  }
}

#--------------------------------------------------------------------
# Function: read_perfdata_header()
#
# Description: Read the next line of perf. data to be processed
#              expecting a header of type "DS:name". If the header
#              is present, return "name", else die().
#
#
# Returns: Name of datasource
#--------------------------------------------------------------------
sub read_perfdata_header()
{
  my $line = read_perfdata_line();
  if ($line =~ /^PERFDATA:(.*)$/)
  {
    my $ds = $1;
    next_perfdata_line();
    return($ds);
  }
  else
  {
    die("Unexpected header format at line $PERFDATA_IDX of input file.");
  }
}

#--------------------------------------------------------------------
# Function: read_perfdata_entry()
#
# Description: Read the next line of perf. data to be processed
#              expecting a data entry with at least two fields. If
#              the data entry is present, return an array containing
#              the fields else, return an empty array.
#
# Returns: Array of fields for this perf. data entry.
#--------------------------------------------------------------------
sub read_perfdata_entry()
{
  my @entry_fields = ();

  # Continue processing only if not at EOF
  if (!perfdata_eof())
  {
    my $line = read_perfdata_line();
    @entry_fields = split(/\s+/, $line);
    if (@entry_fields > 1)
    {
      # OK, this is not a header...
      next_perfdata_line();
    }
    else
    {
      # We reached the next header
      @entry_fields = ();
    }
  }

  return(@entry_fields);
}

#--------------------------------------------------------------------
# Function: initialize_perfdata_entry(timestamp)
#
# Description: Initialize a perf. data entry in PARSED_PERFDATA
#              pointed by timestamp with "UNKNOWN" values.
#
# Returns: Nothing. Perf. data entry is initialized.
#--------------------------------------------------------------------
sub initialize_perfdata_entry($)
{
  my $ts = shift(@_);

  my $href = \%{ $PARSED_PERFDATA{$ts} };

  $$href{cpu_busy} = 'U';
  $$href{cpu_wait} = 'U';
  $$href{mem_free} = 'U';
  $$href{mem_used} = 'U';
  $$href{mem_used_pct} = 'U';
  $$href{mem_cache} = 'U';
  $$href{mempg_alloc_sec} = 'U';
  $$href{swap_in_out_sec} = 'U';
  $$href{swap_free} = 'U';
  $$href{swap_used} = 'U';
  $$href{swap_used_pct} = 'U';
  $$href{pg_in_out_sec} = 'U';
  $$href{disk_tps} = 'U';
  $$href{disk_kbread_sec} = 'U';
  $$href{disk_kbwrtn_sec} = 'U';
  $$href{proc_rque} = 'U';
  $$href{eth0_kbytesin} = 'U';
  $$href{eth0_kbytesout} = 'U';
  $$href{eth1_kbytesin} = 'U';
  $$href{eth1_kbytesout} = 'U';
  $$href{eth2_kbytesin} = 'U';
  $$href{eth2_kbytesout} = 'U';
}

#--------------------------------------------------------------------
# Function: parse_cpu_data()
#
# Description: Calls read_perfdata_entry() and for each entry CPU
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_cpu_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "all")
  #   Field 5: Type (%user, %nice, %system or %idle)
  #   Field 6: Value
  #
  # Example:
  #
  #   lxmq1001  600 1106112000  all %user   71.57
  #   lxmq1001  600 1106112000  all %nice   0.20
  #   lxmq1001  600 1106112000  all %system 1.15
  #   lxmq1001  600 1106112000  all %idle   27.07

  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update cpu datasources
    if (($type eq "%user") or ($type eq "%system") or ($type eq "%nice"))
    {
      if ($$href{cpu_busy} eq "U")
      {
        $$href{cpu_busy} = $value;
      }
      else
      {
        $$href{cpu_busy} += $value;
      }
    }

    # Update cpu_wait datasource
    # NOTE: Not currently supported by sar.
    # if ($type eq "%iowait")
    # {
    #   $$href{cpu_wait} = $value
    # }
  }
}

#--------------------------------------------------------------------
# Function: parse_memusage_data()
#
# Description: Calls read_perfdata_entry() and for each MEM_USAGE entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_memusage_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "-")
  #   Field 5: Type (kbmemfree, kbmemused, %memused, kbmemshrd,
  #                  kbbuffers, kbcached, kbswpfree, kbswpused,
  #                  %swpused)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1001 600 1106977200 - kbmemfree 36352
  # lxmq1001 600 1106977200 - kbmemused 606344
  # lxmq1001 600 1106977200 - %memused  94.34
  # lxmq1001 600 1106977200 - kbmemshrd 0
  # lxmq1001 600 1106977200 - kbbuffers 46392
  # lxmq1001 600 1106977200 - kbcached  455356
  # lxmq1001 600 1106977200 - kbswpfree 811336
  # lxmq1001 600 1106977200 - kbswpused 237224
  # lxmq1001 600 1106977200 - %swpused  22.62

  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update memory datasources
    if ($type eq "kbmemfree")
    {
      # NOTE: Original value is in Kb, divide by 1024 to get Mb
      $$href{mem_free} = $value / 1024;
    }
    elsif ($type eq "kbmemused")
    {
      # NOTE: Original value is in Kb, divide by 1024 to get Mb
      $$href{mem_used} = $value / 1024;
    }
    elsif ($type eq "%memused")
    {
      $$href{mem_used_pct} = $value;
    }
    elsif ($type eq "kbcached")
    {
      # NOTE: Original value is in Kb, divide by 1024 to get Mb
      $$href{mem_cache} = $value / 1024;
    }
    elsif ($type eq "kbswpfree")
    {
      # NOTE: Original value is in Kb, divide by 1024 to get Mb
      $$href{swap_free} = $value / 1024;
    }
    elsif ($type eq "kbswpused")
    {
      # NOTE: Original value is in Kb, divide by 1024 to get Mb
      $$href{swap_used} = $value / 1024;
    }
    elsif ($type eq "%swpused")
    {
      $$href{swap_used_pct} = $value;
    }
  }
}

#--------------------------------------------------------------------
# Function: parse_memstats_data()
#
# Description: Calls read_perfdata_entry() and for each MEM_STATS entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_memstats_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "-")
  #   Field 5: Type (frmpg/s, shmpg/s, bufpg/s, campg/s)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1001 600 1106544000 - frmpg/s 0.64
  # lxmq1001 600 1106544000 - shmpg/s 0.00
  # lxmq1001 600 1106544000 - bufpg/s 0.17
  # lxmq1001 600 1106544000 - campg/s -1.08


  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update run memory pages allocated by second datasource
    if ($type eq "frmpg/s")
    {
      # NOTE: Original date is in pages freed by second and a
      # negative value is a number of pages allocated by second.
      # We will negate this value for our needs.
      $$href{mempg_alloc_sec} = $value * -1;
    }
  }
}

#--------------------------------------------------------------------
# Function: parse_paging_data()
#
# Description: Calls read_perfdata_entry() and for each PAGING entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_paging_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "-")
  #   Field 5: Type (pgpgin/s, pgpgout/s, activepg, inadtypg,
  #                  inaclnpg, inatarpg)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1001 600 1106977200 - pgpgin/s  0.40
  # lxmq1001 600 1106977200 - pgpgout/s 45.18
  # lxmq1001 600 1106977200 - activepg  110559
  # lxmq1001 600 1106977200 - inadtypg  22922
  # lxmq1001 600 1106977200 - inaclnpg  1973
  # lxmq1001 600 1106977200 - inatarpg  28073

  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update paging datasources
    if (($type eq "pgpgin/s") or ($type eq "pgpgout/s"))
    {
      # NOTE: Both values are in blocks/s
      if ($$href{pg_in_out_sec} eq "U")
      {
        $$href{pg_in_out_sec} = $value;
      }
      else
      {
        $$href{pg_in_out_sec} += $value;
      }
    }
  }
}

#--------------------------------------------------------------------
# Function: parse_swapping_data()
#
# Description: Calls read_perfdata_entry() and for each SWAPPING entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_swapping_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "-")
  #   Field 5: Type (pswpin/s, pswpout/s)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1010 600 1107351000 - pswpin/s  0.00
  # lxmq1010 600 1107351000 - pswpout/s 0.00


  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update paging datasources
    if (($type eq "pswpin/s") or ($type eq "pswpout/s"))
    {
      # NOTE: Both values are in blocks/s
      if ($$href{swap_in_out_sec} eq "U")
      {
        $$href{swap_in_out_sec} = $value;
      }
      else
      {
        $$href{swap_in_out_sec} += $value;
      }
    }
  }
}

#--------------------------------------------------------------------
# Function: parse_disk_data()
#
# Description: Calls read_perfdata_entry() and for each DISK entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_disk_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "-")
  #   Field 5: Type (tps, rtps, wtps, bread/s, bwrtn/s)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1001 600 1106977200 - tps     4.13
  # lxmq1001 600 1106977200 - rtps    0.11
  # lxmq1001 600 1106977200 - wtps    4.02
  # lxmq1001 600 1106977200 - bread/s 0.81
  # lxmq1001 600 1106977200 - bwrtn/s 90.36

  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update paging datasources
    if ($type eq "tps")
    {
      $$href{disk_tps} = $value;
    }
    elsif ($type eq "bread/s")
    {
      # Value is in blocks of 512 bytes, divide by 2048 to get Mb
      $$href{disk_kbread_sec} = $value / 2048;
    }
    elsif ($type eq "bwrtn/s")
    {
      # Value is in blocks of 512 bytes, divide by 2048 to get Mb
      $$href{disk_kbwrtn_sec} = $value / 2048;
    }
  }
}

#--------------------------------------------------------------------
# Function: parse_runqueue_data()
#
# Description: Calls read_perfdata_entry() and for each RUNQUEUE entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_runqueue_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (always "-")
  #   Field 5: Type (runq-sz, plist-sz, ldavg-1, ldavg-5)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1001 600 1106112000 - runq-sz  6
  # lxmq1001 600 1106112000 - plist-sz 127
  # lxmq1001 600 1106112000 - ldavg-1  1.24
  # lxmq1001 600 1106112000 - ldavg-5  1.48

  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update run queue datasource
    if ($type eq "runq-sz")
    {
      $$href{proc_rque} = $value;
    }
  }
}

#--------------------------------------------------------------------
# Function: parse_network_data()
#
# Description: Calls read_perfdata_entry() and for each NETWORK entry
#              read update the PARSED_PERFDATA hash appropriately.
#
#
# Returns: Nothing. PARSED_PERFDATA hash is updated.
#--------------------------------------------------------------------
sub parse_network_data()
{
  # Each data entry as the format:
  #
  #   Field 1: Hostname
  #   Field 2: Interval in seconds
  #   Field 3: Timestamp in epoch time
  #   Field 4: Device name (e.g. lo, eth0, eth1)
  #   Field 5: Type (rxpck/s, txpck/s, rxbyt/s, txbyt/s, rxcmp/s,
  #                  txcmp/s, rxmcst/s)
  #   Field 6: Value
  #
  # Example:
  #
  # lxmq1001 600 1106112000 eth0 rxpck/s  1.49
  # lxmq1001 600 1106112000 eth0 txpck/s  0.22
  # lxmq1001 600 1106112000 eth0 rxbyt/s  131.08
  # lxmq1001 600 1106112000 eth0 txbyt/s  167.20
  # lxmq1001 600 1106112000 eth0 rxcmp/s  0.00
  # lxmq1001 600 1106112000 eth0 txcmp/s  0.00
  # lxmq1001 600 1106112000 eth0 rxmcst/s 0.00

  while(@entry_fields = read_perfdata_entry())
  {
    $ts = $entry_fields[2];
    $dev = $entry_fields[3];
    $type = $entry_fields[4];
    $value = $entry_fields[5];

    if (!$PARSED_PERFDATA{$ts})
    {
      initialize_perfdata_entry($ts);
    }

    my $href = \%{ $PARSED_PERFDATA{$ts} };

    # Update run queue datasource
    if ($dev eq "eth0")
    {
      if ($type eq "rxbyt/s")
      {
        # Value is in bytes/s, divide by 1024 to get Kb/s
        $$href{eth0_kbytesin} = $value / 1024;
      }
      elsif ($type eq "txbyt/s")
      {
        # Value is in bytes/s, divide by 1024 to get Kb/s
        $$href{eth0_kbytesout} = $value / 1024;
      }
    }
    elsif ($dev eq "eth1")
    {
      if ($type eq "rxbyt/s")
      {
        # Value is in bytes/s, divide by 1024 to get Kb/s
        $$href{eth1_kbytesin} = $value / 1024;
      }
      elsif ($type eq "txbyt/s")
      {
        # Value is in bytes/s, divide by 1024 to get Kb/s
        $$href{eth1_kbytesout} = $value / 1024;
      }
    }
    elsif ($dev eq "eth2")
    {
      if ($type eq "rxbyt/s")
      {
        # Value is in bytes/s, divide by 1024 to get Kb/s
        $$href{eth2_kbytesin} = $value / 1024;
      }
      elsif ($type eq "txbyt/s")
      {
        # Value is in bytes/s, divide by 1024 to get Kb/s
        $$href{eth2_kbytesout} = $value / 1024;
      }
    }
  }
}

#--------------------------------------------------------------------
# Function: update_rrd_file(rrd_file)
#
# Description: Execute rrdtool utility to update the specified
#              RRD file with the content of PARSED_PERFDATA.
#
# Returns: Nothing. RRD file is is updated.
#--------------------------------------------------------------------
sub update_rrd_file($)
{
  my $rdd_file = shift(@_);

  if ($PRINT_ONLY)
  {
   # dup stdout
    open(RRD_PIPE, ">&STDOUT");
  }
  else
  {
    open(RRD_PIPE, "|$RRDTOOL_CMD -") or die("Failed to open pipe to $RRDTOOL_CMD");
  }

  $update_cmd = "update $rdd_file --t cpu_busy:cpu_wait:".
                "mem_free:mem_used:mem_used_pct:mem_cache:".
                "mempg_alloc_sec:".
                "swap_in_out_sec:swap_free:swap_used:swap_used_pct:".
                "pg_in_out_sec:disk_tps:".
                "disk_kbread_sec:disk_kbwrtn_sec:".
                "proc_rque:eth0_kbytesin:eth0_kbytesout:".
                "eth1_kbytesin:eth1_kbytesout:".
                "eth2_kbytesin:eth2_kbytesout";

  foreach $ts ( sort { $a cmp $b } keys %PARSED_PERFDATA )
  {
    my $href = \%{ $PARSED_PERFDATA{$ts} };
    printf(RRD_PIPE "%s %s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s\n",
           $update_cmd, $ts,
           $$href{cpu_busy}, $$href{cpu_wait},
           $$href{mem_free}, $$href{mem_used}, $$href{mem_used_pct},
           $$href{mem_cache},
           $$href{mempg_alloc_sec},
           $$href{swap_in_out_sec},
           $$href{swap_free}, $$href{swap_used}, $$href{swap_used_pct},
           $$href{pg_in_out_sec},
           $$href{disk_tps}, $$href{disk_kbread_sec}, $$href{disk_kbwrtn_sec},
           $$href{proc_rque},
           $$href{eth0_kbytesin}, $$href{eth0_kbytesout},
           $$href{eth1_kbytesin}, $$href{eth1_kbytesout},
           $$href{eth2_kbytesin}, $$href{eth2_kbytesout});
  }

  close(RRD_PIPE);
}


#####################################################################
#
# MAIN
#
#####################################################################

# Check syntax
(@ARGV != 2) and usage("Invalid number of arguments");
$PERFDATA_FILE = $ARGV[0];
$RRD_FILE = $ARGV[1];

# Load perf. data file into memory
open(PERFDATA_FH, "<$PERFDATA_FILE") or die("Could not open file: $PERFDATA_FILE");
@PERFDATA = <PERFDATA_FH>;
close(PERFDATA_FH);

# Parse performance data
while (!perfdata_eof())
{
  $header = read_perfdata_header();
  # Dispatch parsing to appropriate function depending on header
  if ($header eq "CPU")
  {
    parse_cpu_data();
  }
  elsif ($header eq "MEM_USAGE" or $header eq "MEMORY")
  {
    parse_memusage_data();
  }
  elsif ($header eq "MEM_STATS")
  {
    parse_memstats_data();
  }
  elsif ($header eq "PAGING")
  {
    parse_paging_data();
  }
  elsif ($header eq "SWAPPING")
  {
    parse_swapping_data();
  }
  elsif ($header eq "DISK")
  {
    parse_disk_data();
  }
  elsif ($header eq "RUNQUEUE")
  {
    parse_runqueue_data();
  }
  elsif ($header eq "NETWORK")
  {
    parse_network_data();
  }
  else
  {
    die("Unsupported header '$header'");
  }
}

# Update RRD file
update_rrd_file($RRD_FILE);

exit(0);

