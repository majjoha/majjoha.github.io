---
layout: post
title: "Type-Level Programming in TypeScript"
date: 2021-03-29
---

The [TypeScript](https://www.typescriptlang.org/) type system is immensely
powerful, and while the language itself is, of course, Turing complete, [so is
the type system itself](https://github.com/Microsoft/TypeScript/issues/14833).
This allows us to implement types that are far more sophisticated than what is
possible in most popular programming languages, as we can do computations on a
type-level which is, essentially, what characterizes type-level programming.

In the following, I will demonstrate how we can utilize features of the
TypeScript type system such as [conditional
types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html),
[indexed array
types](https://www.typescriptlang.org/docs/handbook/2/indexed-access-types.html),
and more to implement a type that computes a given [Fibonacci
number](https://en.wikipedia.org/wiki/Fibonacci_number).

It should be pointed out that while it is possible to implement this, you should
consider it merely an academic exercise and not a recommendation for how to use
the type system in your production applications.

Before we can implement anything, we need to have a notion of what a number is.
In type-level programming, this is most commonly modeled using [Peano
numbers](https://en.wikipedia.org/wiki/Peano_axioms). We can define our Peano
numbers in the following manner:

```typescript
type Zero = "zero"

type Succ<N> = { n: N }
```

First, we define the number 0 with our type `Zero`. Here, it is a type alias for
the string `"zero"`, but it could be anything. Next, we define `Succ` which is a
parameterized type (or [generic
type](https://www.typescriptlang.org/docs/handbook/2/generics.html)) that we
will use for any number above 0. With these two types, we can now define 1 as
`Succ<Zero>`, 2 as `Succ<Succ<Zero>>`, and so forth.

For convenience, we will create the following types for the numbers 1 through 10
which we will use later:

```typescript
type One = Succ<Zero>
type Two = Succ<One>
type Three = Succ<Two>
type Four = Succ<Three>
type Five = Succ<Four>
type Six = Succ<Five>
type Seven = Succ<Six>
type Eight = Succ<Seven>
type Nine = Succ<Eight>
type Ten = Succ<Nine>
```

Correspondingly, we will define variables that match our types above. We will
use the variables later when we are going to test that our `Fibonacci` type
works.

```typescript
const zero: Zero = "zero"
const one: One = { n: zero }
const two: Two = { n: { ...one } }
const three: Three = { n: { ...two } }
const four: Four = { n: { ...three } }
const five: Five = { n: { ...four } }
// ...
const thirteen: Succ<Succ<Succ<Ten>>> = { n: { ...twelve } }
```

We now have a notion of what a number is which allows us to move on to the next
part of our implementation.

To implement our `Fibonacci` type, we need a few essential building blocks. We
will start by defining the simplest types first.

For addition to work, we need to be able to *decrement* numbers. It will shortly
become clearer why decrementing a number is important when we want to sum two
numbers. We can define a `Decrement` type in this way:

```typescript
type Decrement<N> = N extends Succ<infer R> ? R : Zero
```

TypeScript supports [inferring within conditional
types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html#inferring-within-conditional-types)
which means that we can extract types from parameterized types. If `N` extends
`Succ`, we extract the type `R` and return it, and, otherwise, we return `Zero`.
`Decrement<Succ<Succ<Zero>>>` would thus be equivalent to `Succ<Zero>`.

Similarly, to check if a type is `Zero`, we will need a type `IsZero` that
we define as such:

```typescript
type IsZero<N> = N extends Zero ? true : false
```

With this type, `const typeChecks: IsZero<Zero> = true` would type check while
`const doesNotTypeCheck: IsZero<Succ<Zero>> = true` would not.

Next, we need to have a way to do `if/else` expressions so we can return types
based on a given condition:

```typescript
type IfElse<C extends boolean, T, F> = C extends true ? T : F
```

Here, `C` can be either `true` or `false`, and if it is true, we return the type
`T`, and, otherwise, the type `F`. So a variable with the type `IfElse<true,
"foo", "bar">` would only type check if it was assigned to the value `"foo"`.

Three types are missing at this point: `Equals`, `Add`, and the `Fibonacci`
type. We define `Equals` this way:

```typescript
type Equals<A, B> =
  A extends Succ<infer SA>
  ? B extends Succ<infer SB>
    ? Equals<SA, SB>
    : false
  : A extends Zero
    ? B extends Zero
      ? true
      : false
    : false
```

Checking for equality on a type-level in TypeScript is difficult to do
elegantly, so the type definition above may be less clear than the types defined
earlier in the blog post.

With this definition, two types are only equal if they are both `Zero`. If `A`
and `B` extends `Succ`, then we recursively use our `Equals` type with the
extracted types `SA` and `SB` until both of the extracted types are `Zero`, or
one of them does not extend `Succ` meaning that the two types are not equal.

Lastly, we need the `Add` type to make computing Fibonacci numbers possible. The
definition for this type is:

```typescript
type Add<A, B> = {
  acc: B
  n: A extends Succ<infer _> ? Add<Decrement<A>, Succ<B>> : never
}[IfElse<IsZero<A>, "acc", "n">]
```

`Add` works by recursively decrementing the first number, `A`, and incrementing
the second number, `B`, until the `A` is `Zero`. So to add 2 and 3, the steps
would be:

```
Step 1. Add<Succ<Succ<Zero>>, Succ<Succ<Succ<Zero>>>> // 2 + 3
Step 2. Add<Succ<Zero>, Succ<Succ<Succ<Succ<Zero>>>>> // 1 + 4
Step 3. Add<Zero, Succ<Succ<Succ<Succ<Succ<Zero>>>>>> // 0 + 5
```

Once we reach `Zero`, we return the type `B` by indexing the property `"acc"`
which is our result. In this case, `Succ<Succ<Succ<Succ<Succ<Zero>>>>>` or
simply 5.

All that is left now is to implement the `Fibonacci` type which is defined as
follows:

```typescript
type Fibonacci<N, F0 = Zero, F1 = One> = {
  acc: F0
  n: N extends Succ<infer _> ? Fibonacci<Decrement<N>, F1, Add<F0, F1>> : never
}[IfElse<Equals<Zero, N>, "acc", "n">]
```

In our type parameter list, we first have `N` which represents the nth number in
the Fibonacci sequence we want to find. This type parameter is then followed by
`F0` and `F1` which have the default types `Zero` and `One`, respectively. We
use these two types to match the formal definition of the Fibonacci sequence
which states that the first two numbers in the sequence should be 0 and 1.

The `Fibonacci` type is similar to the `Add` type in that it returns the result
stored in our accumulator `"acc"` once a type is `Zero` (in this case, `N`).
Until we reach our base case, we keep recursing by indexing the property `"n"`.
For every step, we decrement `N`, replace `F0` with `F1`, and calculate a new
type for `F1` by adding `F0` and `F1` together. Eventually, `N` will become
`Zero`, and we have calculated our nth Fibonacci number.

Now we can finally put our newly defined `Fibonacci` type to use and check that
it works:

```typescript
const fib0: Fibonacci<Zero> = zero
const fib1: Fibonacci<One> = one
const fib2: Fibonacci<Two> = one
const fib3: Fibonacci<Three> = two
const fib4: Fibonacci<Four> = three
const fib5: Fibonacci<Five> = five
const fib6: Fibonacci<Six> = eight
const fib7: Fibonacci<Seven> = thirteen
```

If you are testing this out yourself, you will see that the code only type
checks if the value assigned to the variable matches to corresponding Fibonacci
number. So if we change the value of `fib4` to, say, `eight`, our code will no
longer type check.

Two things are worth pointing out here, though: a) TypeScript gives us an
error stating that the "type instantiation is excessively deep and possibly
infinite" once we try to compute any Fibonacci number larger than eight, and, b)
any number from `Fibonacci<Five>` and above will type check as long it is above
five. Admittedly, it is unclear to me whether this is a limitation of the
TypeScript type checker or an issue with my implementation, but it clearly shows
that while it is possible to implement this, issues will likely occur sooner or
later.

I hope you have found this blog post insightful. If you are curious and want to
play around with the `Fibonacci` type, you can find the code in a TypeScript
playground [here](https://www.typescriptlang.org/play?#code/C4TwDgpgBAWhBOB7KBeKAiAXgx6BQeokUAygK4DGFAPAHIB8qUA3lAHYBcUtUAvgUWgB5NtDTkq1OEnqFw0ACoB3ZOMo0REWYKgKAFvAhjS66ssTb5UAGKIy8JhJr7DWucWsBLAG7Gn1W3tLYhJPAA9HUy9fYOgSCF82SMlQsNioAFFPAHM9YGSaeMT02k9RAuos3OB0hQgktUlS0Vk8CkQ2AGd87CQuaVUMXtw2ju6oDoguTSZWTihhvlGu-OAVLnNZ9i5WADp9yb4l9pWoYAMjDYvjOZ2ofd215F5jsfyAMzt4LkCHNFuWPd9udXEd+Cdxu8fFMbNCtvM9vtPvYwctxp1wlxUvC7g8ob5URD8p0EvUsaSGoCEUDdhiIi9wW8oBAcnkuFU8jjAQ8SYlCUy2GUYc0bttufsWdV+adgGTdPUuYjdoLygy0fkIAAbClY0x1NiMf5ipWypJqolnJRa3y6lJ6+r0Q1U3ES7V881M86eeCyuX+f32g2OxU0tbW6Bq9zQAAiEAohgAtvVgHQnTwIGFTQATTomSRld4IKAAJUYAH4S1B+jgBFYAJKdAappjpzP1HOwHBQCvAeBkaBcd4AQ01JNrxDr7wyo4g1AAwsy22wOwAjRCIbVDtgAGl0u+sToXGezud7-e7uirNnH0AyAEcyCPOtQAIK7gBChrwUCgL8XJ7zGgCyLEgX1kH8K3ff921zfxgIcEhP2-H8L3vR9R2oUDd0Q8CUMHJ8IGQrg-2PGDOyQZCIKgKDSOXXMBkolCez7QiULwqBhxnRj8K4qNfyzLNXw-J1mGQocqC4d9kPmEilw7OC2ELBwAH1y34wTY3jCAkzYFMwOw0xP0YLhRF8eA8F4ABtSdpxJagGybfSMHEih0F3dA2HQegAF0b1hNc2Bczw6H3AAGJgBn3ABGJhNBEsSJJsULpK4VsAIUpSoFUi8vACoLqE0xNk1TaLdxfASAlC6LgxM0lzKsmyZ0qB8nykHBdwYdyXLcjBPJ8ggLShFdQp+Tw8qoYKBidYZ1Q4saotG8aKGCuKmEmWahoAJkWjp8vMJ11sGsaAGYdsCiazGuJ0ng2saABYzvy35ruuW6VwAVkei7oi0Jh8UIo6VwANi+5bMPCJ1JTyN6AHZQeCooHSYL0fSMNggA)
and a repository with more examples [here](https://github.com/majjoha/typology).
