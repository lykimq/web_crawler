open Web_crawler

(* Helper function to print results *)
let print_result result =
  Printf.printf "%s: %d bytes (fetched at %f)\n%!" result.Crawler_effect.url
    (String.length result.Crawler_effect.content)
    result.Crawler_effect.timestamp

(* Helper function to print analysis *)
let print_analysis (url, len) = Printf.printf "%s: %d bytes\n%!" url len

let () =
  let urls = ["https://ocaml.org"; "https://discuss.ocaml.org"; "https://opam.ocaml.org"] in

  (* Effect-based implementation *)
  Printf.printf "\nStarting effect-based crawler...\n%!" ;
  let results = Crawler_effect.handle_effects (fun () -> Crawler_effect.crawl_urls urls) in

  Printf.printf "\nCrawling Results With Effects:\n%!" ;
  List.iter print_result results ;

  let analyzed = Crawler_effect.analyze_results results in
  Printf.printf "\nAnalysis Results With Effects:\n%!" ;
  List.iter print_analysis analyzed ;

  (* Traditional implementation *)
  Printf.printf "\nStarting traditional crawler...\n%!" ;
  let results_traditional = Lwt_main.run (Traditional_crawler.crawl_urls urls) in

  Printf.printf "\nCrawling Results Using Traditional Crawler:\n%!" ;
  List.iter
    (fun result ->
      Printf.printf "%s: %d bytes (fetched at %f)\n%!" result.Traditional_crawler.url
        (String.length result.Traditional_crawler.content)
        result.Traditional_crawler.timestamp)
    results_traditional ;

  let analyzed_traditional = Traditional_crawler.analyze_results results_traditional in
  Printf.printf "\nAnalysis Results Using Traditional Crawler:\n%!" ;
  List.iter print_analysis analyzed_traditional
