// Code generated from _gen/MIPS64latelower.rules using 'go generate'; DO NOT EDIT.

package mips64latelower

import "cmd/compile/internal/ssa/ssaop"
import "cmd/compile/internal/ssa"

func RewriteValue(v *ssa.Value) bool {
	switch v.Op {
	case ssaop.OpMIPS64MOVBUreg:
		return rewriteValue_OpMIPS64MOVBUreg(v)
	case ssaop.OpMIPS64MOVHUreg:
		return rewriteValue_OpMIPS64MOVHUreg(v)
	case ssaop.OpMIPS64MOVVconst:
		return rewriteValue_OpMIPS64MOVVconst(v)
	case ssaop.OpMIPS64MOVWUreg:
		return rewriteValue_OpMIPS64MOVWUreg(v)
	}
	return false
}
func rewriteValue_OpMIPS64MOVBUreg(v *ssa.Value) bool {
	v_0 := v.Args[0]
	// match: (MOVBUreg x)
	// cond: ssa.ZeroUpper56Bits(x)
	// result: x
	for {
		x := v_0
		if !(ssa.ZeroUpper56Bits(x)) {
			break
		}
		v.CopyOf(x)
		return true
	}
	return false
}
func rewriteValue_OpMIPS64MOVHUreg(v *ssa.Value) bool {
	v_0 := v.Args[0]
	// match: (MOVHUreg x)
	// cond: ssa.ZeroUpper48Bits(x)
	// result: x
	for {
		x := v_0
		if !(ssa.ZeroUpper48Bits(x)) {
			break
		}
		v.CopyOf(x)
		return true
	}
	return false
}
func rewriteValue_OpMIPS64MOVVconst(v *ssa.Value) bool {
	// match: (MOVVconst [0])
	// result: (ZERO)
	for {
		if ssa.AuxIntToInt64(v.AuxInt) != 0 {
			break
		}
		v.Reset(ssaop.OpMIPS64ZERO)
		return true
	}
	return false
}
func rewriteValue_OpMIPS64MOVWUreg(v *ssa.Value) bool {
	v_0 := v.Args[0]
	// match: (MOVWUreg x)
	// cond: ssa.ZeroUpper32Bits(x)
	// result: x
	for {
		x := v_0
		if !(ssa.ZeroUpper32Bits(x)) {
			break
		}
		v.CopyOf(x)
		return true
	}
	return false
}
func RewriteBlock(b *ssa.Block) bool {
	return false
}
