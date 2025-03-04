# OCaml 5.x Effect System - Web Crawler

A web crawler implementation demonstrating the power of OCaml 5's algebraic effects system for handling side effects in a pure functional way. This project showcases two different approaches to handling side effects in OCaml: traditional monads (using Lwt) and the new effects system.

## Key Differences: Effects vs Monads

### 1. Effect Declaration and Handling

**Effects-based Approach:**
```ocaml
(* Define effects *)
type _ Effect.t +=
  | Fetch : url -> string Effect.t
  | Log : string -> unit Effect.t

(* Simple effect performance *)
let fetch url = Effect.perform (Fetch url)
let log msg = Effect.perform (Log msg)

(* Core logic remains clean and simple *)
let crawl_urls urls =
  List.filter_map
    (fun url ->
      try
        Effects.log (Printf.sprintf "Fetching %s" url) ;
        let content = Effects.fetch url in
        Some { url; content; timestamp = Unix.gettimeofday () }
      with
      | _ ->
        Effects.log (Printf.sprintf "Failed to fetch %s" url) ;
        None)
    urls
```

**Traditional Monadic Approach:**
```ocaml
(* Monadic operations are embedded in the type system *)
let fetch_url url =
  let open Lwt in
  Cohttp_lwt_unix.Client.get (Uri.of_string url) >>= fun (resp, body) ->
  Cohttp_lwt.Body.to_string body >>= fun content ->
  if resp.status = `OK then return (Some content) else return None

(* Core logic is mixed with monadic operations *)
let crawl_urls urls =
  let open Lwt in
  let fetch_and_log url =
    log_message (Printf.sprintf "Fetching %s" url) >>= fun () ->
    fetch_url url >>= fun content_opt ->
    match content_opt with
    | Some content ->
      let timestamp = Unix.gettimeofday () in
      return (Some { url; content; timestamp })
    | None ->
      log_message (Printf.sprintf "Failed to fetch %s" url) >>= fun () ->
      return None
  in
  Lwt_list.filter_map_p fetch_and_log urls
```

### 2. Key Advantages of Effects

1. **Separation of Concerns**
   - Effects: Core logic is clean and separated from effect handling
   - Monads: Effect handling is mixed with core logic, making it harder to read and maintain

2. **Composition and Testing**
   - Effects: Easy to compose different effects and mock them for testing
   - Monads: Monad transformers are needed for composition, making testing more complex

3. **Error Handling**
   - Effects: Natural error handling with try-catch blocks
   - Monads: Requires explicit error handling through the monad (e.g., `>>=` and `return`)

4. **Code Clarity**
   - Effects: More readable code with clear separation between computation and effects
   - Monads: Code can become complex with nested monadic operations

### 3. Implementation Details

The effects-based implementation uses OCaml 5's effect system to handle side effects through a handler:

```ocaml
let handle_effects f =
  let open Effects in
  let handler =
    {
      Effect.Deep.retc = (fun x -> x)
    ; exnc = (fun e -> raise e)
    ; effc =
        (fun (type a) (eff : a Effect.t) ->
          match eff with
          | Log msg ->
            Some
              (fun (k : (a, _) Effect.Deep.continuation) ->
                Printf.printf "[LOG] %s\n%!" msg ;
                Effect.Deep.continue k ())
          | Fetch url ->
            Some
              (fun (k : (a, _) Effect.Deep.continuation) ->
                let content = Lwt_main.run (fetch_with_retry url) in
                Effect.Deep.continue k content)
          | _ -> None)
    }
  in
  Effect.Deep.match_with f () handler
```

## Prerequisites

- OCaml 5.1.0 or higher
- OPAM 2.x
- Dune build system

## Usage

To build and run the web crawler:

```bash
# Using Dune
dune build
dune exec web_crawler

# Or using Make
make setup
make build
make run
```

## Project Structure

- `lib/effects.ml`: Core effects definitions and handlers
- `lib/crawler_effect.ml`: Effects-based crawler implementation
- `lib/traditional_crawler.ml`: Traditional monadic crawler implementation
- `bin/main.ml`: Main executable demonstrating both approaches
