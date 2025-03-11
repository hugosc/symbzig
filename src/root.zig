//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

const Func = enum { CONST, IDENT, ADD, NEG, MUL, SINE, COSINE, POW, UNKOWN };

pub fn Const(val: comptime_float) type {
    return struct {
        pub const _refl = Func.CONST;
        const _val = val;
        pub fn eval(x: anytype) @TypeOf(x) {
            return _val;
        }
        pub fn grad() type {
            return Const(0.0);
        }
    };
}

pub fn Ident(comptime F: type) type {
    return struct {
        pub const _refl = Func.IDENT;
        pub fn eval(x: F) F {
            return x;
        }
        pub fn grad() type {
            return Const(1.0);
        }
    };
}

pub fn Add(comptime Fun1: type, comptime Fun2: type) type {
    return struct {
        pub const _refl = Func.ADD;
        const _Left = Fun1;
        const _Right = Fun2;
        pub fn eval(x: anytype) @TypeOf(x) {
            return Fun1.eval(x) + Fun2.eval(x);
        }
        pub fn grad() type {
            return Add(Fun1.grad(), Fun2.grad());
        }
    };
}

pub fn Neg(comptime Fun: type) type {
    return struct {
        pub const _refl = Func.NEG;
        const _Sub = Fun;
        pub fn eval(x: anytype) @TypeOf(x) {
            return -Fun.eval(x);
        }
        pub fn grad() type {
            return Neg(Fun.grad());
        }
    };
}

pub fn Mul(comptime Fun1: type, comptime Fun2: type) type {
    return struct {
        pub const _refl = Func.MUL;
        const _Left = Fun1;
        const _Right = Fun2;
        pub fn eval(x: anytype) @TypeOf(x) {
            return Fun1.eval(x) * Fun2.eval(x);
        }
        pub fn grad() type {
            Add(Mul(Fun1.grad(), Fun2), Mul(Fun1, Fun2.grad()));
        }
    };
}

pub fn Pow(comptime Fun: type, exp: comptime_float) type {
    //Sad because I need to cast to float
    const F = f64;
    return struct {
        const _exp = exp;
        const _Sub = Fun;
        pub const _refl = Func.POW;
        pub fn eval(x: anytype) @TypeOf(x) {
            return std.math.pow(F, Fun.eval(x), exp);
        }
        pub fn grad() type {
            return Mul(Mul(Const(exp), Pow(Fun, exp - 1)), Fun.grad());
        }
    };
}

pub fn Sine(comptime F: type) type {
    return struct {
        const _refl = Func.SINE;
        pub fn eval(x: F) F {
            return @sin(x);
        }
        pub fn grad() type {
            return Cosine(F);
        }
    };
}

pub fn Cosine(comptime F: type) type {
    return struct {
        pub const _refl = Func.COSINE;
        pub fn eval(x: F) F {
            return @cos(x);
        }
        pub fn grad() type {
            return Neg(Sine(F));
        }
    };
}

pub fn hasConstVal(comptime F: type, val: comptime_float) bool {
    return F._refl == Func.CONST and F._val == val;
}

pub fn isBinOp(comptime F: type) bool {
    return F._refl == Func.ADD or F._refl == Func.MUL;
}

//Bin op
//+ and *
//

//Ordered:
// Ordered(

// Expanded:
// c1*x^p1 + c2*x^p2, ..., cn*x^pn, where p1 > p2 > ... > pn.
//  Expanded(Const(v)) -> Const(v)
//  Expanded(x) -> x
//  Expanded(x*exp) -> x*exp
//  Expanded(F1 + F2) ->
//

// time to think
// - F: if F = Const(v) => Const(-v)
//
//

pub fn Simplified(comptime F: type) type {
    //@compileLog(std.fmt.comptimePrint("{}\n", .{F._refl}));
    switch (F._refl) {
        Func.NEG => {
            const S = Simplified(F._Sub);
            switch (S._refl) {
                Func.CONST => return Const(-S._val),
                else => return Neg(S),
            }
        },
        Func.ADD => {
            const SL = Simplified(F._Left);
            const SR = Simplified(F._Right);
            if (SL._refl == Func.CONST and SR._refl == Func.CONST) {
                return Const(SL._val + SR._val);
            }
            if (hasConstVal(SL, 0.0)) {
                return SR;
            }
            if (hasConstVal(SR, 0.0)) {
                return SL;
            }
            return Add(SL, SR);
        },
        Func.MUL => {
            const SL = Simplified(F._Left);
            const SR = Simplified(F._Right);
            if (SL._refl == Func.CONST and SR._refl == Func.CONST) {
                return Const(SL._val * SR._val);
            }
            if (hasConstVal(SL, 0.0) or hasConstVal(SR, 0.0)) {
                return Const(0.0);
            }
            if (hasConstVal(SL, 1.0)) {
                return Simplified(F._Right);
            }
            if (hasConstVal(SR, 1.0)) {
                return Simplified(F._Left);
            }
            return Mul(Simplified(F._Left), Simplified(F._Right));
        },
        Func.POW => {
            const S = Simplified(F._Sub);
            if (F._exp == 1.0) {
                return S;
            }
            if (F._exp == 0.0) {
                if (hasConstVal(S, 0.0)) {
                    @compileError("Performing undefined 0^0, loser.\n");
                } else {
                    return Const(1.0);
                }
            }
            return Pow(S, F._exp);
        },
        else => return F,
    }
}

pub fn FromFormula(comptime formula: []const u8) type {
    if (formula.len == 1 and formula[0] == 'x') {
        return Ident(comptime_float);
    }
}
