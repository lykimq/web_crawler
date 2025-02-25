(lang dune 3.0)

(name web_crawler)

(generate_opam_files true)

(package
 (name web_crawler)
 (synopsis "A web crawler using OCaml effects")
 (description "A web crawler implementation using OCaml 5's effects system")
 (depends
  (ocaml (>= 5.1.0))
  (dune (>= 3.0))
  (fmt (>= 0.9.0))
  (logs (>= 0.7.0))
  (lwt (>= 5.6.1))
  (cohttp-lwt-unix (>= 6.0.0))
  (yojson (>= 2.0.0))
  (tls-lwt (>= 0.15.0))
  (uri (>= 4.0.0))
  (cmdliner (>= 1.1.0))
  (ptime (= 1.2.0))
  (base (= v0.17.1))
  (mirage-crypto (= 1.2.0))))

(authors "Author Name <author@example.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license LICENSE)

(documentation https://url/to/documentation)
