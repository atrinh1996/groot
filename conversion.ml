(* Closure conversion for groot compiler *)


open Tast
open Cast 


(***********************************************************************)

(* Pre-load rho with prints built in *)
let prerho env = 
  let add_prints map (k, v) =
    StringMap.add k [v] map
  in List.fold_left add_prints env [("printi", (0, intty)); 
                                    ("printb", (0, boolty)); 
                                    ("printc", (0, charty)); ]

(* list of variable names that get ignored/are not to be considered frees *)
let ignores = ["printi"; "printb"; "printc"; "+"]

(* partial cprog to return from this module *)
let res = 
{
  main        = emptyList; 
  functions   = emptyList; 
  rho         = prerho emptyEnv;
  structures  = emptyList
}

(* name used for anonymous lambda functions *)
let anon = "anon"
let count = ref 0

(* Converts a gtype to a ctype *)
let rec ofGtype = function
    TYCON ty    -> Tycon (ofTycon ty)
  | TYVAR tp    -> Tyvar (ofTyvar tp)
  | CONAPP con  -> Conapp (ofConapp con)
and ofTycon = function 
    TInt        -> Intty
  | TBool       -> Boolty
  | TChar       -> Charty
  | TArrow gty  -> Tarrow (ofGtype gty)
and ofTyvar = function 
    TVariable n -> Tparam n
and ofConapp (tyc, gtys) = (ofTycon tyc, List.map ofGtype gtys)


(* puts the given cdefn into the main list *)
let addMain d = res.main <- d :: res.main 

(* puts the given function name (id) mapping to its definition (f) in the 
   functions StringMap *)
let addFunction f = res.functions <- f :: res.functions 

let getFunction id = 
  List.find (fun frecord -> id = frecord.fname) res.functions

let addClosure elem = res.structures <- elem :: res.structures

(* Returns true if the given name id is already bound in the given 
   StringMap env. False otherwise *)
let isBound id env = StringMap.mem id env 

(* Adds a binding of k to v in the global StringMap env *)
let bind k v = res.rho <- 
  let currList = if isBound k res.rho then StringMap.find k res.rho else [] in
  let newList = v :: currList in 
  StringMap.add k newList res.rho

(* Returns the value id is bound to in the given StringMap env. If the 
   binding doesn't exist, Not_Found exception is raised. *)
let find id env = 
  let occursList = StringMap.find id env in List.nth occursList 0

(* Adds a local binding of k to v in the given StringMap env *)
let bindLocal map k (t, _) =
  let currList = if isBound k map then StringMap.find k map else [] in
  let localList = (0, ofGtype t) :: currList in 
  StringMap.add k localList map

(* Given expression an a string name n, returns true if n is 
   a free variable in the expression *)
let freeIn exp n = 
  let rec free (_, e) = match e with  
    | TLiteral _        -> false
    | TypedVar s        -> s = n
    | TypedIf (s1, s2, s3)  -> free s1 || free s2 || free s3
    | TypedApply (f, args)  -> free f  || List.fold_left 
                                        (fun a b -> a || free b) 
                                        false args
    | TypedLet (bs, body) -> List.fold_left (fun a (_, e) -> a || free e) false bs 
                         || (free body && not (List.fold_left 
                                                (fun a (x, _) -> a || x = n) 
                                                false bs))
    | TypedLambda ((_, formalIdents), body) -> 
        (* let (_, names) = List.split formals in  *)
        (* free body && not (List.fold_left (fun a x -> a || x = n) false names) *)
        free body && not (List.fold_left (fun a x -> a || x = n) false formalIdents)
  in free (inttype, exp)


(* Given the formals list and body of a lambda (xs, e), and a 
   variable environment, the function returns an environment with only 
   the free variables of this lambda. The environment of frees shall
   not inculde the names of built-in functions and primitives *)
let improve ((ts, xs), e) rho = 
  StringMap.filter 
    (fun n _ -> 
        if List.mem n ignores
          then false
        else freeIn (TypedLambda ((ts, xs), e)) n) 
    rho

(* removes any occurrance of things in no_no list from the env (StringMap)
   and returns the new StringMap *)
let clean no_no env =  
  StringMap.filter (fun n _ -> not (List.mem n no_no)) env

(* Given a var_env, returns a (ctype  * name) list version *)
let toParamList (venv : var_env) = 
  StringMap.fold  (fun id occursList res -> 
                      let (num, ty) = List.nth occursList 0 in 
                      let id' = if num = 0 then id 
                                else "_" ^ id ^ "_" ^ string_of_int num in 
                      (ty, id') :: res)
                  venv []

(* turns a list of ty * name list to a Var list  *)
let convertToVars (frees : (ctype * cname) list) = 
    List.map (fun (t, n) -> (t, CVar n)) frees 



(* Generate a new function type for lambda expressions in order to account
   for free variables, when given the original function type and an 
   association list of gtypes and var names to add to the new formals list
   of the function type. *)
let newFuntype  (origTyp : gtype) (newRet : ctype) 
                (toAdd : (ctype * cname) list) = 
  (match origTyp with 
    CONAPP (TArrow _, argstyp) -> 
      let newFormalTys = List.map ofGtype argstyp in 
      let (newFreeTys, _) = List.split toAdd in 
      (* Tycon (Tarrow (newRet, newFormalTys @ newFreeTys)) *)
      funty (newRet, newFormalTys @ newFreeTys)
  | _ -> raise (Failure "Non-function function type"))



(* Converts given sexpr to cexpr, and returns the cexpr *)
let rec texprToCexpr ((ty, e) : texpr) (env : var_env) =
  let rec exp ((typ, ex) : texpr) = match ex with
    | TLiteral v -> (ofGtype typ, CLiteral (value v))
    | TypedVar s     -> 
        (* In case s is a name of a define, get the closure type *)
        let (occurs, ctyp) = find s env in 
        (* to match the renaming convention in svalToCval, and to ignore
           built in prints *)
        let vname = if occurs = 0 
                      then s 
                    else "_" ^ s ^ "_" ^ string_of_int occurs
        in (ctyp, CVar (vname))
    | TypedIf (s1, s2, s3) -> 
        let cexp1 = exp s1 
        and cexp2 = exp s2
        and cexp3 = exp s3 in 
        (fst cexp2, CIf (cexp1, cexp2, cexp3))
    | TypedApply (f, args) -> 
        let (ctyp, f') = exp f in 
        let normalargs = List.map exp args in 
        (* actual type of the function application is the type of the return*)
        let (retty, freesCount) = 
          (match ctyp with 
              Tycon (Clo (_, functy, freetys)) -> 
                (match functy with 
                    Conapp (Tarrow ret, _) -> (ret, List.length freetys)
                  | _ -> raise (Failure "Non-function function type"))
            | _ -> (intty, 0)) in 
        (retty, CApply ((retty, f'), normalargs, freesCount))
    | TypedLet (bs, body) -> 
        let local_env = (List.fold_left (fun map (x, se) -> 
                                          bindLocal map x se) 
                                        env bs) in 
        let c_bs = List.map (fun (x, e) -> (x, exp e)) bs in 
        let (ctyp, body') = texprToCexpr body local_env in 
        (ctyp, CLet (c_bs, (ctyp, body')))
    (* Supose we hit a lambda expression, turn it into a closure *)
    (* | TypedLambda (formals, body) -> create_anon_function formals body typ env *)
    | TypedLambda ((formalTyvars, formalIdents), body) -> 
        (* let gtys = List.map (fun elem -> TYVAR elem) formalTyvars in 
        create_anon_function (List.combine gtys formalIdents) body typ env *)

        create_anon_function (formalTyvars, formalIdents) body typ env
  and value = function 
    | TChar c             -> CChar c 
    | TInt  i             -> CInt  i 
    | TBool b             -> CBool b 
    | TRoot t             -> CRoot (tree t)
  and tree = function 
    | TLeaf               -> CLeaf 
    | TBranch (v, t1, t2) -> CBranch (value v, tree t1, tree t2)
  in exp (ty, e)
(* When given just a lambda expresion withot a user defined identity/name 
   this function will generate a name and give the function a body --
   Lambda lifting. *)
and create_anon_function  (fformals : (Tast.tyvar list * string list)) (fbody : texpr) 
                          (ty : gtype) (env : var_env) = 
  (* All anonymous functions are named the same and numbered. *)
  let id = anon ^ string_of_int !count in 
  let () = count := !count + 1 in
  (* Create the record that represents the function body and definition *)
  let tyvs = fst fformals and idents = snd fformals in 
  let gtys = List.map (fun elem -> TYVAR elem) tyvs in 
  let fformals = List.combine gtys idents in 
  let local_env = List.fold_left (fun map (typ, x) -> 
                                    bindLocal map x (typ, TypedVar x))
                                  env fformals in 
  let func_body = texprToCexpr fbody local_env in 
  let f_def = 
    {
      body    = func_body;
      rettyp  = fst func_body;
      fname   = id; 
      formals = List.map (fun (ty, nm) -> (ofGtype ty, nm)) fformals;
      frees   = toParamList (improve ((tyvs, idents), fbody) env);
    } 
  in 
  let () = addFunction f_def in 
  (* New function type will include the types of free arguments *)
  let anonFunTy = newFuntype ty f_def.rettyp f_def.frees in 
  (* Record the type of the anonymous function and its "rea" ftype *)
  let () = bind id (1, anonFunTy) in 
  (* The value of a Lambda expression is a Closure -- new type construction 
     will help create the structs in codegen that represents the closure *)
  let (freetys, _) = List.split f_def.frees in 
  let clo_ty = closurety (id ^ "_struct", anonFunTy, freetys) in 
  let () = addClosure clo_ty in 
  let freeVars = convertToVars f_def.frees in 
  (clo_ty, CLambda (id, freeVars))



(* Converts given SVal to CVal, and returns the CVal *)
let tvalToCval (id, (ty, e)) = 
  (* check if id was already defined in rho, in order to get 
     the actual frequency the variable name was defined. 
     The (0, inttype is a placeholder) *)
  let (occurs, _) = if (isBound id res.rho) 
                      then (find id res.rho) 
                    else (0, intty) in
  (* Modify the name to account for the redefinitions, and so old closures 
     can access original variable values *)
  let id' = "_" ^ id ^ "_" ^ string_of_int (occurs + 1) in 
  let (ty', cexp) = texprToCexpr (ty, e) res.rho in 
  (* bind original name to the number of occurrances and the variable's type *)
  let () = bind id (occurs + 1, ty') in 
  (* Return the possibly new CVal definition *)
  CVal (id', (ty', cexp))
(***********************************************************************)



(* Given an sprog (which is an sdefn list), convert returns a 
   cprog version. *)
let conversion sdefns =
  (* With a given sdefn, function converts it to the appropriate CAST type
     and sorts it to the appropriate list in a cprog type. *)
  let convert = function 
    | TVal (id, (ty, texp)) -> 
        let cval = tvalToCval (id, (ty, texp)) in addMain cval
    | TExpr e -> 
        let cexp = texprToCexpr e res.rho in addMain (CExpr cexp)
  in 
    
  let _ = List.iter convert sdefns in 
    {
      main       = List.rev res.main;
      functions  = res.functions;
      rho        = res.rho;
      structures = res.structures
    }
