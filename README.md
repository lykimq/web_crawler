# OCaml 5.x Morden Web Crawler
A modern web crawler implementation using OCaml 5's algebraic effects system for handling I/O operations and side effects in a pure functional way.

## Features

- Pure functional implementation using OCaml 5's effect system
- Separation of effects from business logic
- Robust error handling and logging
- Content analysis capabilities
- Testable architecture with mockable effects

## Prerequisites
- OCaml 5.1.0 or higher
- opam 2.x
- dune build system


## Usage

```bash
dune build
dune exec web_crawler
```

or

```bash
make setup
make build
make run
```
