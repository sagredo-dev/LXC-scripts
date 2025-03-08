# Changelog

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
