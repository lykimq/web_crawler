type url = string

(* Define simple effects for logging and fetching URLs, logging and fetching are computations that
   can perform side effects. By using Effect this allows more flexible control over how and when
   these effects are handled. *)

type _ Effect.t += Fetch : url -> string Effect.t | Log : string -> unit Effect.t

let fetch url = Effect.perform (Fetch url)
let log msg = Effect.perform (Log msg)

(* Higher-order function to add logging to any function *)
let with_logging f =
  (* Execute the function f with an empty initial state *)
  Effect.Deep.try_with f ()
    ~handler:
      (* Define a handler for the effects *)
      {
        Effect.Deep.retc = (fun x -> x) (* Return the result unchanged *)
      ; exnc = raise
      ; effc =
          (fun (type a) (eff : a Effect.t) ->
            (* Match on the effect type *)
            match eff with
            | Log msg ->
              Some
                (fun (k : (a, _) Effect.Deep.continuation) ->
                  Printf.printf "[LOG] %s\n" msg ;
                  (* Continue with the original result *)
                  Effect.Deep.continue k ())
            | _ -> None)
      }

(* Configuration *)
let max_retries = 3
let user_agent = "OCaml Web Crawler/1.0"
let timeout_seconds = 10.0

(* Helper function to create HTTP headers *)
let create_headers () =
  let headers = Cohttp.Header.init () in
  Cohttp.Header.add headers "User-Agent" user_agent

(* Helper function to fetch URL with retries and timeout *)
let fetch_with_retry url =
  let open Lwt in
  let rec try_fetch attempts =
    if attempts <= 0
    then Lwt.fail_with (Printf.sprintf "Failed to fetch %s after %d attempts" url max_retries)
    else
      let headers = create_headers () in
      let uri = Uri.of_string url in
      (* Create a timeout promise *)
      let timeout_promise =
        Lwt_unix.sleep timeout_seconds >>= fun () ->
        Lwt.fail_with (Printf.sprintf "Timeout after %.1f seconds" timeout_seconds)
      in
      (* Create the actual request promise *)
      let request_promise =
        Cohttp_lwt_unix.Client.get ~headers uri >>= fun (resp, body) ->
        match resp.status with
        | `OK -> Cohttp_lwt.Body.to_string body
        | status ->
          Printf.printf "[WARN] %s returned %s (attempt %d/%d)\n%!" url
            (Cohttp.Code.string_of_status status)
            (max_retries - attempts + 1)
            max_retries ;
          if attempts > 1
          then Lwt_unix.sleep 1.0 >>= fun () -> try_fetch (attempts - 1)
          else Lwt.fail_with (Printf.sprintf "HTTP %s" (Cohttp.Code.string_of_status status))
      in
      (* Race between timeout and request *)
      Lwt.pick [timeout_promise; request_promise]
  in
  try_fetch max_retries

let handle_effects f =
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
                let content =
                  try Lwt_main.run (fetch_with_retry url) with
                  | e ->
                    Printf.printf "[ERROR] Failed to fetch %s: %s\n%!" url (Printexc.to_string e) ;
                    raise e
                in
                Effect.Deep.continue k content)
          | _ -> None)
    }
  in
  Effect.Deep.match_with f () handler
