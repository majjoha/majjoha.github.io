---
layout: post
title:  "Common Pitfalls in Ruby"
date:   2017-01-02
---

Last week, I stumbled upon a document covering a list of common pitfalls in Ruby
that I assembled in the beginning of 2015. Browsing through the various gotchas,
I decided to rework the list, and publish it here for future reference.
Hopefully, others will find it useful too.

## `and`, `or`, and `not`

Since Ruby is often considered a readable language, many novices tend to believe
that `and`, `or`, and `not` are more appealing alternatives to `&&`, `||`, and
`!`, respectively. They differ, however, in their behavior. Consider the
following example:

```ruby
foo = true and false
=> false
foo
=> true
foo = true && false
=> false
foo
=> false
foo = false || true
=> true
foo = false or true
=> true
foo
=> false
```

Similarly, this example below reveals the issue with `not` versus `!`.

```ruby
not true
=> false
!true
=> false
not 3 == 4
=> true
!3 == 4
=> false
```

In the first example, `foo = true and false` will be interpreted as `(foo =
true) and false` where `foo = true && false` will be interpreted as `foo = (true
&& false)`, as `and` and `or` have lower precedence than `&&` and `||`.  Thus,
`and` and `or` are meant for flow control, while `&&` and `||` are for boolean
logic.

Correspondingly, `not` and `!` also behave differently due to their precedence.
As expected, `not` has lower precedence than `!`.

As shown in the second example, `not 3 == 4` will be interpreted as `not (3 ==
4)` which evaluates to true, while `!3 == 4` will be interpreted as `(!3) == 4`,
i.e. `false == 4`.

## `equal?`, `eql?`, `===`, and `==`

These four methods of determining equality all behave widely different. The
first method, `equal?`, is an identity comparison, so it will only return true
in situations where `a` is the same object as `b`. One can think of `equal?` as
a pointer comparison.

```ruby
1.equal?(1)
=> true
"a".equal?("a")
=> false
```

It is worth nothing that if we enable immutable strings in the example above
with `# frozen_string_literal: true`, or the `--enable-frozen-string-literal `
flag, the last example will also evaluate to true.

`eql?` is essentially for hash comparisons. It returns true when `a`, and `b`
refer to the same hash key. `Hash` uses this to test for equality. It is common
to alias `eql?` to `==`.

Finally, `===`, and `==` are for case equality, and generic equality,
respectively. `===` is typically overridden to provide meaningful semantics in
`case` statements for `Range`, `Regex`, and `Proc`. `==` is the most common
comparison operator, and therefore this is usually overridden to provide
class-specific meaning.

## `to_s`, `to_str`, and `String`

`to_s`, and `String` are more or less equivalent. `String` will check the class
of its parameter, and if it is not already a string, it will call `to_s` on it.
Calling `to_s` obviously means it will be called regardless.

`to_str` is different from the two, however. It should only be implemented in
situations where your object acts like a string as opposed to being
representable by a string meaning you should only implement `to_str` in your
classes for objects that are interchangeable with `String` objects.

## `any?`

The `Enumerable` module in Ruby defines an `any?` method. When I initially
learned Ruby, I expected that it would return true if the collection was
non-empty (as a negated `empty?`). Nevertheless, `any?` (without a provided
block) returns true if at least one of the collection members is not `false` or
`nil`. The following example demonstrates this behavior:

```ruby
[false, nil].any?
=> false
[true, false].any?
=> true
[:truthy, nil].any?
=> true
```

## `super`, and `super()`

In Ruby, we learn that we can omit parentheses in method calls without any
arguments, as `foo`, and `foo()` returns the same result, and abandoning
unnecessary parentheses is normally what most style guides advocate for.

Consequently, it might be rather tempting to leave out parentheses when calling
`super()` but calling `super`, and `super()` is not entirely the same in Ruby.
`super` (without parentheses) will call the parent method with exactly the same
arguments that were passed to the original method, while the latter will call
the parent method without any arguments at all.

## `size`, `count`, and `length`

Similar to other methods in this blog post, people may be tempted to think
that `size`, `count`, and `length` are simply aliases for the same operation
but this is yet another quirk of Ruby.

`length`, and `size` are identical, and they usually run in constant time, so
they are faster than `count`. Unlike `count`, they are not a part of
`Enumerable` but rather a part of a concrete class (such as `Array`, or
`String`). Normally, I tend to use `length` for strings, and `size` for
collections.

As mentioned, `count` is a part of `Enumerable`, and it is usually meant to be
used with a block, although this is not mandatory.

```ruby
[1, 2, 3, 4, 5, 6].count(&:even?)
=> 3
[1, 2, 3, 4, 5, 6].count
=> 6
```

## `Hash.new([])` vs. `Hash.new {|h, k| h[k] = [] }`

`Hash.new([])`, and `Hash.new {|h,k| h[k] = [] }` may look similar but they
behave slightly different. When accessing an unknown element, `Hash.new([])`
will always return the same array where `Hash.new {|h, k| h[k] = [] }` creates a
new array. A quick benchmark reveals that accessing an unknown element from a
hash initialized with `Hash.new([])` is approximately twice as fast as
accessing an unknown element from a hash initialized with `Hash.new {|h,k| h[k]
= [] }`

This behavior can also be seen in arrays where `Array.new(42) { Foo.new }` will
initialize a new `Foo` every time, while `Array.new(42, Foo.new)` will refer to
the same `Foo` object for each element.

## The flip-flop operator (`..`)

In Ruby, `..`, and `...` are most often used for ranges. It allows us to
succinctly express ranges from A to Z as such `'a'..'z'`. The `..` operator
always includes the last element where `...` will skip the last element in the
range.

```ruby
('a'..'z').to_a.size
=> 26
('a'...'z').to_a.size
=> 25
```

We can also conveniently express a date range as such:

```ruby
require 'date'
=> true
now = DateTime.now
=> #<DateTime: 2016-12-15T22:36:38+01:00 ((2457738j,77798s,446146000n), +3600s, 2299161j)>
last_month = now - 30
=> #<DateTime: 2016-11-15T22:36:38+01:00 ((2457708j,77798s,446146000n),+3600s,2299161j)>
(last_month..now).to_a.size
=> 31
```

The `..` operator can, however, lead to a bit of confusion since it has a different
behavior in other situations.

```ruby
(1..20).each do |x|
  puts x if (x == 5) .. (x == 10)
end
```

The condition in the loop above evaluates to false every time it is evaluated
until the first part, i.e. `x == 5`, evaluates to true. Then it evaluates to
true until the second part evaluates to true. In the above example, the
flip-flop is turned on when `x == 5` and stays on until `x == 10`, so the
numbers from 5 to 10 are printed.

The flip-flop operator only works inside `if`s and ternary conditions.
Everywhere else, Ruby considers it to be the range operator. With the flip-flop
operator, we now conclude our whirlwind tour of the various pitfalls in the Ruby
programming language.

As demonstrated in this blog post, Ruby has quite a few quirks. In order to
avoid many of these pitfalls, I usually advocate for using
[Rubocop](https://github.com/bbatsov/rubocop) either locally on your own
machine, or ideally as a part of the CI pipeline. While it may not detect all
the issues at hand, it is at most times extremely good at reporting problems in
your code.
