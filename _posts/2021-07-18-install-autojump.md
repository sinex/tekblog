---
title: Installing autojump
tags: [sysadmin]
---

### 1. Install 
```sh
git clone git://github.com/wting/autojump.git
cd autojump
sudo ./install.py --prefix /usr/local --destdir /usr/local --zshshare /usr/local/share/zsh/site-functions
```

### 2. Update `~/.zshrc`
```sh
if [ -e /usr/local/share/autojump/autojump.zsh ]; then
    source /usr/local/share/autojump/autojump.zsh
fi
```

