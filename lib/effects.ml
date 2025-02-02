type url = string

type _ Effect.t += Fetch : url -> string Effect.t | Log : string -> unit Effect.t

let fetch url = Effect.perform (Fetch url)
let log msg = Effect.perform (Log msg)

let with_logging f =
  Effect.Deep.try_with f ()
    ~handler:
      {
        Effect.Deep.retc = (fun x -> x)
      ; exnc = raise
      ; effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Log msg ->
              Some
                (fun (k : (a, _) Effect.Deep.continuation) ->
                  Printf.printf "[LOG] %s\n" msg ;
                  Effect.Deep.continue k ())
            | _ -> None)
      }
