//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

const Func = enum { CONST, IDENT, ADD, NEG, SINE, COSINE, UNKOWN };

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
        const _refl = Func.COSINE;
        pub fn eval(x: F) F {
            return @cos(x);
        }
        pub fn grad() type {
            return Neg(Sine(F));
        }
    };
}

pub fn Simplified(F: type) type {
    //@compileLog(std.fmt.comptimePrint("{}\n", .{F._refl}));
    switch (F._refl) {
        Func.NEG => switch (F._Sub._refl) {
            Func.NEG => return Simplified(F._Sub._Sub),
            else => return F,
        },
        Func.ADD => {
            if (F._Left._refl == Func.CONST and F._Left._val == 0.0) {
                return Simplified(F._Right);
            }
            if (F._Right._refl == Func.CONST and F._Right._val == 0.0) {
                return Simplified(F._Left);
            }
            return Add(Simplified(F._Left), Simplified(F._Right));
        },
        else => return F,
    }
}

pub fn FromFormula(comptime formula: []const u8) type {
    if (formula.len == 1 and formula[0] == 'x') {
        return Ident(comptime_float);
    }
}
