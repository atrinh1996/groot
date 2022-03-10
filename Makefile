# Makefile for (g)ROOT project team
# Inspired by Richard/CS107 who was inspired by one provided by 
# Stephen Edwards for his Compilers course at Columbia University.

DEPENDS=toplevel.ml ast.ml sast.ml parser.mly scanner.mll diagnostic.ml

toplevel.native: $(DEPENDS)
	ocamlbuild toplevel.native

parser: parser.mly
	ocamlyacc parser.mly

lexer: ast.ml parser.mly scanner.mll
	ocamllex scanner.mll

clean:
	ocamlbuild -clean
	rm -rf parser.ml parser.mli scanner.ml toplevel.native groot.native
