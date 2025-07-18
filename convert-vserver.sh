#!/bin/bash

###########################################################################
# This script converts a Slackware Linux-VServer into an LXC container
# setting up its configuration.
# It is a modification of Matteo Bernardini's Slackware template for LXC
# by Roberto Puzzanghera
# More info here https://www.sagredo.eu/en/other-contents-186/migrating-from-linux-vserver-to-lxc-slackware-235.html
###########################################################################

#
# lxc: linux Container library

# Authors:
# Daniel Lezcano <daniel.lezcano@free.fr>

# Template for slackware by Matteo Bernardini <ponce@slackbuilds.org>
# some parts are taken from the debian one (used as model)

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#######################################################################

# Comment if using the default lxc.lxcpath=/var/lib/lxc
# Don't use symbolic links as lxcpath here
lxcpath="/usr/local/lxc"

configure_slackware()
{
rootfs=$1
hostname=$2

echo "Configuring..." ; echo

# The next part contains excerpts taken from SeTconfig (written by
# Patrick Volkerding) from the slackware setup disk.
# But before pasting them just set a variable to use them as they are 
T_PX=$rootfs

( cd $T_PX ; chmod 755 ./ )
( cd $T_PX ; chmod 755 ./var )
if [ -d $T_PX/usr/src/linux ]; then
  chmod 755 $T_PX/usr/src/linux
fi
if [ ! -d $T_PX/proc ]; then
  mkdir $T_PX/proc
  chown root.root $T_PX/proc
fi
if [ ! -d $T_PX/sys ]; then
  mkdir $T_PX/sys
  chown root.root $T_PX/sys
fi
chmod 1777 $T_PX/tmp
if [ ! -d $T_PX/var/spool/mail ]; then
  mkdir -p $T_PX/var/spool/mail
  chmod 755 $T_PX/var/spool
  chown root.mail $T_PX/var/spool/mail
  chmod 1777 $T_PX/var/spool/mail
fi

# Network configuration is left to the user, that have to edit
# /etc/rc.d/rc.inet1.conf and /etc/resolv.conf of the container
# just set the hostname
#
cp $rootfs/etc/HOSTNAME $rootfs/etc/hostname

# remove existing linux-vserver /dev dir
rm -r $rootfs/dev

# make needed devices, from Chris Willing's MAKEDEV.sh
# http://www.vislab.uq.edu.au/howto/lxc/MAKEDEV.sh
DEV=$rootfs/dev
mkdir -p ${DEV}
mknod -m 666 ${DEV}/null c 1 3
mknod -m 666 ${DEV}/zero c 1 5
mknod -m 666 ${DEV}/random c 1 8
mknod -m 666 ${DEV}/urandom c 1 9
mkdir -m 755 ${DEV}/pts
mkdir -m 1777 ${DEV}/shm
mknod -m 666 ${DEV}/tty c 5 0
mknod -m 600 ${DEV}/console c 5 1
mknod -m 666 ${DEV}/tty0 c 4 0
mknod -m 666 ${DEV}/tty1 c 4 1
mknod -m 666 ${DEV}/tty2 c 4 2
mknod -m 666 ${DEV}/tty3 c 4 3
mknod -m 666 ${DEV}/tty4 c 4 4
mknod -m 666 ${DEV}/tty5 c 4 5
mknod -m 666 ${DEV}/full c 1 7
mknod -m 600 ${DEV}/initctl p
mknod -m 660 ${DEV}/loop0 b 7 0
mknod -m 660 ${DEV}/loop1 b 7 1
ln -s pts/ptmx ${DEV}/ptmx
ln -s /proc/self/fd ${DEV}/fd

# remember to add later mounts to fstab from /etc/vserver/<name>/fstab
echo "Adding an etc/fstab that must be modified later with the"
echo "full path of the container's rootfs if you decide to move it."
cat >$rootfs/etc/fstab <<EOF
lxcpts $rootfs/dev/pts devpts defaults,newinstance 0 0
# proc & sys, removed from /etc/fstab because already mounted via config file
#none $rootfs/proc    proc   defaults 0 0
#none $rootfs/sys     sysfs  defaults 0 0
none /dev/shm tmpfs defaults 0 0
none /run tmpfs defaults,mode=0755 0 0
EOF

# Copy the rc.d init scripts and backup the existing ones:
mv $rootfs/etc/rc.d $rootfs/etc/rc.d-original
cp -rp rc.d $rootfs/etc/
# restore at least the original rc.local. Check the other script later...
rm $rootfs/etc/rc.d/rc.local
cp -p $rootfs/etc/rc.d-original/rc.local $rootfs/etc/rc.d/rc.local

# restart rc.inet1 to have routing for the loop device
echo "/etc/rc.d/rc.inet1 restart" >> $rootfs/etc/rc.d/rc.local

# reduce the number of local consoles: two should be enough
sed -i '/^c3\|^c4\|^c5\|^c6/s/^/# /' $rootfs/etc/inittab

# In a container, use shutdown for powerfail conditions.  LXC sends the SIGPWR
# signal to init to shut down the container with lxc-stop and without this the
# container will be force stopped after a one minute timeout.
sed -i "s,pf::powerfail:/sbin/genpowerfail start,pf::powerfail:/sbin/shutdown -h now,g" $rootfs/etc/inittab
sed -i "s,pg::powerokwait:/sbin/genpowerfail stop,pg::powerokwait:/sbin/shutdown -c,g" $rootfs/etc/inittab

# borrow the time configuration from the local machine
cp -a /etc/localtime $rootfs/etc/localtime

return 0
}

copy_configuration()
{
path=$1
name=$2

cat <<EOF >> $path/$name/config
lxc.start.auto = 0
lxc.uts.name = $name
lxc.mount.fstab = $path/$name/rootfs/etc/fstab
lxc.rootfs.path = dir:$path/$name/rootfs

lxc.include = /etc/lxc/lxc-common.conf
EOF

if [ $? -ne 0 ]; then
	echo "Failed to add configuration."
	return 1
fi

# install extra slackware packages needed to lxc
installpkg --root $path/$name/rootfs $PWD/extra-pkg/*.t?z

# configure resolv.conf in the guest
cat <<EOF > $path/$name/rootfs/etc/resolv.conf
nameserver 10.0.0.10
nameserver 10.0.0.1
EOF

# install a couple of suitable aliases...
cat <<EOF > $path/$name/rootfs/root/.bashrc
alias rm='rm -I'
alias ls='ls --color=always'
alias grep="grep --color=auto"
alias tree="tree -C"
alias wget="wget --no-check-certificate"
alias dmesg="dmesg -HPL"
export EDITOR=/usr/bin/nano
export VISUAL='/usr/bin/nano'

export alias
EOF

return 0
}

usage()
{
cat <<HELP

$1 -h|--help -n|--name=<name> -p|--path=<path>

 -n|--name=<name> -- the name of the container
 -p|--path=<path> -- the content of the variable lxc.lxcpath (default is /var/lib/lxc)
 -h|--help        -- this help

HELP
return 0
}

options=$(getopt -o hp:n:a:r:c -l help,rootfs:,path:,name: --  "$@")
if [ $? -ne 0 ]; then
	usage $(basename $0)
	exit 1
fi
eval set -- "$options"

while true
do
case "$1" in
        -h|--help)      usage $0 && exit 0;;
        -p|--path)      path=$2; shift 2;;
	-n|--name)      name=$2; shift 2;;
        --)             shift 1; break ;;
        *)              break ;;
esac
done

# root id check
if [ "$(id -u)" != "0" ]; then
	echo "This script should be run as 'root'."
	exit 1
fi

# detect container's name
if [ -z $name ]; then
	# no name given
	echo "Please provide the container's name:"
	echo $1 "-n|--name=<name>"
	exit 1
fi

# detect path
if [ -z $path ] && [ -z $lxcpath ]; then
        echo "'path' is missing."
	echo "Please set -p|--path=<path> or 'lxcpath' parameter."
        exit 1
elif [ ! -z $lxcpath ] && [ ! -d $lxcpath ]; then
        echo "$lxcpath from 'lxcpath' parameter is missing."
        exit 1
elif [ ! -z $path ] && [ ! -d $path ]; then
        echo "$path from --path parameter is missing."
        exit 1
elif [ ! -z $lxcpath ] && [ -d $lxcpath ]; then
	path=$lxcpath
elif [ ! -z $path ] && [ -d $path ]; then
        path=$path
else
	# default lxcpath
	path="/var/lib/lxc"
fi
if [ ! -d $path ]; then
	echo "$path is missing"
fi

# detect rootfs
config="$path/$name/config"
rootfs=$path/$name/rootfs
if [ -z "$rootfs" ] || [ ! -d $rootfs ]; then
        echo "$rootfs is missing"
	exit 1
fi

echo

set -e

configure_slackware $rootfs $name
if [ $? -ne 0 ]; then
	echo "Failed to configure slackware for a container."
	exit 1
fi

echo
echo

copy_configuration $path $name
if [ $? -ne 0 ]; then
	echo "Failed to write configuration file."
	exit 1
fi
