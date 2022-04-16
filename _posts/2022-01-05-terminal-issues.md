---
title: Fix terminal printing weird characters when using the mouse
tags: [sysadmin, workarounds]
---

My terminal prints weird characters when clicking or using the scroll wheel!

Some applications such as `vim` and `tmux` use _cursor addressing mode_.
Usually this mode will be reset once the program exits, but if a crash or unexpected disconnect occurs, then it may not be reset properly.

To reset it manually, either open and close `vim`, or execute:

```sh
tput rmcup
```

Source: [https://www.igorkromin.net/index.php/2016/05/05/mouse-wheel-displaying-control-characters-in-a-terminal-or-scrolling-through-history-instead](https://www.igorkromin.net/index.php/2016/05/05/mouse-wheel-displaying-control-characters-in-a-terminal-or-scrolling-through-history-instead)
([Archive](https://web.archive.org/web/20210517040931/https://www.igorkromin.net/index.php/2016/05/05/mouse-wheel-displaying-control-characters-in-a-terminal-or-scrolling-through-history-instead/))

