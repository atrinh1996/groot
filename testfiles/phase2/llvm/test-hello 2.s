	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 12, 0
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #32                     ; =32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -8
	.cfi_offset w29, -16
Lloh0:
	adrp	x0, l_globalChar@PAGE
Lloh1:
	add	x0, x0, l_globalChar@PAGEOFF
	str	x0, [sp, #8]
	bl	_puts
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32                     ; =32
	ret
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_fmt:                                  ; @fmt
	.asciz	"%d\n"

l_boolT:                                ; @boolT
	.asciz	"#t"

l_boolF:                                ; @boolF
	.asciz	"#f"

l_globalChar:                           ; @globalChar
	.asciz	"h"

.subsections_via_symbols
