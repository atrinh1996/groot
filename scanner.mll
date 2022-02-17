(*
        scanner.mll

    lexer file to create a lexical analyzer from a set of reg exs
    
    Compile with command to produce scanner.ml with the ocaml code:
        ocamllex scanner.mll
*)

(* Header *)
{ open Parser } 

(* Regular Expressions (optional *)
let digit = ['0'-'9']
let integer = ['-']?['0'-'9']+


(* Entry Points *)
rule tokenize = parse
  (* RegEx { action } *)
  | [' ' '\n' '\t' '\r'] { tokenize lexbuf }
  | "(;"                 { comment lexbuf }
  | '('                  { LPAREN }
  | ')'                  { RPAREN }
  | '-'                  { MINUS }
  | ['=']['=']           { EQ }
  | "if"                 { IF }
  | integer as ival      { INT(int_of_string ival) }
  | "#t"                 { BOOL(true) }
  | "#f"                 { BOOL(false) }
  | "lambda"             { LAMBDA }
  | eof                  { EOF }
  | _ as char            { raise(Failure("illegal character " 
                                          ^ Char.escaped char)) }

and comment = parse
  | ";)"               { tokenize lexbuf }
  | _                  { comment lexbuf }
      
