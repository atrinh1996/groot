(*
fun canonicalize; seems to generate the type variable names;
	'a through 'z
	once those are exhausted, then v1 and up, to infinity

*)

open Ast
open Sast

module StringMap = Map.Make(String)

type gtype = 
    | TInt 
    | TChar 
    | TBool 
    | TTree
    | TVar of int

(* type TConsts = {typ : } *)

(* Takes an Ast (defn list) and will return an Sast (sdefn list) *)
(* 

type defn = 
	| Val of ident * expr
	| Expr of expr

type sdefn = 
  | SVal of ident * sexpr
  | SExpr of sexpr

type sexpr = Ast.typ * Sast.sx

type typ = Integer | Character | Boolean

*)

(* Notes with Mert *)
(*

(let [x 3] z) <- will parse
???? z 
(let [x y] z)
---
(define foo () 3)  '() -> int
(foo 1 2 3 4 5) int * int * int * int * int -> int

*)

(* type texper = Var of grootType * ident | Let of (ident * grootType * texpr) list * texpr | .. *)

(* type Gamma = grootType StringMap *)

(* let infer_types defns : (Gamma) = StringMap.empty *)
(* End Notes with Mert *)

let semantic_check defns =
	(* let irast = check_non_type_stuff defns in -- Note *)
	(* let type_bindings = infer_types irast in -- Note *)
	(* let typed_ast = apply_types irast type_bindings in
	typed_ast;; -- Note *)
	let fresh =
  		let k = ref 0 in
    		fun () -> incr k; TVar !k
		in

	let rec generate_constraints expr = match expr with
		| Literal v -> 
			let literal_check v = match v with
				| Char _ -> (TChar, [])
				| Int  _ -> (TInt, [])
				| Bool _ -> (TBool, []) 
				| Root r -> 
					let rec tree_check t = match t with
						| Leaf   -> (TTree, [])
						| Branch (e, t1, t2) -> 
							let branch_check e t1 t2 =
								let e, c1 = generate_constraints e in
									let t1, c2 = tree_check t1 in 
										let t2, c3 = tree_check t2 in 
											let tau = fresh () in (TTree, [(tau, e); (TTree, t1); (TTree, t2)] @ c1 @ c2 @ c3)
							in branch_check e t1 t2
					in tree_check r
			in literal_check v
		| If (e1, e2, e3) ->
			let if_check e1 e2 e3 =
				let t1, c1 = generate_constraints e1 in
					let	t2, c2 = generate_constraints e2 in
						let t3, c3 = generate_constraints e3 in
							let tau = fresh () in (tau, [(TBool, t1); (tau, t2); (tau, t3)] @ c1 @ c2 @ c3)
			in if_check e1 e2 e3
    | Var (_) -> raise (Failure ("missing case for type checking"))
    | Apply (_, _) -> raise (Failure ("missing case for type checking"))
    | Let (_, _) -> raise (Failure ("missing case for type checking"))
    | Lambda (_,_) -> raise (Failure ("missing case for type checking"))
  in
			

(*handle type-checking for evaluation - make sure the expression returns the
	correct type, build local symbol table and do local type checking*)

	(* Lookup what Ast.typ value that the key name s maps to. *)
	(* let typeof_identifier s = 
		Requires creation of symbols table
		   code for try: StringMap.find s symbols
		try StringMap.find s symbols
		with Not_found -> raise (Failure ("undeclared identifier" ^ s))
	in *)

	(* Returns the Sast.sexpr (Ast.typ, Sast.sx) version of the given Ast.expr *)
	(* let rec expr = function
                                (* Problem - I force the Ast.typ to be Integer *)
		| Literal(lit)          -> (IType, SLiteral(value lit))
    | Var(_)                -> raise (Failure ("TODO - expr to sexpr of Var"))
    | If(_, _, _)           -> raise (Failure ("TODO - expr to sexpr of If"))
    | Apply(_, _)           -> raise (Failure ("TODO - expr to sexpr of Apply"))
    | Let(_, _)             -> raise (Failure ("TODO - expr to sexpr of Let"))
    | Lambda(_, _)          -> raise (Failure ("TODO - expr to sexpr of Lambda"))
  (* Returns the Sast.svalue version fo the given Ast.value *)
  and value = function 
  	| Char(_)     -> raise (Failure ("TODO - value to svalue of Char"))
    | Int(i)      -> SInt i
    | Bool(_)     -> raise (Failure ("TODO - value to svalue of Bool"))
    | Root(_)     -> raise (Failure ("TODO - value to svalue of Root"))
  in *)

  (* For the given Ast.defn, returns an Sast.sdefn *)
	let check_defn d = match d with
(*
		| Val (name, e) -> 
				let e' = expr e in 
				SVal(name, e')
		| Expr (_)      -> raise (Failure ("TODO - check_defn in Expr"))
*)
		| Val (_, e) -> generate_constraints e 
		| Expr (e)   -> generate_constraints e
in List.map check_defn defns 

(* Probably will map a check-function over the defns (defn list : defs) *)
(* check-function will take a defn and return an sdefn *)
