---
layout: post
title:  "Encrypting Files With GPG and Vim"
date:   2015-01-27
---

I do most of my writing in Vim whether it is programming or editing ordinary
documents. The only two exceptions are journals and emails. For journals, I've
been using [Day One](http://dayoneapp.com) for quite an extensive amount of time
now, but I've been considering to replace it with Vim. In order to replace Day
One, I need a way to effortlessly encrypt and decrypt text files. In this post,
I'll show you how I've set up an environment that enables me to do so.

By default, Vim provides you with the ability to encrypt and decrypt files in a
quite simple manner. You open a file with `vim -x my-top-secret-document.md` or
the `:X` command, and then Vim prompts you for an encryption key. When you've
entered the encryption key twice, you are able to edit the document. If you try
to print the document with `cat` afterwards, you'll see gibberish like
`VimCrypt~01!gd)�/�:�-(%)`, but if you open the file with Vim, the editor will
prompt you for the key phrase, and after entering the correct encryption key you
can read and edit the file. There is a caveat to this approach, however.
According to the `:X` help page, Vim has not been tested for robustness, and we
do not want swap files, the `viminfo` file or any other files for that matter to
expose our file contents, so instead we are going to rely on
[GPG](https://www.gnupg.org/) and
[autocommands](http://learnvimscriptthehardway.stevelosh.com/chapters/12.html).

What we need to include in our `.vimrc` is the following autocommand group:

{% highlight vim %}
augroup encrypted
  autocmd!
  autocmd BufReadPre,FileReadPre *.gpg set viminfo=
  autocmd BufReadPre,FileReadPre *.gpg set noswapfile noundofile nobackup
  autocmd BufReadPost *.gpg :%!gpg --decrypt 2> /dev/null
  autocmd BufWritePre *.gpg :%!gpg -ae --default-recipient-self
  autocmd BufWritePost *.gpg u
augroup END

{% endhighlight %}

Essentially, we disable auto-saving the `.viminfo` file, and then we disable
swap files, undo files and backup files. After the buffer is read, we decrypt
it with GPG, so that we are able to read the content in Vim.  Before we
eventually save our file, we encrypt the entire file with the user ID of the
default key as the recipient of our message, and finally after writing the file
we undo the last action, so that the file is still readable to us.
