type result = {
    url : string
  ; content : string
  ; timestamp : float
}

(* This function takes a list of urls and fetch their content, timestamping the results, logging the
   process of fetching *)
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

(* Analyze the results, focus on the content length without the actual content *)
let analyze_results results =
  results
  |> List.filter_map (fun result ->
         if String.length result.content > 100
         then Some (result.url, String.length result.content)
         else None)
  |> List.sort (fun (_, len1) (_, len2) -> compare len1 len2)

(* Configuration *)
let max_retries = 3
let user_agent = "OCaml Web Crawler/1.0"

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
  try_fetch max_retries

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
