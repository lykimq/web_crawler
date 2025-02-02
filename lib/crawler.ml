open Effects

type result = {
    url : string
  ; content : string
  ; timestamp : float
}

let crawl_urls urls =
  List.filter_map
    (fun url ->
      try
        log (Printf.sprintf "Fetching %s" url) ;
        let content = fetch url in
        Some { url; content; timestamp = Unix.gettimeofday () }
      with
      | _ ->
        log (Printf.sprintf "Failed to fetch %s" url) ;
        None)
    urls

let analyze_results results =
  results
  |> List.filter_map (fun result ->
         if String.length result.content > 100
         then Some (result.url, String.length result.content)
         else None)
  |> List.sort (fun (_, len1) (_, len2) -> compare len1 len2)
