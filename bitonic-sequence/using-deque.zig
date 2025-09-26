const std = @import("std");
const print = std.debug.print;
const denque = std.denque;

fn bitonicArray(n: i32, l: i32, r: i32) void {
    print("fn bitonicArray: n = {}, l = {}, r = {}\n", .{n, l, r});
}

pub fn main() void {
    const n :i32 = 5;
    const l :i32 = 3;
    const r :i32 = 10;

    print("fn main: n = {}, l = {}, r = {}\n", .{n, l, r});

    bitonicArray(n, l, r);
}
