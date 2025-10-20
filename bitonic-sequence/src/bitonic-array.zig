const std = @import("std");
const print = std.debug.print;

pub fn bitonicArray(allocator: std.mem.Allocator, n: usize, l: i32, r: i32) ![]i32 {
    print("fn bitonicArray: n = {}, l = {}, r = {}\n", .{n, l, r});

    const maxLimit = ((r - l) * 2) + 1;
    print("fn bitonicArray: maxLimit = {}\n", .{maxLimit});

    if (n > maxLimit) {
        return error.InvalidInput;
    }

    var bitonicResult = try std.ArrayList(i32).initCapacity(allocator, n);
    defer bitonicResult.deinit(allocator);

    try bitonicResult.append(allocator, r - 1);

    var i = r;
    while (i >= l and bitonicResult.items.len < n) : (i -= 1) {
        try bitonicResult.append(allocator, i);
    }

    i = r - 2;
    while (i >= l and bitonicResult.items.len < n) : (i -= 1) {
        try bitonicResult.insert(allocator, 0, i);
    }

    return bitonicResult.toOwnedSlice(allocator);
}
