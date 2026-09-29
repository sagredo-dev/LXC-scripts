# Changelog

- Sep 29, 2026
  - Added cgroup v2 support. Thanks to 0XBF
  - lxc-my_template: Update version in the generated slackpkg.conf, changed mirror,
  - current.template: added fprintd (required by pam), ngtcp2
  - lxcctl can stop unprivileged containers by executing lxl --active for each owner
  - dropped cgroupctl rc.cgconfig.patch files
  - on rename adjust mount points with the old name in config
  - my_lxc-copy now allows -6 option with arguments
  - lxcctl now uses lxu/lxd to start/stop containers. This solved an hang up
    on latest slackware current which prevented the containers to boot properly.
  - Added ipv6 support. Old container name replaced by the new one in config's mount points
  - fixed bug lxc/lxc#4560 (comment)

- Jun 14, 2025
  - lxc-common.conf: cgroup2 compat (limits not applied successfully yet)
  - rc.lxc-bridge and rc.lxc-nat updates
  - Avoiding the full path when importing my_lxc-common
  - Number of processors determined dinamically in my_lxc-turn_into_unprivileged

- Mar 8, 2025
  - added slackpkg+ to slackware-current template 

- Jan 13, 2025
  - Trick to fake a systemd cgroup mount on lxcctl
  - added network config for systemd containers
  - number of cpus now is [0-7]

- Aug 5, 2024
  - lxu: now allows -l and -o options
  - my_lxc-turn_into_unprivileged: it adds the line
    lxc.mount.auto = cgroup:mixed proc:mixed sys:rw
    to containers different from slackware to relax lxc.mount.auto (the trick won't work on debian)
