Korn Shell (PD) Configuration and Program Files for uberbaud
=============================================================

This is my personal KSH configuration and is based on workflows which 
I may still be using or which I may have abandoned years ago.

Many of these files were based on *zsh* files and which were 
themselves based on *bash* files from when that was my primary shell. 
You can see the *zsh* files on github in my github
[zsh](https://github.com/uberbaud/zsh) repository.

Install
========

Note: I use **xdg** directories and try to keep dot files out of my 
home directory and everything herein is designed around that concept.  
If you haven't previously set up your own **xdg** directories and 
corresponding variables, you will probably want, at least,
  * XDG_CONFIG_HOME -> ~/config
  * XDG_DATA_HOME   -> ~/local

This is experimental and intended solely for my personal use.  You're 
on your own if you want to use these files yourself.

I'm using OpenBSD, and on OpenBSD you need to modify `/etc/profile` to 
set `ENV=$HOME/config/ksh/kshrc`. I put mine behind a test, so

---
    [[ -n "$KSH_VERSION" ]]&& export ENV=$HOME/config/ksh/kshrc
---

In which case, clone this repository to `$XDG_CONFIG_HOME/ksh`.

Usage
======

Basically, if you want to use any of this, you're on your own.

On OpenBSD there is a help command (`/usr/bin/help`) which is 
essentially the same (possibly exactly the same) as `man help`.  
I don't find that helpful, so I've created my own `help` command which 
checks for files in FPATH and looks for a SYNOPSIS comment which it 
shows OR it `sparkle`s a help file created from the man page for 
builtins or hand crafted. This is based on my experience with *bash*, 
which in this regard at least, I liked.

You can get help on scripts in the `$KDOTDIR/bin` directory by calling 
them with the `-h` flag.

Contributing
=============

Please see [CONTRIBUTING](CONTRIBUTING.md) for details. TLDR; I'm not 
looking for help other than bugfixes.

Copyright
==========

Copyright (C) 2016 by Tom Davis <tom@greyshirt.net>.

` <@(#)tag:csongor.greyshirt.net,2017-08-09:tw/02.57.09z/83fa5a> `
