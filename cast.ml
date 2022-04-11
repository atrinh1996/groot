(*
    Closure converted Abstract Syntax tree 
    Assumes name-check and type-check have already happened
*)

(* open Ast *)
open Sast 
module StringMap = Map.Make(String)

(* int StringMap.t - for our rho/variable environment 
   (DOES NOT MAP TO VALUES) *)
type var_env = (int * gtype) StringMap.t
let emptyEnv = StringMap.empty
let emptyList = []

type cname = string


type cexpr = gtype * cx
and cx =
  | CLiteral  of cvalue 
  | CVar      of cname 
  | CIf       of cexpr * cexpr * cexpr
  | CApply    of cexpr * cexpr list 
  | CLet      of (cname * cexpr) list * cexpr 
  | CLambda   of (gtype * cname) list * cexpr
and cvalue = 
  | CChar     of char
  | CInt      of int
  | CBool     of bool
  | CRoot     of ctree
and ctree = 
  | CLeaf 
  | CBranch   of cvalue * ctree * ctree

type cdefn = 
  | CVal      of cname * cexpr
  | CExpr     of cexpr


(* function definiton record type (imperative style to record information) *)
type fdef = 
{
  rettyp  : gtype; 
  fname   : cname; 
  formals : (gtype * cname) list;
  frees   : (gtype * cname) list; 
  body    : cexpr;
}

(* funciton definition table used to handle multiple definitons of a function *)
type func_env = fdef StringMap.t

(* a CAST *)
type cprog = 
{
  mutable main        : cdefn list; (* list for main instruction *)
  mutable functions   : fdef list;   (* table of function definitions *)
  mutable rho         : var_env;    (* variable declaration table *)
  mutable phi         : cname list; (* fname list to deal with dup defs of functions *)
}





(* Pretty Print *)
let rec string_of_cexpr (ty, e) = 
    (* "["  *)
        (* ^ string_of_typ ty ^ " : "  *)
        (* ^  *)
        string_of_cx e 
        (* ^ "]" *)
and string_of_cx = function 
    | CLiteral v -> string_of_cvalue v
    | CVar n -> n  
    | CIf (e1, e2, e3) -> 
        "(if "  ^ string_of_cexpr e1 ^ " " 
                ^ string_of_cexpr e2 ^ " " 
                ^ string_of_cexpr e3 ^ ")"
    | CApply (f, args) -> 
      "(" ^ string_of_cexpr f ^ " " 
          ^ String.concat " " (List.map string_of_cexpr args) ^ ")"
    | CLet (binds, body) -> 
        let string_of_binding (id, e) = 
              "[" ^ id ^ " " ^ (string_of_cexpr e) ^ "]"
        in "(let ("  ^ String.concat " " (List.map string_of_binding binds) 
                     ^ ") " ^ string_of_cexpr body ^ ")"
    | CLambda (formals, body) -> 
        let (tys, names) = List.split formals in 
        "(lambda (" ^ (List.fold_left2 
                        (fun space ty para -> string_of_typ ty ^ space ^ para) 
                        " " tys names) 
                    ^ ") " 
                    ^ string_of_cexpr body ^ ")"
and string_of_cvalue = function
    | CChar c -> String.make 1 c 
    | CInt  i -> string_of_int i
    | CBool b -> if b then "#t" else "#f"
    | CRoot t -> string_of_ctree t
and string_of_ctree = function
    | CLeaf -> "leaf"
    | CBranch (v, sib, child) -> 
        "(tree " ^ string_of_cvalue v ^ " " 
                 ^ string_of_ctree sib ^ " " 
                 ^ string_of_ctree child ^ ")"


let string_of_cdefn = function 
    | CVal (id, e) -> "(val " ^ id ^ " " ^ string_of_cexpr e ^ ")"
    | CExpr (cexp) -> string_of_cexpr cexp

let string_of_main main = 
    String.concat "\n" (List.map string_of_cdefn main) ^ "\n"

let string_of_functions (funcs : fdef list) = 
  let string_of_fdef ret_string {
        rettyp = return;
        fname = fname; 
        formals = formals;
        frees = frees;
        body = body;
    } = 
      let string_of_formal  (ty, para) = string_of_typ ty ^ " " ^ para in
      (* let string_of_free    (ty, nm) = string_of_typ ty ^ " " ^ nm in *)
      (* let listfrees id (num, ty) l = (ty, id ^ string_of_int num) :: l in  *)
      (* let args = formals @ List.rev (StringMap.fold listfrees frees []) in *)
      let args = formals @ frees in
      let def = string_of_typ return ^ " " ^ fname ^ " (" 
        ^ String.concat ", " (List.map string_of_formal args)
        ^ ")\n{\n" 
        (* ^ String.concat "\n" (List.map string_of_free frees) ^ "\n" *)
        ^ string_of_cexpr body  ^ "\n}\n"
      in ret_string ^ def ^ "\n"
  in List.fold_left string_of_fdef "" funcs

let string_of_rho rho = 
  StringMap.fold (fun id (num, ty) s -> 
                    s ^ id ^ ": " ^ string_of_typ ty ^ " " ^ id ^ string_of_int num ^ "\n") 
                 rho ""

let string_of_phi phi = 
  List.iter print_endline phi

let string_of_cprog { main = main; functions = functions; rho = rho; phi = phi } = 
    print_endline "Main:";
    print_endline (string_of_main main);
    print_endline "Functions:";
    print_endline (string_of_functions functions);
    print_endline "Rho:";
    print_endline (string_of_rho rho);
    print_endline "Phi:";
    string_of_phi phi;
