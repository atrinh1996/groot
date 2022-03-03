(* Top-level of the groot compiler: scan & parse input, 

    TODO: generate the resulting AST and generate a SAST from it
          generate LLVM IR, dump the module
  *)

type action = Ast | Compile

let () =
  let action = ref Ast in
  let set_action a () = action := a in
  let speclist = [
    ("-c", Arg.Unit (set_action Compile),
      "Check and print the generated LLVM IR");
    ("-a", Arg.Unit (set_action Ast), "Print the AST");
  ] in  
  let usage_msg = "usage: ./toplevel.native [-a|-c] [file.mc]" in
  let channel = ref stdin in
  Arg.parse speclist (fun filename -> channel := open_in filename) usage_msg;
  
  let lexbuf = Lexing.from_channel !channel in
    let ast = Parser.main Scanner.tokenize lexbuf in 
      match !action with
        Ast     -> print_string (Ast.string_of_main ast)
      | Compile -> print_string ("Error: Compilation not yet implemented\n")