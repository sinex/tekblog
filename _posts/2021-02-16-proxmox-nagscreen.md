---
title: Remove nagscreen from Proxmox
tags: [virtual-machines, proxmox, sysadmin]
---

Trying to run a homelab on the cheap, and keep getting reminded of your cheapness?

![Proxmox nag screen](/assets/img/proxmox-nagscreen.png){: width="500px"}


Disable checked commands:

```sh
#!/bin/sh

PROXMOXLIB_JS=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

PATCH_COMMENT="// NO_CHECKED_COMMAND_PATCH"

if grep -q "$PATCH_COMMENT" "$PROXMOXLIB_JS"; then
        echo 'Already patched!'
        exit 0
fi

set -x
sed -i 's,\(checked_command: function(\([^,]*\).*) {\),\1\n\t\2(); return; '"$PATCH_COMMENT," "$PROXMOXLIB_JS"
```

