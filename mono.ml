(* Monopmorphizes a typed (incl poly) program *)

open Tast
open Mast


(* Function takes a tprog (list of typed definitions),
   and monomorphizes it. to produce a mprog *)
let monomorphize (tdefns : tprog) =

  (* Takes a Tast.gtype and returns the equivalent Mast.mtype *)
  let rec ofGtype = function
      TYCON ty    -> Mtycon  (ofTycon ty)
    | TYVAR tp    -> Mtyvar   (ofTyvar tp)
    | CONAPP con  -> Mconapp (ofConapp con)
  and ofTycon = function
      TyInt        -> MIntty
    | TyBool       -> MBoolty
    | TyChar       -> MCharty
    | TArrow rety  -> MTarrow (ofGtype rety)
  and ofTyvar = function
      TVariable n -> n
  and ofConapp (tyc, tys) = (ofTycon tyc, List.map ofGtype tys)
  in




  (* Takes an mtype, and returns true if it is polymorphic, false o.w. *)
  let rec isPolymorphic (typ : mtype) = match typ with
    | Mtycon  t -> poly_tycon t
    | Mtyvar  _ -> true
    | Mconapp c -> poly_conapp c
  and poly_tycon = function
      MIntty | MBoolty | MCharty -> false
    | MTarrow t -> isPolymorphic t
  and poly_conapp (tyc, mtys) =
    (poly_tycon tyc)
    || (List.fold_left (fun init mtyp -> init || (isPolymorphic mtyp))
          false mtys)
  in



  (* Takes a type environment and a string key "id". Returns the
       value (mtype) that the key mapts to. *)
  let lookup (id : mname) (gamma : polyty_env) =
    StringMap.find id gamma
  in


  (* Takes a name and an polyty_env, and inserts it into the map *)
  let set_aside (id : mname) ((ty, exp) : mexpr) (gamma : polyty_env) =
    StringMap.add id (ty, exp) gamma
  in


  (* Returns true if ty is a type variable *)
  let isTyvar (ty : mtype) = match ty with
      Mtycon _  -> false
    | Mtyvar _  -> true
    | Mconapp _ -> false
  in

  (* Returns true if ty is a function type *)
  let isFunctionType (ty : mtype) = match ty with
      Mconapp (MTarrow _, _)  -> true
    | _                       -> false
  in


  (* (fty, exp) == poly lambda expression
     (ty) == mono function type *)
  let resolve (prog : mprog) (id : mname) (ty : mtype) ((fty, exp) : mexpr) =
    (* Given a function type, returns the list of the types of the arguments *)
    let get_type_of_args = function
        Mconapp (MTarrow _, formaltys) -> formaltys
      | _ -> Diagnostic.error 
              (Diagnostic.MonoError "cannot monomorphize non-function type")
    in

    let formaltys     = get_type_of_args ty  in (* mono *)
    let polyargtys    = get_type_of_args fty in (* poly *)
    let substitutions = List.combine polyargtys formaltys in

    (* Given a (polymorphic) mtype, returns the monomorphic version *)
    let resolve_mty (mty : mtype) =
      let apply_subs typ (arg, sub) =
        if isTyvar arg
          then
            let tyvarID =
              (match arg with
                 Mtyvar i -> i
               | _ -> Diagnostic.error 
                        (Diagnostic.MonoError "non-tyvar substitution"))
            in
            let rec search_mtype = function
                Mtycon tyc -> Mtycon (search_tycon tyc)
              | Mtyvar i   -> if i = tyvarID then sub else Mtyvar i
              | Mconapp con -> Mconapp (search_con con)
            and search_tycon = function
                MIntty  -> MIntty
              | MCharty -> MCharty
              | MBoolty -> MBoolty
              | MTarrow retty -> MTarrow (search_mtype retty)
            and search_con (tyc, mtys) =
              (search_tycon tyc, List.map search_mtype mtys)
            in search_mtype typ
        else typ
      in List.fold_left apply_subs mty substitutions
    in

    (* Given an (polymorphic) mx, returns the monomorphic version, with an
       updated program, if any. *)
    let rec resolve_mx pro = function
        MLiteral l -> (MLiteral l, pro)
      | MVar     v -> (MVar v, pro)
      | MIf ((t1, e1), (t2, e2), (t3, e3)) ->
          let t1' = resolve_mty t1 in
          let t2' = resolve_mty t2 in
          let t3' = resolve_mty t3 in
          let (e1', pro1) = resolve_mx pro  e1 in
          let (e2', pro2) = resolve_mx pro1 e2 in
          let (e3', pro3) = resolve_mx pro2 e3 in
          (MIf ((t1', e1'), (t2', e2'), (t3', e3')), pro3)
      | MApply ((appty, app), args) ->
          (* resolve the expression thats applied *)
          let appty' = resolve_mty appty in
          let (app', pro') = resolve_mx pro app in
          (* resolve the arguments of the application *)
          let (argtys, argexps) = List.split args in
          let argtys' = List.map resolve_mty argtys in
          let (argexps', pro'') = resolve_listOf_mx pro' argexps in 
          let args' = List.combine argtys' argexps' in
          (MApply ((appty', app'), args'), pro'')
      | MLet (bs, body) -> 
          let (names, bexprs) = List.split bs in 
          let (btys, bmxs) = List.split bexprs in 
          let btys' = List.map resolve_mty btys in 
          let (bmxs', pro') = resolve_listOf_mx pro bmxs in 
          let bs' = List.combine names (List.combine btys' bmxs') in 
          let (body', pro'') = resolve_mexpr pro' body in 
          (MLet (bs', body'), pro'')
      | MLambda  (formals, body) ->
          let (formaltys, names) = List.split formals in
          let formaltys' = List.map resolve_mty formaltys in
          let formals' = List.combine formaltys' names in
          let (body', pro') = resolve_mexpr pro body in 
          let lambdaExp = MLambda (formals', body') in
          let pro'' = (MVal (id, (ty, lambdaExp))) :: pro' in
          (lambdaExp, pro'')
    and resolve_mexpr pro ((ty, mexp) : mexpr) = 
        let ty' = resolve_mty ty in
        let (mexp', pro') = resolve_mx pro mexp in
        let monoexp' = (ty', mexp') in
        (monoexp', pro')
    and resolve_listOf_mx pro (mxs : mx list) = 
        let (mx', pro') = 
          List.fold_left 
            (fun (mexlist, prog) mex -> 
                let (mex', prog') = resolve_mx prog mex in 
                (mex' :: mexlist, prog'))
            ([], pro) mxs
        in
        let mx' = List.rev mx' in 
        (mx', pro')
    in

    let (exp', prog') = resolve_mx prog exp in
    ((ty, exp'), prog')

  in




  (* Takes a texpr and returns the equivalent mexpr 
     and the prog (list of mdefns) *)
  let rec expr (gamma : polyty_env) (prog : mprog) ((ty, ex) : texpr) = 
    match ex with
      TLiteral l -> ((ofGtype ty, MLiteral (value l)), prog)
    | TypedVar v ->
        (* let () = print_endline ("looking for: " ^ v) in  *)
        let vartyp = (try fst (lookup v gamma)
                      with Not_found -> 
                          (* let () = print_endline "didn't find it" in  *)
                          ofGtype ty) in
        let actualtyp = ofGtype ty in
        if (isPolymorphic vartyp) && (isFunctionType vartyp)
          then
            let polyexp = lookup v gamma in
            let (_, prog') = resolve prog v actualtyp polyexp in
            ((actualtyp, MVar v), prog')
        else 
          ((actualtyp, MVar v), prog)
    | TypedIf  (t1, t2, t3) ->
        let (mexp1, prog1) = expr gamma prog t1 in 
        let (mexp2, prog2) = expr gamma prog1 t2 in
        let (mexp3, prog3) = expr gamma prog2 t3 in
        ((fst mexp3, MIf (mexp1, mexp2, mexp3)), prog3)
    | TypedApply (f, args) ->
        let (f', prog') = expr gamma prog f in
        let (args', prog'') =
          List.fold_left  
            (fun (arglst, pro) arg ->
              let (arg', pro') = expr gamma pro arg in
              (arg' :: arglst, pro'))
            ([], prog') args
        in
        let args' = List.rev args' in
        ((ofGtype ty, MApply (f', args')), prog'')
    | TypedLet (bs, body) -> 
        let binding (x, e) =  let (e', _) = expr gamma prog e in (x, e') in 
        let bs' = List.map binding bs in 
        let (body', prog') = expr gamma prog body in 
        ((ofGtype ty, MLet (bs', body')), prog')
    | TypedLambda (formals, body) ->
        let (formaltys, names) = List.split formals in
        let formaltys' = List.map ofGtype formaltys in
        let formals'   = List.combine formaltys' names in
        let gamma' = List.fold_left 
                        (fun env (ty, name) -> 
                         if isPolymorphic ty  
                            then set_aside name (ty, MVar name) env
                         else env)
                        gamma
                        formals' in 
        let (body', prog') = expr gamma' prog body in
        ((ofGtype ty, MLambda (formals', body')), prog')
  and value = function
    | TChar c -> MChar c
    | TInt  i -> MInt i
    | TBool b -> MBool b
    | TRoot t -> MRoot (tree t)
  and tree = function
    | TLeaf               -> MLeaf
    | TBranch (v, t1, t2) -> MBranch (value v, tree t1, tree t2)
  in


  (* Takes the current mprog built so far, and one tdefn, and adds
     the monomorphized version to the mprog. Returns a new mprog
     with the new definition added in.  *)
  let mono ((gamma, prog) : polyty_env * mprog) = function
      TVal (id, (ty, texp)) ->
        let ((mty, mexp), prog') = expr gamma prog (ty, texp) in
        if isPolymorphic mty
          then
            let gamma' = set_aside id (mty, mexp) gamma in
            (gamma', MVal (id, (mty, mexp)) :: prog')
        else (gamma, MVal (id, (mty, mexp)) :: prog')
    | TExpr (ty, texp) ->
        let ((mty, mexp), prog') = expr gamma prog (ty, texp) in
        let () = if isPolymorphic mty then 
          Diagnostic.warning 
            (Diagnostic.MonoWarning ("polymorphic type leftover;" 
                                     ^ " resolving to integers"))
        else ()
        in (gamma, MExpr (mty, mexp) :: prog')

        (* if isPolymorphic mty
          then (gamma, prog')
        else (gamma, MExpr (mty, mexp) :: prog') *)
  in

  let (_, program) = List.fold_left mono (StringMap.empty, []) tdefns in 




  (* Bug/Bandaid - unable to resolve polymorphism.
     Iterate through the current "mono" typed program. 
     Insert integer type wherever leftover type variables remain *)
  let buggy_resolve (prog : mprog) (def : mdefn) = 

    (* resolves any remaining polymorphism in an mexpr to integer type *)
    let rec resolve_expr ((ty, exp) : mexpr) = 
      (* turns tyvar into int type *)
      let rec resolve_mty = function 
        | Mtycon  t -> Mtycon (resolve_tycon t)
        | Mtyvar  _ -> Mtycon MIntty
        | Mconapp c -> Mconapp (resolve_conapp c)
      and resolve_tycon = function
        | MIntty    -> MIntty
        | MBoolty   -> MBoolty
        | MCharty   -> MCharty
        | MTarrow t -> MTarrow (resolve_mty t)
      and resolve_conapp (tyc, mtys) = 
            (resolve_tycon tyc, List.map resolve_mty mtys)
      in

      (* finds and resolves any nested tyvars to int type *)
      let resolve_mx = function 
        | MLiteral l -> MLiteral l
        | MVar v     -> MVar v
        | MIf (e1, e2, e3) -> 
            let r1 = resolve_expr e1 in 
            let r2 = resolve_expr e2 in 
            let r3 = resolve_expr e3 in 
            MIf (r1, r2, r3)
        | MApply (f, args) -> 
            let f' = resolve_expr f in 
            let args' = List.map resolve_expr args in 
            MApply (f', args')
        | MLet (bs, body) -> 
            let bs' = List.map (fun (name, mex) -> 
                                  (name, resolve_expr mex)) 
                               bs in
            let body' = resolve_expr body in 
            MLet (bs', body')
        | MLambda (formals, body) ->
            let formals' = 
              List.map (fun (mty, name) -> (resolve_mty mty, name)) formals in 
            let body' = resolve_expr body in 
            MLambda (formals', body')
      in 

      (resolve_mty ty, resolve_mx exp)
    in

    (* Resolve the given mdefn *)
    match def with 
    | MVal (id, ex) -> MVal  (id, resolve_expr ex) :: prog 
    | MExpr ex      -> MExpr (resolve_expr ex) :: prog 
  in 

  List.fold_left buggy_resolve [] program
