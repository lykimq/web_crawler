open Web_crawler.Effects
open Web_crawler.Crawler
open Cohttp_lwt_unix
open Lwt.Infix

let handle_effects f =
  let handler =
    {
      Effect.Deep.retc = (fun x -> x)
    ; exnc = (fun e -> raise e)
    ; effc =
        (fun (type c) (eff : c Effect.t) ->
          match eff with
          | Log msg ->
            Some
              (fun (k : (c, _) Effect.Deep.continuation) ->
                Printf.printf "[LOG] %s\n%!" msg ;
                Effect.Deep.continue k ())
          | Fetch url ->
            Some
              (fun k ->
                try
                  let headers = Cohttp.Header.init_with "User-Agent" "OCaml Web Crawler/1.0" in
                  let resp_body =
                    Client.get ~headers (Uri.of_string url) >>= fun (resp, body) ->
                    match Cohttp.Response.status resp with
                    | `OK ->
                      Cohttp_lwt.Body.to_string body >>= fun content -> Lwt.return (Some content)
                    | status ->
                      Printf.printf "[ERROR] %s returned %s\n%!" url
                        (Cohttp.Code.string_of_status status) ;
                      Lwt.return None
                  in
                  match Lwt_main.run resp_body with
                  | Some content -> Effect.Deep.continue k content
                  | None -> raise (Failure "HTTP request failed")
                with
                | e ->
                  Printf.printf "[ERROR] Failed to fetch %s: %s\n%!" url (Printexc.to_string e) ;
                  raise e)
          | _ -> None)
    }
  in
  Effect.Deep.match_with f () handler

let () =
  let urls = ["https://ocaml.org"; "https://discuss.ocaml.org"; "https://opam.ocaml.org"] in

  let results = handle_effects (fun () -> crawl_urls urls) in

  Printf.printf "\nCrawling Results:\n" ;
  List.iter
    (fun result ->
      Printf.printf "%s: %d bytes (fetched at %f)\n" result.url (String.length result.content)
        result.timestamp)
    results ;

  let analyzed = analyze_results results in
  Printf.printf "\nAnalysis Results:\n" ;
  List.iter (fun (url, len) -> Printf.printf "%s: %d bytes\n" url len) analyzed
