---
layout: post
title:  "The Joy of .agignore"
date:   2014-08-05
---

For searching files, I normally use [The Silver
Searcher](https://github.com/ggreer/the_silver_searcher/) (or Ag as it is
commonly shortened), and I've set up [CtrlP](https://github.com/kien/ctrlp.vim)
in Vim to use Ag as well for fuzzy file search. CtrlP is, however, terribly slow
when working with larger projects if you do not scope your search properly. For
quite some time, I've been trying to solve this issue, but I recently stumbled
upon the solution to my agonizing problem.

First of all, since CtrlP uses Ag, it uses the `.agignore` file for ignoring
specific folders, file types, etc. I needed to exclude especially the
`vendor/bundle` folder from the results as it currently contains over 150.000
files that I am not interested in at all. Despite the fact that I configured
`.agignore` accordingly, CtrlP still did not scope my search as expected.

After traversing several pages of search results on Google, I finally found the
solution mentioned in [an issue on
GitHub](https://github.com/ggreer/the_silver_searcher/issues/367). Apparently, I
had to update Ag to version 0.22 as earlier versions of Ag does not respect the
`.agignore` file, and it now works like a charm.
