---
layout: post
title:  "Ruby extensions in C"
date:   2015-02-07 
---

Occasionally, we come across particular sections in our programs that need to be
exceptionally fast. Ruby allows us to write extensions in C, so that we can
delegate the heavy lifting. In this post, I'll show you how easy it is to extend
Ruby with C by writing a trivial factorial function in C which we'll be able to
call from Ruby.

We start out by creating the relevant directories and files.

<pre class="prettyprint">
$ mkdir fact
$ cd fact
$ mkdir ext
$ touch ext/extconf.rb ext/fact.c
</pre>

In the `ext/extconf.rb` file, we require the
[`mkmf`](http://ruby-doc.org/stdlib-2.0.0/libdoc/mkmf/rdoc/MakeMakefile.html)
module which allows us to generate an applicable Makefile that compiles our C
code.

<pre class="prettyprint">
require "mkmf"

create_makefile("fact")
</pre>

Afterwards, we write the actual C program in the `ext/fact.c` file. It should
look like this:

<pre class="prettyprint">
#include "ruby.h"

void Init_fact();
VALUE fact(VALUE self, VALUE n);

void Init_fact()
{
  VALUE Fact = rb_define_module("Fact");
  rb_define_method(Fact, "fact", fact, 1);
}

VALUE fact(VALUE self, VALUE n)
{
  int x = NUM2INT(n);
  int factorial = 1;

  for (int i = 1; i <= x; i++) {
    factorial *= i;
  }

  return INT2NUM(factorial);
}
</pre>

First, we include the `ruby.h` header file, so that we can access the necessary
macros and functions. Ruby will by default execute our initializing function
`Init_fact`, so we define our `Fact` module in here with the function
`rb_define_module`. Additionally, we define a method `fact` in the `Fact`
module with the `rb_define_method` function. It takes a class, a method name, a
function and the number of arguments.

In the function `VALUE fact(VALUE self, VALUE n)`, we pass both `VALUE self` and
the number we want to take the factorial of. We convert the `VALUE n` to an
`int` with the `NUM2INT` macro, and convert the integer back to `Fixnum` when
returning the result.

We can then compile our program, and open `irb` to verify that it works as
expected:

<pre class="prettyprint">
$ ruby ext/extconf.rb
creating Makefile
$ make
compiling ext/fact.c
linking shared-object fact.bundle
$ irb
irb(main):001:0> require_relative "fact"
=> true
irb(main):002:0> include Fact
=> Object
irb(main):003:0> fact(5)
=> 120
</pre>

Utilizing C in our Ruby programs can be incredibly useful both in order to
achieve higher performance for specific parts of our application, but also if we
want interfacing with other C code. If you want to go further, I highly
recommend that you take a look at the
[README.EXT](http://docs.ruby-lang.org/en/2.2.0/README_EXT.html) documentation. 
