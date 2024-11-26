# Changelog

 - Aug 5, 2024
   - lxu: now allows -l and -o options
   - my_lxc-turn_into_unprivileged: it adds the line
     lxc.mount.auto = cgroup:mixed proc:mixed sys:rw
     to containers different from slackware to relax lxc.mount.auto (the trick won't work on debian)
