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
  (cohttp-lwt-unix (>= 6.0.0))
  (yojson (>= 2.0.0))
  (uri (>= 4.0.0))))

(authors "Author Name <author@example.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license LICENSE)

(documentation https://url/to/documentation)
