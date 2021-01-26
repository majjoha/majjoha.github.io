---
layout: post
title: "Buidling a Passphrase Generator in Haskell"
date: 2021-01-26 
---

During the recent holiday season, I decided to put my admittedly limited Haskell
skills to use. While the [CIS 194](https://www.seas.upenn.edu/~cis194/spring13/)
course exercises are excellent for learning and practicing Haskell, and I enjoy
working through them when time permits, I wanted to work on a more structured
"real world" project this time.

I had a few goals in mind for this particular project. First and foremost, it
had to be a well-defined and relatively simple problem that I needed to solve.
Secondly, I wanted it to require me to handle IO and side effects, and, lastly,
I wanted it to offer me an opportunity to integrate third-party libraries in my
app.

Only a couple of weeks prior to starting this project, I had been reading the
[guide](https://www.eff.org/dice) by the [Electronic Frontier
Foundation](https://www.eff.org) on how to generate strong six-word
[Diceware](https://en.m.wikipedia.org/wiki/Diceware) passphrases. Turning their
suggested method into a small command-line utility seemed to suit my three goals
nicely, so I decided to give it the old college try. In this blog post, I will
elaborate on how this method of generating passphrases works and how it can be
implemented in Haskell. The entire project can be found on GitHub
[here](https://github.com/majjoha/passphrase).

The steps needed to generate a passphrase using the directions provided by EFF
are fairly simple, and you only need five dice and a
[wordlist](https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt):

1. Roll five dice at the same time and write down the five numbers. The numbers
   might be something like 4, 3, 4, 6, 3.
2. In your wordlist, find the word that matches the number 43463 (in this case,
   panoramic), and write it down.
3. Repeat these two steps until you have (at least) six words. Once you have
   repeated the steps, you might have a passphrase such as "whinny daffodil
   aerobics upheld bankable niece."

Before detailing the implementation, it should be noted that the project uses
[`rio`](https://github.com/commercialhaskell/rio) as a prelude replacement by
setting `{-# LANGUAGE NoImplicitPrelude #-}` and importing `RIO` in all files.
With our project description in place, we are now ready to implement it.

In order to solve the first step, we need to be able to roll five dice and join
the numbers into a single digit. To do so, we define a `rollDice` function:

```haskell
rollDice :: Int -> Integer -> Integer -> IO [Integer]
rollDice rolls start end = replicateM rolls $ generateBetween start end
```

`rollDice` takes three arguments: `rolls` which describes how many dice we want
to roll, and `start` and `end` which respectively describe the start and end of
the range of numbers, we will be working with. Here, we rely on
[`generateBetween`](https://hackage.haskell.org/package/cryptonite-0.27/docs/Crypto-Number-Generate.html#v:generateBetween)
from the [Cryptonite](https://hackage.haskell.org/package/cryptonite) library to
generate a random number within our range. Since our result is wrapped in a
monad, we need to use
[`replicateM`](https://hackage.haskell.org/package/base-4.14.1.0/docs/Control-Monad.html#v:replicateM)
to repeat this process N times.

Next, we need to be able to join these digits into one. To do this, we will
define a function `joinDigits` in the following manner:

```haskell
joinDigits :: [Integer] -> Integer
joinDigits = L.foldl' ((+) . (* 10)) 0
```

This function takes a list of `Integer`s and uses
[`L.foldl'`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-List.html#v:foldl-39-)
to combine them into one. 

For every element in the list, we multiply our accumulator with 10 and then add
the first element in our list to the result. This process is repeated until our
list is empty. For instance, given the numbers 5, 2, 3, 1, 6, and 0 as our
initial accumulator value, this is how our result is calculated:

```
0                  # Initial accumulator value
0*10+5    = 5      # The list is now [2, 3, 1, 6]
5*10+2    = 52     # The list is now [3, 1, 6]
52*10+3   = 523    # The list is now [1, 6]
523*10+1  = 5231   # The list is now [6]
5231*10+6 = 52316  # The list is now []
```

With these two functions defined, we now have the necessary parts for generating
the indices which we will need later when pairing dice rolls with words. To pair
indices with words, we will need a function `toTuple`:

```haskell
toTuple :: [String] -> (Integer, String)
toTuple [] = (0, "")
toTuple (index:word) = (fromMaybe 0 index', fromMaybe "" word')
  where
    index' = readMaybe index :: Maybe Integer
    word' = L.headMaybe word
```

`toTuple` takes a list of `String`s and returns a tuple of `(Integer, String)`
where the `Integer` represents an index, and the `String` represents the
corresponding word from the wordlist. We will call this function later when we
map over each line in our wordlist.

Since a line in our wordlist follows the format "`11111 abacus`", we want to
read the first string as an `Integer` and take the first word of the remaining
words in our line. As
[`read`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Partial.html#v:read)
and
[`head`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-List-Partial.html#v:head)
can throw exceptions, we use the safe alternatives
[`readMaybe`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Prelude.html#v:readMaybe)
and
[`L.headMaybe`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-List.html#v:headMaybe)
instead. To unwrap our
[`Maybe`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Prelude-Types.html#t:Maybe)
values, we call
[`fromMaybe`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Prelude.html#v:fromMaybe)
and use `0` and `""` as the default values for the index and word, respectively.
Lastly, to avoid non-exhaustive patterns, we pattern match on the empty list and
return `(0, "")` for good measure.

Now we can finally move on to writing the logic for generating passphrases which
is handled by the `passphrase` function:

```haskell
passphrase :: String -> [[Integer]] -> String
passphrase wordlist dice =
  unwords $ map (flip (Map.findWithDefault "") wordMap) indices
    where
      indices = map joinDigits dice
      wordMap = Map.fromList $ map (toTuple . words) $ lines wordlist
```

To generate a passphrase, we need to pass our wordlist as the first argument and
then a list containing a list of our dice rolls as the second argument. The
first argument will look like this:

```
11111 abacus
11112 abdomen
11113 abdominal
11114 abide
11115 abiding
11116 ability
11121 ablaze
11122 able
11123 abnormal
11124 abrasion
11125 abrasive
11126 abreast
11131 abridge
...
```

While the second argument, i.e., our dice rolls, might look like this:

```haskell
[ [5, 3, 2, 1, 6]
, [3, 4, 1, 6, 6]
, [2, 4, 4, 1, 3]
, [1, 3, 3, 5, 4]
, [2, 3, 2, 1, 5]
, [6, 4, 3, 2, 5]
]
```

For all the lists in our list of dice rolls, we use our previously defined
`joinDigits` function to join the numbers in the list into single digits. We
then store these digits, or indices, in the `indices` variable, so we can use
them later when we need to look up words in our wordlist.

As shown above, the wordlist follows the format `INDEX WORD`, so we split our
wordlist on line breaks using 
[`lines`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Prelude.html#v:lines)
which gives us a list of `String`s containing elements such as `"11111 abacus"`
and `"11112 abdomen"`. We want to further break these elements down so we will
end up with a list of tuples. To do so, we map over all the lines in our
wordlist and call `(toTuple . words)` on them. Now that we have a list of
tuples, we can convert it to a
[`Map`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Map.html#t:Map)
using
[`Map.fromList`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Map.html#v:fromList)
so we can perform efficient lookups later.

For all our indices, we want to find the corresponding word in our wordlist
which we do with `map (flip (Map.findWithDefault "") wordMap) indices`. Since
[`Map.findWithDefault`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Map.html#v:findWithDefault)
expects the index of the map to be the second argument and the map to be the
last, we use two useful techniques here to make our code less convoluted. First,
we leverage currying by applying `""` as the first argument to
[`Map.findWithDefault`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Map.html#v:findWithDefault),
and then we use
[`flip`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Prelude.html#v:flip)
to reverse the order of the last two arguments.

By flipping the order, we can now do a simple map over our `indices` variable
and perform a lookup in our `wordMap` in a slightly more elegant fashion. Once
we have all our words, we can join them into a single `String` using
[`unwords`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-List.html#v:unwords).

With the fundamental logic now defined, we only need to read our wordlist from a
file, throw five dice six times, and pass these two values to our `passphrase`
function. We do so by defining the entry point of our app in
[`Main.hs`](https://github.com/majjoha/passphrase/blob/main/app/Main.hs) as
such:

```haskell
main :: IO ()
main = do
  wordlist <- T.unpack <$> readFileUtf8 "data/eff-large-wordlist.txt"
  dice <- replicateM 6 $ rollDice 5 1 6
  runSimpleApp $ do
    logInfo . display . T.pack $ passphrase wordlist dice
```

This largely resembles the steps listed earlier. To retrieve our wordlist, we
call
[`readFileUtf8`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO.html#v:readFileUtf8)
with the path to our wordlist, and then
[`T.unpack`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Text.html#v:unpack)
to convert the
[`Text`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Text.html#t:Text)
value into a `String`.

Next, we roll our five dice six times by calling `replicateM 6 $ rollDice 5 1
6`, and pass our `wordlist` and `dice` to the `passphrase` function.

After calling our `passphrase` function, we now have a passphrase that we need
to output in our terminal. Following the conventional structure for how to build
apps using [`rio`](https://github.com/commercialhaskell/rio), we run our app as
a
[`SimpleApp`](https://hackage.haskell.org/package/rio-0.1.15.0/docs/RIO-Prelude-Simple.html#t:SimpleApp)
which provides a convenient default configuration. We convert the result from
our `passphrase` function into a
[`Text`](https://hackage.haskell.org/package/rio-0.1.19.0/docs/RIO-Text.html#t:Text)
value, then a
[`Utf8Builder`](https://hackage.haskell.org/package/rio-0.1.15.0/docs/RIO.html#t:Utf8Builder),
and, lastly, print it in our terminal with
[`logInfo`](https://hackage.haskell.org/package/rio-0.1.15.0/docs/RIO.html#v:logInfo).

With everything in place, we have now reached our goal and can finally build our
project by running `stack build` and generate a passphrase:

```
% stack exec -- passphrase
polar geek nimble okay appealing trim
```

In my experience, the Haskell community is great at sharing their knowledge on
both Twitter and in various blog posts. With this blog post, I hope to
contribute back to the community and help especially the people newer to the
language who might want to move beyond contrived exercises and learn how to
build smaller apps. If you are interested, you can find the project on GitHub
[here](https://github.com/majjoha/passphrase), and if you have any feedback, I
am all ears.
