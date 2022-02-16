/* 
    parser.mly

    produces a parser from a context-free grammar specification

    Compile with command to produce parser.ml with the ocaml code:
        ocamlyacc parser.mly

*/

/* Header */
%{ open Ast %} 

/* Tokens */
%token LPAREN RPAREN PLUS MINUS TIMES DIVIDE
%token EQ NEQ LT GT
%token IF
%token <int>  INT
%token <bool> BOOL
%token EOF

/* Precedence */
%nonassoc EQ NEQ /*CHANGE TO NONASSOC (and make binops nonassoc)*/
%nonassoc PLUS MINUS
%nonassoc TIMES DIVIDE
%nonassoc NEG

/* Declarations */
%start expr
%type <Ast.expr> expr

%%

/* Rules */
literal:
    | INT                                    { Int($1) }
    | BOOL                                   { Bool($1) }

expr:
    | literal                                { $1 }
    | LPAREN MINUS expr %prec NEG RPAREN                 { Unary(Neg, $3) }
    | LPAREN expr RPAREN                     { $2 }
    | LPAREN IF expr expr expr RPAREN        { If($3, $4, $5)}
    | LPAREN LT expr expr RPAREN             { Binops(Lt, $3, $4)}
    | LPAREN GT expr expr RPAREN             { Binops(Gt, $3, $4)}
    | LPAREN EQ expr expr RPAREN             { Binops(Eq, $3, $4) }
    | LPAREN NEQ expr expr RPAREN            { Binops(Neq, $3, $4) }
    | LPAREN PLUS expr expr RPAREN           { Binops(Add, $3, $4) }
    | LPAREN MINUS expr expr RPAREN          { Binops(Sub, $3, $4) }
    | LPAREN TIMES expr expr RPAREN           { Binops(Mul, $3, $4) }
    | LPAREN DIVIDE expr expr RPAREN          { Binops(Div, $3, $4) }
/*  | LPAREN closure (list of expr_opts?) RPAREN   { $2, $3 } */

/* POSSIBLE REORGANIZATION - 
everything that needs to be enclosed in parens can be a type of closure, so we don't need
to have super-long expression rules and all the expressions that need to be in parens could
instead be the more specific "closure" case

closure:
    | expr
    | IF expr expr expr 
*/

/* Trailer */
