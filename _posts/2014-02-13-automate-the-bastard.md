---
layout: post
title:  "Automate the Bastard"
date:   2014-02-13
---

Getting a new machine can be quite an ambivalent experience. You're often
finding yourself in a position where you're happy about the increased power
available and thinner look of the new machine, but despising the entire process
of setting the bastard up to your needs. It should not have to be this way.

To me, automating a machine setup is one of the most important things any
developer can do. Our setups are often tweaked down to the smallest details,
and it should be easy to return to those particular details as fast as
possible, so that we can spend our time on more meaningful matters.

In order to get rid of this horrible process, I created a repository on GitHub
called [machine](https://github.com/majjoha/machine) that takes care of this
process for me. I simply just download the repository on a new machine and run
``machine/bootstrap`` which sets up everything to my needs. It aims to be usable
on both Mac and Ubuntu machines, where the Mac is mainly for my daily
operations, and the Ubuntu is primarily for small server instances where I just
need Vim, tmux and friends.

Furthermore, this repository also installs all of my
[dotfiles](https://github.com/majjoha/dotfiles) which are a selection of files I
use to configure zsh, Git, Vim and so on.

Because of the great [Homebrew package manager](http://brew.sh/), it is
incredibly easy to setup most apps, but, unfortunately, Homebrew does not
support regular apps with a graphical user interface out of the box, so instead
I use [homebrew-cask](https://github.com/phinze/homebrew-cask) for this.  By
combining the power of both Homebrew and homebrew-cask, I can easily setup a
machine that has my dotfiles, iTerm2, Alfred, Dropbox, 1password and all the
other necessities I need. If you aren't already automating your setup in a
similar fashion, you should definitely do it. You never know when it will come
in handy.
