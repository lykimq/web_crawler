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
