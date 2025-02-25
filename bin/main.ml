open Web_crawler.Effects
open Web_crawler.Crawler
open Cohttp_lwt_unix
open Lwt.Infix

(* Higher-order function to handle effects, logging and fetching URLs *)
let handle_effects f =
  (* Define a handler for the effects *)
  let handler =
    {
      Effect.Deep.retc = (fun x -> x) (* Return the result unchanged *)
    ; exnc = (fun e -> raise e) (* Raise the exception *)
    ; effc =
        (fun (type c) (eff : c Effect.t) ->
          (* Match on the effect type *)
          match eff with
          | Log msg ->
            (* Some function that takes a continuation and returns a unit *)
            Some
              (fun (k : (c, _) Effect.Deep.continuation) ->
                Printf.printf "[LOG] %s\n%!" msg ;
                Effect.Deep.continue k ())
          | Fetch url ->
            Some
              (fun k ->
                try
                  (* Fetch the URL *)
                  let headers = Cohttp.Header.init_with "User-Agent" "OCaml Web Crawler/1.0" in
                  (* Get the response and body *)
                  let resp_body =
                    Client.get ~headers (Uri.of_string url) >>= fun (resp, body) ->
                    (* Check if the response is OK *)
                    match Cohttp.Response.status resp with
                    | `OK ->
                      (* Convert the body to a string *)
                      Cohttp_lwt.Body.to_string body >>= fun content -> Lwt.return (Some content)
                    | status ->
                      (* Log the error *)
                      Printf.printf "[ERROR] %s returned %s\n%!" url
                        (Cohttp.Code.string_of_status status) ;
                      Lwt.return None
                  in
                  (* Run the response body *)
                  match Lwt_main.run resp_body with
                  | Some content ->
                    (* Continue with the content *)
                    Effect.Deep.continue k content
                  | None -> raise (Failure "HTTP request failed")
                with
                | e ->
                  (* Log the error *)
                  Printf.printf "[ERROR] Failed to fetch %s: %s\n%!" url (Printexc.to_string e) ;
                  raise e)
          | _ -> None)
    }
  in
  (* Run the function f with the handler *)
  Effect.Deep.match_with f () handler

let () =
  let urls = ["https://ocaml.org"; "https://discuss.ocaml.org"; "https://opam.ocaml.org"] in
  (* Crawl the URLs and handle effects, provide the raw data about the web pages, including the
     content and retrieval timestamp *)
  let results = handle_effects (fun () -> crawl_urls urls) in

  Printf.printf "\nCrawling Results:\n" ;
  List.iter
    (fun result ->
      Printf.printf "%s: %d bytes (fetched at %f)\n" result.url (String.length result.content)
        result.timestamp)
    results ;

  (* Analyze the results, focus on the content length without the actual content *)
  let analyzed = analyze_results results in
  Printf.printf "\nAnalysis Results:\n" ;
  List.iter (fun (url, len) -> Printf.printf "%s: %d bytes\n" url len) analyzed
