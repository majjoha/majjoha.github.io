---
layout: project
title: "Sloth"
image: "/images/sloth.png"
year: 2015
tag: "Miscellaneous"
inactive: true
---

Sloth is an implementation of an extended lambda calculus with lazy evaluation.
It consists of a compiler which transforms a shared source language into two
distinct intermediate representations, and two stack machines that evaluate
these intermediate languages by exercising disparate strategies for lazy
evaluation.
The compiler was written in [OCaml](https://ocaml.org), and the stack machines
were both written in
[C](https://en.wikipedia.org/wiki/C_(programming_language)).

The project was developed as a collaborative effort as a part of my bachelor's
thesis which can be found
[here](https://www.dropbox.com/s/g138w9klyneuajy/Mads-Mathias-Bachelor-Thesis.pdf?dl=0).

[Browse repository on GitHub](https://github.com/majjoha/sloth).
