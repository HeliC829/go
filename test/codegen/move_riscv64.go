// asmcheck

// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package codegen

func moveLargeRISCV64(p *struct{ dst, src [256]byte }) {
	// Older profiles dispatch at runtime; rva23 always uses RVV.
	// riscv64/rva20u64:`MOVBU.*runtime.riscv64HasV` `VSETVLI` `VLE8V` `VSE8V`
	// riscv64/rva22u64:`MOVBU.*runtime.riscv64HasV` `VSETVLI` `VLE8V` `VSE8V`
	// riscv64/rva23u64:-`MOVBU.*runtime.riscv64HasV` `VSETVLI` `VLE8V` `VSE8V`
	p.dst = p.src
}
