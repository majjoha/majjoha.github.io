---
layout: post
title:  "Curry Your Procs"
date:   2014-11-04
---

Recently, I discovered that Ruby provides a rather esoteric `#curry` method for
`Proc`s that I'd like to examine in this post.

Currying basically means taking one function with multiple arguments and
converting it into a function that takes only one argument and returns another
function. The concept was originally coined by Moses Schönfinkel, and later
developed by Haskell Curry.

In Ruby, we might have a `Proc` taking multiple arguments:

{% highlight ruby %}
f = Proc.new { |a, b, c| a + b + c }
{% endhighlight %}

We can call `f` with all of its arguments by saying `f[1,2,3]` which would
evaluate to 6 in our case.

Currying `f` by hand would look like this:

{% highlight ruby %}
curried_f = Proc.new do |a|
  Proc.new do |b|
    Proc.new do |c|
      a + b + c
    end
  end
end
{% endhighlight %}

We can now evaluate our `Proc` by running `curried_f[1][2][3]` which would
evluate to 6 exactly as in our previous example.

The ingenious reader have probably already guessed that `#curry` will take our
original `f` and turn it into `curried_f`. We can curry `f` in the following way
instead: `curried_f = f.curry`, and then finally call `curried_f[1][2][3]` which
will unsurprisingly return 6 as before.
