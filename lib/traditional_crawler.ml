type result = {
    url : string
  ; content : string
  ; timestamp : float
}

(* Traditional implementation using LWT for concurrent HTTP requests *)
let fetch_url url =
  let open Lwt in
  Cohttp_lwt_unix.Client.get (Uri.of_string url) >>= fun (resp, body) ->
  Cohttp_lwt.Body.to_string body >>= fun content ->
  if resp.status = `OK then return (Some content) else return None

let log_message msg =
  let open Lwt in
  Printf.printf "[LOG] %s\n" msg ;
  return_unit

(* Takes a list of urls and fetch their content concurrently using LWT *)
let crawl_urls urls =
  let open Lwt in
  let fetch_and_log url =
    log_message (Printf.sprintf "Fetching %s" url) >>= fun () ->
    fetch_url url >>= fun content_opt ->
    match content_opt with
    | Some content ->
      let timestamp = Unix.gettimeofday () in
      return (Some { url; content; timestamp })
    | None -> log_message (Printf.sprintf "Failed to fetch %s" url) >>= fun () -> return None
  in
  (* Use Lwt_list.filter_map for concurrent processing *)
  Lwt_list.filter_map_p fetch_and_log urls

(* Analyze the results, focus on the content length without the actual content *)
let analyze_results results =
  results
  |> List.filter_map (fun result ->
         if String.length result.content > 100
         then Some (result.url, String.length result.content)
         else None)
  |> List.sort (fun (_, len1) (_, len2) -> compare len1 len2)
