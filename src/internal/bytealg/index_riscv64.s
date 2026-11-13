// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "asm_riscv64.h"
#include "go_asm.h"
#include "textflag.h"

TEXT ·Index<ABIInternal>(SB),NOSPLIT|NOFRAME,$0-56
	// X10 = a_base
	// X11 = a_len
	// X12 = a_cap (unused)
	// X13 = b_base
	// X14 = b_len
	// X15 = b_cap (unused)
	MOV	X13, X12
	MOV	X14, X13
	JMP	indexbody<>(SB)

TEXT ·IndexString<ABIInternal>(SB),NOSPLIT|NOFRAME,$0-40
	// X10 = a_base
	// X11 = a_len
	// X12 = b_base
	// X13 = b_len
	JMP	indexbody<>(SB)

// input:
//   X10 = string pointer
//   X11 = string length
//   X12 = separator pointer
//   X13 = separator length (2 <= len <= 32)
TEXT indexbody<>(SB),NOSPLIT|NOFRAME,$0
	BLT	X11, X13, not_found

	MOV	X10, X14		// base pointer
	SUB	X13, X11, X11
	ADD	$1, X11		// candidate start count
	MOVBU	(X12), X16		// first separator byte
	MOV	X13, X25
	SUB	$1, X25		// last separator byte offset
	ADD	X12, X25, X5
	MOVBU	(X5), X26		// last separator byte


#ifndef hasV
	MOVB	internal∕cpu·RISCV64+const_offsetRISCV64HasV(SB), X5
	BEQZ	X5, scalar_search
#endif

	MOV	$16, X5
	BLT	X11, X5, scalar_search
	MOV	$2, X24

vector_search:
	BEQZ	X11, not_found
	VSETVLI	X11, E8, M8, TA, MA, X5
	MOV	X10, X28		// vector chunk base
	MOV	X11, X29		// remaining candidate count before this chunk
	MOV	X5, X30			// vector chunk length
	VLE8V	(X10), V8
	VMSEQVX	X16, V8, V0
	ADD	X10, X25, X7
	VLE8V	(X7), V16
	VMSEQVX	X26, V16, V1
	VMANDMM	V1, V0, V0

vector_find:
	VFIRSTM	V0, X31
	BGEZ	X31, vector_candidate
	ADD	X28, X30, X10
	SUB	X30, X29, X11
	JMP	vector_search

vector_candidate:
	ADD	X28, X31, X10
	SUB	X31, X29, X11
	JMP	verify

scalar_search:
	MOV	ZERO, X24
	BEQZ	X11, not_found

align_loop:
	AND	$7, X10, X15
	BEQZ	X15, scalar_aligned
	MOVBU	(X10), X17
	BEQ	X16, X17, check_last_byte
	ADD	$1, X10
	SUB	$1, X11
	BNEZ	X11, align_loop
	JMP	not_found

scalar_aligned:
	MOV	$8, X15
	BLT	X11, X15, byte_loop

	MOV	$0x0101010101010101, X17
	SLLI	$7, X17, X18		// 0x8080808080808080
	MUL	X16, X17, X19		// broadcast first separator byte

	PCALIGN	$16
word_loop:
	BLT	X11, X15, byte_loop
	MOV	X10, X28		// scalar word base
	MOV	X11, X29		// remaining candidate count before this word
	MOV	(X10), X20
	XOR	X20, X19, X20
	SUB	X17, X20, X21
	ANDN	X20, X18, X22
	AND	X21, X22
	BNEZ	X22, word_candidate
	ADD	$8, X10
	SUB	$8, X11
	JMP	word_loop

word_candidate:

	MOV	ZERO, X23
#ifndef hasZbb
	MOVB	internal∕cpu·RISCV64+const_offsetRISCV64HasZbb(SB), X5
	BEQZ	X5, find_word_candidate
#endif

find_word_candidate_zbb:
	CTZ	X22, X23
	SRLI	$3, X23
	JMP	adjust_word_candidate

find_word_candidate:
	AND	$0xff, X22, X21
	BNEZ	X21, adjust_word_candidate
	SRLI	$8, X22
	ADD	$1, X23
	JMP	find_word_candidate

adjust_word_candidate:
	ADD	X28, X23, X10
	SUB	X23, X29, X11
	MOV	$1, X24
	JMP	check_last_byte

byte_loop:
	BEQZ	X11, not_found
	MOVBU	(X10), X17
	BEQ	X16, X17, check_last_byte
	ADD	$1, X10
	SUB	$1, X11
	JMP	byte_loop

check_last_byte:
	ADD	X10, X25, X5
	MOVBU	(X5), X6
	BNE	X26, X6, next_start
	JMP	verify

verify:
	MOV	$1, X18

compare_loop:
	BEQ	X18, X25, found
	ADD	X10, X18, X19
	ADD	X12, X18, X20
	MOVBU	(X19), X21
	MOVBU	(X20), X22
	BNE	X21, X22, next_start
	ADD	$1, X18
	JMP	compare_loop

next_start:
	ADD	$1, X10
	SUB	$1, X11
	BEQZ	X11, not_found
	MOV	$2, X5
	BEQ	X24, X5, vector_next_candidate
	MOV	$1, X5
	BEQ	X24, X5, scalar_next_candidate
	JMP	scalar_search

scalar_next_candidate:
	// The SWAR mask can contain false positives above a true zero byte due to
	// borrow propagation, so scan the rest of this word with byte loads.
	ADD	$8, X28, X5

scalar_word_tail:
	BEQ	X10, X5, scalar_word_done
	BEQZ	X11, not_found
	MOVBU	(X10), X6
	BEQ	X16, X6, check_last_byte
	ADD	$1, X10
	SUB	$1, X11
	JMP	scalar_word_tail

scalar_word_done:
	MOV	ZERO, X24
	JMP	scalar_search

vector_next_candidate:
	VMSOFM	V0, V1
	VMANDNMM	V1, V0, V0
	JMP	vector_find

found:
	SUB	X14, X10
	RET

not_found:
	MOV	$-1, X10
	RET
