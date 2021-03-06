
(* Top-level of the groot compiler: scan & parse input,
    build the AST, generate LLVM IR *)

type action =
  | Ast
  | Name_Check
  | Tast
  | Mast
  | Hast
  | Cast
  | LLVM_IR
  | Compile 


let () =
  let action = ref Ast in
  let set_action a () = action := a in
  let speclist = [
    ("-a", Arg.Unit (set_action Ast), 		"Print the AST (default)");
    ("-n", Arg.Unit (set_action Name_Check), 	"Print the AST (name-checking)");
    ("-t", Arg.Unit (set_action Tast), 		"Print the TAST");
    ("-m", Arg.Unit (set_action Mast), 	"Print the MAST");
    ("-h", Arg.Unit (set_action Hast), 	"Print the HAST");
    ("-v", Arg.Unit (set_action Cast), 	"Print the CAST");
    ("-l", Arg.Unit (set_action LLVM_IR), 	"Print the generated LLVM IR");
    ("-c", Arg.Unit (set_action Compile),
      "Check and print the generated LLVM IR");
  ] in


  let usage_msg = 
      "usage: ./toplevel.native [-a|-n|-t|-m|-h|-v|-l|-c] [file.gt]" in
  let channel = ref stdin in
  Arg.parse speclist (fun filename -> channel := open_in filename) usage_msg;
  let lexbuf = Lexing.from_channel !channel in
  let ast = Parser.prog Scanner.tokenize lexbuf in
  match !action with
  (* Default action - print the AST using ast *)
  | Ast -> print_string (Ast.string_of_prog ast)
  (* All other action needs to generate an SAST, store in variable sast *)
  | _ ->
    let ast' = Scope.check ast in
    match !action with
    | Ast -> ()
    | Name_Check -> print_string (Ast.string_of_prog ast')
    | _ ->
      let tast = Infer.type_infer ast' in
      match !action with
      | Tast -> print_string (Tast.string_of_tprog tast)
      | _ ->
        let mast = Mono.monomorphize tast in
        match !action with
        | Mast -> print_string (Mast.string_of_mprog mast)
        | _ ->
          let hast = Hof.clean mast in 
          match !action with
          | Hast -> print_string (Hast.string_of_hprog hast)
          | _ ->
          let cast = Conversion.conversion hast in
            match !action with
            | Cast -> print_string (Cast.string_of_cprog cast)
            | LLVM_IR -> 
                print_string (Llvm.string_of_llmodule (Codegen.translate cast))
            | Compile -> 
                let the_module = Codegen.translate cast in
                Llvm_analysis.assert_valid_module the_module;
                print_string (Llvm.string_of_llmodule the_module)
            | _ -> print_string usage_msg
