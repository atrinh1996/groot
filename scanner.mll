(*
        scanner.mll

    lexer file to create a lexical analyzer from a set of reg exs
    
    Compile with command to produce scanner.ml with the ocaml code:
        ocamllex scanner.mll
*)

(* Header *)
{ 
  open Parser
} 

(* Regular Expressions (optional *)
let digit = ['0'-'9']
let integer = ['-']?['0'-'9']+


(* Entry Points *)
rule tokenize = parse
  | [' ' '\n' '\t' '\r'] { tokenize lexbuf }
  | "(;"                 { comment lexbuf }
  | '('                  { LPAREN }
  | ')'                  { RPAREN }
  | '+'                  { PLUS }
  | '-'                  { MINUS }
  | '*'                  { TIMES }
  | '/'                  { DIVIDE }
  | "mod"                { MOD }
  | "=="                 { EQ }
  | "!="                 { NEQ }
  | "<="                 { LEQ }
  | ">="                 { GEQ }
  | '<'                  { LT }
  | '>'                  { GT }
  | "if"                 { IF }
  | integer as ival      { INT(int_of_string ival) }
  | "#t"                 { BOOL(true) }
  | "#f"                 { BOOL(false) }
  | "lambda"             { LAMBDA }
  | "let"                { LET }
  | ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
  | "&&"                 { AND }
  | "||"                 { OR }
  | eof                  { EOF }
  | _ as char            { raise(Failure("illegal character " 
                                          ^ Char.escaped char)) }

and comment = parse
  | ";)"               { tokenize lexbuf }
  | _                  { comment lexbuf }
      
