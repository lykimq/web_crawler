# OCaml 5.x Effect System - Web Crawler

This is a simple web crawler implementation using OCaml 5's algebraic effects system to handle I/O operations and side effects in a pure functional way.

## Effect System vs Traditional Implementation (Monads)

- **Flexibility with Effects**: In the effect-based implementation, the handling of side effects (like logging and fetching) is abstracted away from the core logic. This allows for easy modifications and testing. In the traditional implementation, logging and fetching might be directly embedded in the core logic, making it harder to change or test.

- **Separation of Concerns**: The effect-based implementation clearly separates the concerns of fetching and logging from the core logic of crawling URLs. In the traditional implementation, the core logic is mixed with the side effects, leading to less maintainable code. In the example below, the `crawl_urls` function does not need to know how logging and fetching are implemented. It simply calls `Effects.log` and `Effects.fetch`, making it easier to read and maintain.

### Benefits of Using the Effect System

1. **Improved Testability**: Since side effects are handled separately, it becomes easier to write unit tests for the core logic without worrying about the side effects. This leads to more reliable and maintainable tests.

2. **Enhanced Modularity**: The effect system promotes modular design by allowing developers to define and manage side effects independently. This modularity makes it easier to reuse components across different projects.

3. **Easier Refactoring**: With side effects abstracted away, refactoring the core logic becomes less risky. Developers can change the implementation of side effects without affecting the main logic of the application.

4. **Clearer Code**: The separation of concerns leads to clearer and more understandable code. Developers can focus on the core logic without being distracted by the details of side effect management.

5. **Dynamic Effect Handling**: The effect system allows for dynamic handling of effects, enabling more complex behaviors such as effect composition and cancellation, which are difficult to achieve with traditional monadic approaches.

### Example: Fetching URLs

**Effect-based implementation:**

```ocaml
let crawl_urls urls =
  List.filter_map
    (fun url ->
      try
        Effects.log (Printf.sprintf "Fetching %s" url) ;
        (* Side effect handled separately *)
        let content = Effects.fetch url in
        Some { url; content; timestamp = Unix.gettimeofday () }
      with
      | _ ->
        (* Side effect handled separately *)
        Effects.log (Printf.sprintf "Failed to fetch %s" url) ;
        None)
    urls
```

**Traditional implementation (Monad):**

```ocaml
let crawl_urls urls =
  List.filter_map (fun url ->
    try
      (* Direct Logging *)
      Printf.printf "Fetching %s\n" url;
      (* Direct I/O operations *)
      let content = fetch url in
      Some { url; content; timestamp = Unix.gettimeofday () }
    with
    | _ ->
      (* Direct logging *)
      Printf.printf "Failed to fetch %s\n" url;
      None)
  urls
```

## Prerequisites

- OCaml 5.1.0 or higher
- OPAM 2.x
- Dune build system

## Usage

To build and run the web crawler, you can use either of the following methods:

Using Dune:

```bash
dune build
dune exec web_crawler
```

Or using Make:

```bash
make setup
make build
make run
```
