const std = @import("std");
const lib = @import("symbzig_lib");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Autodiff tests\n", .{});
    const sin = lib.Sine(f32);
    const pi = 3.14159265;
    try stdout.print("sine(pi) = {}\n", .{sin.eval(pi)});
    try stdout.print("sine type: {s}\n", .{@typeName(sin)});
    try stdout.print("sine'(pi) = {}\n", .{sin.grad().eval(pi)});
    try stdout.print("sine' type: {s}\n", .{@typeName(sin.grad())});
    try stdout.print("sine''(pi) = {}\n", .{sin.grad().grad().eval(pi)});
    try stdout.print("sine'' type: {s}\n", .{@typeName(sin.grad().grad())});
    try stdout.print("sine'''(pi) = {}\n", .{sin.grad().grad().grad().eval(pi)});
    try stdout.print("sine''' type: {s}\n", .{@typeName(sin.grad().grad().grad())});
    //x -(- 3) + 0
    const fun = lib.Add(lib.Add(lib.Ident(comptime_float), lib.Neg(lib.Neg(lib.Const(3.0)))), lib.Const(0));
    try stdout.print("f = x -(- 3), f(0) = {}, f'(0) = {}\n", .{ fun.eval(0.0), fun.grad().eval(0.0) });
    const simp_fun = lib.Simplified(fun);
    try stdout.print("original:   {s}, \nsimplified: {s}\n", .{ @typeName(fun), @typeName(simp_fun) });
    const formula = "x";
    const form = lib.FromFormula(formula);
    try stdout.print("from formula {s}: {s}\n", .{ formula, @typeName(form) });
    try bw.flush(); // Don't forget to flush!
}
