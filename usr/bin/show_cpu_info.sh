#!/bin/sh
#
# This simple script uses /proc/cpuinfo (or filename of your choosing) to print
# a succinct summary about a system's processors.
# Other useful utilities (some only available in RHEL6 or EPEL):
#   x86info, dmidecode, lscpu, cpuid, lshw, lstopo, xsos
#
# Originally uploaded to redhat.com by Ryan Sawhill <rsaw@redhat.com>, Sep 2012; Updated Jan 2013
# This code is from xsos, which can do so much more <http://github.com/ryran/xsos>
#

# Get input
if [[ -r $1 && -f $1 ]]; then
  # If passed a readable file, use that
  cpuinfo=$1
else
  # Otherwise, use /proc/cpuinfo
  cpuinfo=/proc/cpuinfo
fi

# Get model of cpu
model_cpu=$(awk -F: '/^model name/{print $2; exit}' <"$cpuinfo")

# If no model detected (e.g. on Itanium), try to use vendor+family
[[ -z $model_cpu ]] && {
  vendor=$(awk -F: '/^vendor /{print $2; exit}' <"$cpuinfo")
  family=$(awk -F: '/^family /{print $2; exit}' <"$cpuinfo")
  model_cpu="$vendor$family"
}

# Clean up cpu model string
model_cpu=$(sed -e 's,(R),,g' -e 's,(TM),,g' -e 's,  *, ,g' -e 's,^ ,,' <<<"$model_cpu")

# Get number of logical processors
num_cpu=$(awk '/^processor/{n++} END{print n}' <"$cpuinfo")

# Get number of physical processors
num_cpu_phys=$(grep '^physical id' <"$cpuinfo" | sort -u | wc -l)

# If "physical id" not found, we cannot make any assumptions (Virtualization--)
# But still, multiplying by 0 in some crazy corner case is bad, so set it to 1
# If num of physical *was* detected, add it to the beginning of the model string
[[ $num_cpu_phys == 0 ]] && num_cpu_phys=1 || model_cpu="$num_cpu_phys $model_cpu"

# If number of logical != number of physical, try to get info on cores & threads
if [[ $num_cpu != $num_cpu_phys ]]; then
  
  # Detect number of threads (logical) per cpu
  num_threads_per_cpu=$(awk '/^siblings/{print $3; exit}' <"$cpuinfo")
  
  # Two possibile ways to detect number of cores
  cpu_cores=$(awk '/^cpu cores/{print $4; exit}' <"$cpuinfo")
  core_id=$(grep '^core id' <"$cpuinfo" | sort -u | wc -l)
  
  # The first is the most accurate, if it works
  if [[ -n $cpu_cores ]]; then
    num_cores_per_cpu=$cpu_cores
  
  # If "cpu cores" doesn't work, "core id" method might (e.g. Itanium)
  elif [[ $core_id -gt 0 ]]; then
    num_cores_per_cpu=$core_id
  fi
  
  # If found info on cores, setup core variables for printing
  if [[ -n $num_cores_per_cpu ]]; then
    cores1="($((num_cpu_phys*num_cores_per_cpu)) CPU cores)"
    cores2=" / $num_cores_per_cpu cores"
  # If didn't find info on cores, assume single-core cpu(s)
  else
    cores2=" / 1 core"
  fi
  
  # If found siblings (threads), setup the variable for the final line
  [[ -n $num_threads_per_cpu ]] &&
    coresNthreads="\n└─$num_threads_per_cpu threads${cores2} each"
fi

# Check important cpu flags
# pae=physical address extensions  *  lm=64-bit  *  vmx=Intel hw-virt  *  svm=AMD hw-virt
# ht=hyper-threading  *  aes=AES-NI  *  constant_tsc=Constant Time Stamp Counter
cpu_flags=$(egrep -o "pae|lm|vmx|svm|ht|aes|constant_tsc" <"$cpuinfo" | sort -u | sed ':a;N;$!ba;s/\n/,/g')
[[ -n $cpu_flags ]] && cpu_flags="(flags: $cpu_flags)"

# Check kernel version; print warning if Xen
[[ $(uname -r) =~ xen ]] && {
  echo "Warning: kernel for localhost detected as $(uname -r)"
  echo "With Xen, CPU layout in /proc/cpuinfo will be inaccurate; consult dmidecode"
}

# Print out the deets
echo -e "${num_cpu} logical processors ${cores1}"
echo -e "${model_cpu} ${cpu_flags} ${coresNthreads}"

