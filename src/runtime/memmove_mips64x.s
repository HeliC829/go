// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build mips64 || mips64le

#include "textflag.h"

// See memmove Go doc for important implementation constraints.

// func memmove(to, from unsafe.Pointer, n uintptr)
TEXT runtime·memmove(SB), NOSPLIT|NOFRAME, $0-24
	MOVV	to+0(FP), R1
	MOVV	from+8(FP), R2
	MOVV	n+16(FP), R3
	BEQ	R1, R2, done
	BEQ	R3, done

	// If the destination is ahead of the source, start at the end of the
	// buffer and go backward.
	SGTU	R1, R2, R4
	BNE	R4, backward

	// If less than 8 bytes, do single byte copies.
	SGTU	$8, R3, R4
	BNE	R4, f_loop4_check

	// Check alignment. If the alignment differs, word copies are unsafe, but
	// byte copies can still be unrolled.
	AND	$7, R1, R5
	AND	$7, R2, R6
	BNE	R5, R6, f_loop8_unaligned_check
	BEQ	R5, f_loop_check

	// Move one byte at a time until we reach 8 byte alignment.
	MOVV	$8, R7
	SUBVU	R5, R7, R5
	SUBVU	R5, R3, R3
f_align:
	SUBVU	$1, R5
	MOVB	0(R2), R8
	MOVB	R8, 0(R1)
	ADDVU	$1, R1
	ADDVU	$1, R2
	BNE	R5, f_align

f_loop_check:
	SGTU	$16, R3, R4
	BNE	R4, f_loop8_check
	SGTU	$32, R3, R4
	BNE	R4, f_loop16_check
	SGTU	$64, R3, R4
	BNE	R4, f_loop32_check
f_loop64:
	MOVV	0(R2), R8
	MOVV	8(R2), R9
	MOVV	16(R2), R10
	MOVV	24(R2), R11
	MOVV	32(R2), R12
	MOVV	40(R2), R13
	MOVV	48(R2), R14
	MOVV	56(R2), R15
	MOVV	R8, 0(R1)
	MOVV	R9, 8(R1)
	MOVV	R10, 16(R1)
	MOVV	R11, 24(R1)
	MOVV	R12, 32(R1)
	MOVV	R13, 40(R1)
	MOVV	R14, 48(R1)
	MOVV	R15, 56(R1)
	ADDVU	$64, R1
	ADDVU	$64, R2
	SUBVU	$64, R3
	SGTU	$64, R3, R4
	BEQ	R4, f_loop64
	BEQ	R3, done

f_loop32_check:
	SGTU	$32, R3, R4
	BNE	R4, f_loop16_check
f_loop32:
	MOVV	0(R2), R8
	MOVV	8(R2), R9
	MOVV	16(R2), R10
	MOVV	24(R2), R11
	MOVV	R8, 0(R1)
	MOVV	R9, 8(R1)
	MOVV	R10, 16(R1)
	MOVV	R11, 24(R1)
	ADDVU	$32, R1
	ADDVU	$32, R2
	SUBVU	$32, R3
	SGTU	$32, R3, R4
	BEQ	R4, f_loop32
	BEQ	R3, done

f_loop16_check:
	SGTU	$16, R3, R4
	BNE	R4, f_loop8_check
f_loop16:
	MOVV	0(R2), R8
	MOVV	8(R2), R9
	MOVV	R8, 0(R1)
	MOVV	R9, 8(R1)
	ADDVU	$16, R1
	ADDVU	$16, R2
	SUBVU	$16, R3
	SGTU	$16, R3, R4
	BEQ	R4, f_loop16
	BEQ	R3, done

f_loop8_check:
	SGTU	$8, R3, R4
	BNE	R4, f_loop4_check
f_loop8:
	MOVV	0(R2), R8
	MOVV	R8, 0(R1)
	ADDVU	$8, R1
	ADDVU	$8, R2
	SUBVU	$8, R3
	SGTU	$8, R3, R4
	BEQ	R4, f_loop8
	BEQ	R3, done
	JMP	f_loop4_check

f_loop8_unaligned_check:
	SGTU	$8, R3, R4
	BNE	R4, f_loop4_check
f_loop8_unaligned:
	MOVB	0(R2), R8
	MOVB	1(R2), R9
	MOVB	2(R2), R10
	MOVB	3(R2), R11
	MOVB	4(R2), R12
	MOVB	5(R2), R13
	MOVB	6(R2), R14
	MOVB	7(R2), R15
	MOVB	R8, 0(R1)
	MOVB	R9, 1(R1)
	MOVB	R10, 2(R1)
	MOVB	R11, 3(R1)
	MOVB	R12, 4(R1)
	MOVB	R13, 5(R1)
	MOVB	R14, 6(R1)
	MOVB	R15, 7(R1)
	ADDVU	$8, R1
	ADDVU	$8, R2
	SUBVU	$8, R3
	SGTU	$8, R3, R4
	BEQ	R4, f_loop8_unaligned

f_loop4_check:
	SGTU	$4, R3, R4
	BNE	R4, f_loop1
f_loop4:
	MOVB	0(R2), R8
	MOVB	1(R2), R9
	MOVB	2(R2), R10
	MOVB	3(R2), R11
	MOVB	R8, 0(R1)
	MOVB	R9, 1(R1)
	MOVB	R10, 2(R1)
	MOVB	R11, 3(R1)
	ADDVU	$4, R1
	ADDVU	$4, R2
	SUBVU	$4, R3
	SGTU	$4, R3, R4
	BEQ	R4, f_loop4

f_loop1:
	BEQ	R3, done
	MOVB	0(R2), R8
	MOVB	R8, 0(R1)
	ADDVU	$1, R1
	ADDVU	$1, R2
	SUBVU	$1, R3
	JMP	f_loop1

backward:
	ADDVU	R3, R1
	ADDVU	R3, R2

	// If less than 8 bytes, do single byte copies.
	SGTU	$8, R3, R4
	BNE	R4, b_loop4_check

	// Check alignment. If the alignment differs, word copies are unsafe, but
	// byte copies can still be unrolled.
	AND	$7, R1, R5
	AND	$7, R2, R6
	BNE	R5, R6, b_loop8_unaligned_check
	BEQ	R5, b_loop_check

	// Move one byte at a time until we reach 8 byte alignment.
	SUBVU	R5, R3, R3
b_align:
	SUBVU	$1, R5
	SUBVU	$1, R1
	SUBVU	$1, R2
	MOVB	0(R2), R8
	MOVB	R8, 0(R1)
	BNE	R5, b_align

b_loop_check:
	SGTU	$16, R3, R4
	BNE	R4, b_loop8_check
	SGTU	$32, R3, R4
	BNE	R4, b_loop16_check
	SGTU	$64, R3, R4
	BNE	R4, b_loop32_check
b_loop64:
	SUBVU	$64, R1
	SUBVU	$64, R2
	MOVV	0(R2), R8
	MOVV	8(R2), R9
	MOVV	16(R2), R10
	MOVV	24(R2), R11
	MOVV	32(R2), R12
	MOVV	40(R2), R13
	MOVV	48(R2), R14
	MOVV	56(R2), R15
	MOVV	R8, 0(R1)
	MOVV	R9, 8(R1)
	MOVV	R10, 16(R1)
	MOVV	R11, 24(R1)
	MOVV	R12, 32(R1)
	MOVV	R13, 40(R1)
	MOVV	R14, 48(R1)
	MOVV	R15, 56(R1)
	SUBVU	$64, R3
	SGTU	$64, R3, R4
	BEQ	R4, b_loop64
	BEQ	R3, done

b_loop32_check:
	SGTU	$32, R3, R4
	BNE	R4, b_loop16_check
b_loop32:
	SUBVU	$32, R1
	SUBVU	$32, R2
	MOVV	0(R2), R8
	MOVV	8(R2), R9
	MOVV	16(R2), R10
	MOVV	24(R2), R11
	MOVV	R8, 0(R1)
	MOVV	R9, 8(R1)
	MOVV	R10, 16(R1)
	MOVV	R11, 24(R1)
	SUBVU	$32, R3
	SGTU	$32, R3, R4
	BEQ	R4, b_loop32
	BEQ	R3, done

b_loop16_check:
	SGTU	$16, R3, R4
	BNE	R4, b_loop8_check
b_loop16:
	SUBVU	$16, R1
	SUBVU	$16, R2
	MOVV	0(R2), R8
	MOVV	8(R2), R9
	MOVV	R8, 0(R1)
	MOVV	R9, 8(R1)
	SUBVU	$16, R3
	SGTU	$16, R3, R4
	BEQ	R4, b_loop16
	BEQ	R3, done

b_loop8_check:
	SGTU	$8, R3, R4
	BNE	R4, b_loop4_check
b_loop8:
	SUBVU	$8, R1
	SUBVU	$8, R2
	MOVV	0(R2), R8
	MOVV	R8, 0(R1)
	SUBVU	$8, R3
	SGTU	$8, R3, R4
	BEQ	R4, b_loop8
	BEQ	R3, done
	JMP	b_loop4_check

b_loop8_unaligned_check:
	SGTU	$8, R3, R4
	BNE	R4, b_loop4_check
b_loop8_unaligned:
	SUBVU	$8, R1
	SUBVU	$8, R2
	MOVB	0(R2), R8
	MOVB	1(R2), R9
	MOVB	2(R2), R10
	MOVB	3(R2), R11
	MOVB	4(R2), R12
	MOVB	5(R2), R13
	MOVB	6(R2), R14
	MOVB	7(R2), R15
	MOVB	R8, 0(R1)
	MOVB	R9, 1(R1)
	MOVB	R10, 2(R1)
	MOVB	R11, 3(R1)
	MOVB	R12, 4(R1)
	MOVB	R13, 5(R1)
	MOVB	R14, 6(R1)
	MOVB	R15, 7(R1)
	SUBVU	$8, R3
	SGTU	$8, R3, R4
	BEQ	R4, b_loop8_unaligned

b_loop4_check:
	SGTU	$4, R3, R4
	BNE	R4, b_loop1
b_loop4:
	SUBVU	$4, R1
	SUBVU	$4, R2
	MOVB	0(R2), R8
	MOVB	1(R2), R9
	MOVB	2(R2), R10
	MOVB	3(R2), R11
	MOVB	R8, 0(R1)
	MOVB	R9, 1(R1)
	MOVB	R10, 2(R1)
	MOVB	R11, 3(R1)
	SUBVU	$4, R3
	SGTU	$4, R3, R4
	BEQ	R4, b_loop4

b_loop1:
	BEQ	R3, done
	SUBVU	$1, R1
	SUBVU	$1, R2
	MOVB	0(R2), R8
	MOVB	R8, 0(R1)
	SUBVU	$1, R3
	JMP	b_loop1

done:
	RET
