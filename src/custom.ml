(* Custom search system *)
open Js
open Dom_html

let (>>=) = Lwt.bind
                   
let wait_page () =
  let t, u = Lwt.wait () in
  let _ =
    window ## onload <-
      Dom.handler (fun _ -> Lwt.wakeup u (); _true)
  in t

let fail () = raise Not_found
let unopt x = Opt.get x fail
let retreive id = unopt (document ## getElementById (string id))
                        
let run f = (wait_page ()) >>= (fun () -> Lwt.return (f ()))
let display e t =
  List.iter (fun elt -> elt ## style ## display <- (string t)) e
  
let seek e =
  let elt =
    e 
    |> CoerceTo.input
    |> unopt
  in
  let kwd =
    let open Regexp in 
    let k = 
      to_string (elt ## value)
      |> split (regexp "\\s|\\+|;|,")
      |> List.fold_left (fun a x -> a^",.keyword_"^x) "" in
    string String.(sub k 1 ((length k)-1))

  in
  let all =
    (document ## querySelectorAll (string ".a_article"))
    |> Dom.list_of_nodeList
  in
  let candidates =
    (document ## querySelectorAll (kwd))
    |> Dom.list_of_nodeList
  in
  match candidates with
  | [] -> display all "block"
  | x ->
     begin
       display all "none";
       display x "block"
     end
       
  
let state () =
  let searchbar = (retreive "search-bar") in
  searchbar ## onkeyup <-
    Dom.handler (fun _ -> seek searchbar; _true)
let _ = run state
  
