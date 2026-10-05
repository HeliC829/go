// Copyright 2016 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// See memmove Go doc for important implementation constraints.

// void runtime·memmove(void*, void*, uintptr)
TEXT runtime·memmove<ABIInternal>(SB),NOSPLIT,$-0-24
	// X10 = to
	// X11 = from
	// X12 = n
	BEQ	X10, X11, done
	BEQZ	X12, done

	// If the destination is ahead of the source, start at the end of the
	// buffer and go backward.
	BGTU	X10, X11, backward

	// If less than 8 bytes, do single byte copies.
	MOV	$8, X9
	BLT	X12, X9, f_tail4

	// Check alignment - if alignment differs we have to do one byte at a time.
	AND	$7, X10, X5
	AND	$7, X11, X6
	BNE	X5, X6, f_loop8_unaligned
	BEQZ	X5, f_loop_check

	// Move one byte at a time until we reach 8 byte alignment.
	SUB	X5, X9, X5
	SUB	X5, X12, X12
f_align:
	SUB	$1, X5
	MOVB	0(X11), X14
	MOVB	X14, 0(X10)
	ADD	$1, X10
	ADD	$1, X11
	BNEZ	X5, f_align

f_loop_check:
	MOV	$16, X9
	BLT	X12, X9, f_tail8
	MOV	$32, X9
	BLT	X12, X9, f_tail16
	MOV	$64, X9
	BLT	X12, X9, f_tail32
	PCALIGN	$4
f_loop64:
	MOV	0(X11), X14
	MOV	8(X11), X15
	MOV	16(X11), X16
	MOV	24(X11), X17
	MOV	32(X11), X18
	MOV	40(X11), X19
	MOV	48(X11), X20
	MOV	56(X11), X21
	MOV	X14, 0(X10)
	MOV	X15, 8(X10)
	MOV	X16, 16(X10)
	MOV	X17, 24(X10)
	MOV	X18, 32(X10)
	MOV	X19, 40(X10)
	MOV	X20, 48(X10)
	MOV	X21, 56(X10)
	ADD	$64, X10
	ADD	$64, X11
	SUB	$64, X12
	BGE	X12, X9, f_loop64
	BEQZ	X12, done

f_tail32:
	MOV	$32, X9
	BLT	X12, X9, f_tail16
	MOV	0(X11), X14
	MOV	8(X11), X15
	MOV	16(X11), X16
	MOV	24(X11), X17
	MOV	X14, 0(X10)
	MOV	X15, 8(X10)
	MOV	X16, 16(X10)
	MOV	X17, 24(X10)
	ADD	$32, X10
	ADD	$32, X11
	SUB	$32, X12
	BEQZ	X12, done

f_tail16:
	MOV	$16, X9
	BLT	X12, X9, f_tail8
	MOV	0(X11), X14
	MOV	8(X11), X15
	MOV	X14, 0(X10)
	MOV	X15, 8(X10)
	ADD	$16, X10
	ADD	$16, X11
	SUB	$16, X12
	BEQZ	X12, done

f_tail8:
	MOV	$8, X9
	BLT	X12, X9, f_tail4
	MOV	0(X11), X14
	MOV	X14, 0(X10)
	ADD	$8, X10
	ADD	$8, X11
	SUB	$8, X12
	BEQZ	X12, done

f_tail4:
	AND	$4, X12, X5
	BEQZ	X5, f_tail2
	MOVB	0(X11), X14
	MOVB	1(X11), X15
	MOVB	2(X11), X16
	MOVB	3(X11), X17
	MOVB	X14, 0(X10)
	MOVB	X15, 1(X10)
	MOVB	X16, 2(X10)
	MOVB	X17, 3(X10)
	ADD	$4, X10
	ADD	$4, X11

f_tail2:
	AND	$2, X12, X5
	BEQZ	X5, f_tail1
	MOVB	0(X11), X14
	MOVB	1(X11), X15
	MOVB	X14, 0(X10)
	MOVB	X15, 1(X10)
	ADD	$2, X10
	ADD	$2, X11

f_tail1:
	AND	$1, X12, X5
	BEQZ	X5, done
	MOVB	0(X11), X14
	MOVB	X14, 0(X10)
	RET

	PCALIGN	$16
f_loop8_unaligned:
	MOVB	0(X11), X14
	MOVB	1(X11), X15
	MOVB	2(X11), X16
	MOVB	3(X11), X17
	MOVB	4(X11), X18
	MOVB	5(X11), X19
	MOVB	6(X11), X20
	MOVB	7(X11), X21
	MOVB	X14, 0(X10)
	MOVB	X15, 1(X10)
	MOVB	X16, 2(X10)
	MOVB	X17, 3(X10)
	MOVB	X18, 4(X10)
	MOVB	X19, 5(X10)
	MOVB	X20, 6(X10)
	MOVB	X21, 7(X10)
	ADD	$8, X10
	ADD	$8, X11
	SUB	$8, X12
	BGE	X12, X9, f_loop8_unaligned
	BNEZ	X12, f_tail4
	RET

backward:
	ADD	X10, X12, X10
	ADD	X11, X12, X11

	// If less than 8 bytes, do single byte copies.
	MOV	$8, X9
	BLT	X12, X9, b_tail4

	// Check alignment - if alignment differs we have to do one byte at a time.
	AND	$7, X10, X5
	AND	$7, X11, X6
	BNE	X5, X6, b_loop8_unaligned
	BEQZ	X5, b_loop_check

	// Move one byte at a time until we reach 8 byte alignment.
	SUB	X5, X12, X12
b_align:
	SUB	$1, X5
	SUB	$1, X10
	SUB	$1, X11
	MOVB	0(X11), X14
	MOVB	X14, 0(X10)
	BNEZ	X5, b_align

b_loop_check:
	MOV	$16, X9
	BLT	X12, X9, b_tail8
	MOV	$32, X9
	BLT	X12, X9, b_tail16
	MOV	$64, X9
	BLT	X12, X9, b_tail32
	PCALIGN	$4
b_loop64:
	SUB	$64, X10
	SUB	$64, X11
	MOV	0(X11), X14
	MOV	8(X11), X15
	MOV	16(X11), X16
	MOV	24(X11), X17
	MOV	32(X11), X18
	MOV	40(X11), X19
	MOV	48(X11), X20
	MOV	56(X11), X21
	MOV	X14, 0(X10)
	MOV	X15, 8(X10)
	MOV	X16, 16(X10)
	MOV	X17, 24(X10)
	MOV	X18, 32(X10)
	MOV	X19, 40(X10)
	MOV	X20, 48(X10)
	MOV	X21, 56(X10)
	SUB	$64, X12
	BGE	X12, X9, b_loop64
	BEQZ	X12, done

b_tail32:
	MOV	$32, X9
	BLT	X12, X9, b_tail16
	SUB	$32, X10
	SUB	$32, X11
	MOV	0(X11), X14
	MOV	8(X11), X15
	MOV	16(X11), X16
	MOV	24(X11), X17
	MOV	X14, 0(X10)
	MOV	X15, 8(X10)
	MOV	X16, 16(X10)
	MOV	X17, 24(X10)
	SUB	$32, X12
	BEQZ	X12, done

b_tail16:
	MOV	$16, X9
	BLT	X12, X9, b_tail8
	SUB	$16, X10
	SUB	$16, X11
	MOV	0(X11), X14
	MOV	8(X11), X15
	MOV	X14, 0(X10)
	MOV	X15, 8(X10)
	SUB	$16, X12
	BEQZ	X12, done

b_tail8:
	MOV	$8, X9
	BLT	X12, X9, b_tail4
	SUB	$8, X10
	SUB	$8, X11
	MOV	0(X11), X14
	MOV	X14, 0(X10)
	SUB	$8, X12
	BEQZ	X12, done

b_tail4:
	AND	$4, X12, X5
	BEQZ	X5, b_tail2
	SUB	$4, X10
	SUB	$4, X11
	MOVB	0(X11), X14
	MOVB	1(X11), X15
	MOVB	2(X11), X16
	MOVB	3(X11), X17
	MOVB	X14, 0(X10)
	MOVB	X15, 1(X10)
	MOVB	X16, 2(X10)
	MOVB	X17, 3(X10)

b_tail2:
	AND	$2, X12, X5
	BEQZ	X5, b_tail1
	SUB	$2, X10
	SUB	$2, X11
	MOVB	0(X11), X14
	MOVB	1(X11), X15
	MOVB	X14, 0(X10)
	MOVB	X15, 1(X10)

b_tail1:
	AND	$1, X12, X5
	BEQZ	X5, done
	SUB	$1, X10
	SUB	$1, X11
	MOVB	0(X11), X14
	MOVB	X14, 0(X10)
	RET

	PCALIGN	$16
b_loop8_unaligned:
	SUB	$8, X10
	SUB	$8, X11
	MOVB	0(X11), X14
	MOVB	1(X11), X15
	MOVB	2(X11), X16
	MOVB	3(X11), X17
	MOVB	4(X11), X18
	MOVB	5(X11), X19
	MOVB	6(X11), X20
	MOVB	7(X11), X21
	MOVB	X14, 0(X10)
	MOVB	X15, 1(X10)
	MOVB	X16, 2(X10)
	MOVB	X17, 3(X10)
	MOVB	X18, 4(X10)
	MOVB	X19, 5(X10)
	MOVB	X20, 6(X10)
	MOVB	X21, 7(X10)
	SUB	$8, X12
	BGE	X12, X9, b_loop8_unaligned
	BNEZ	X12, b_tail4
	RET

done:
	RET
