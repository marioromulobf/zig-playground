const std = @import("std");
const zap = @import("zap");
const print = std.debug.print;
const okredis = @import("okredis");

var redisClient: ?okredis.Client = null;
var redisRbuf: [1024]u8 = undefined;
var redisWbuf: [1024]u8 = undefined;

pub fn main() !void {
    const net = std.net;
    print("Connecting to Redis at redis:{}\n", .{6379});

    redisClient = blk: {
        print("Connecting to redis service...\n", .{});

        var addressList = net.getAddressList(std.heap.page_allocator, "localhost", 6379) catch |err| {
            print("Could not resolve redis service: {}\n", .{err});
            break :blk null;
        };
        defer addressList.deinit();

        if (addressList.addrs.len == 0) {
            print("No address found for redis service\n", .{});
            break :blk null;
        }

        const redisAddr = addressList.addrs[0];

        const connection = net.tcpConnectToAddress(redisAddr) catch |err| {
            print("Could not connect to Redis: {}\n", .{err});
            break :blk null;
        };

        const client = okredis.Client.init(connection, .{
            .reader_buffer = &redisRbuf,
            .writer_buffer = &redisWbuf,
        }) catch |err| {
            print("Could not initialize Redis client: {}\n", .{err});
            break :blk null;
        };

        print("Successfully conected to Redis!\n", .{});
        break :blk client;
    };

    var listener = zap.HttpListener.init(.{
        .port = 8080,
        .on_request = handleRequest,
    });
    try listener.listen();
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}

fn handleRequest(r: zap.Request) !void {
    if (r.path) |path| {
        if (std.mem.eql(u8, path, "/bitonic") and std.mem.eql(u8, r.method.?, "POST")) {
            try handleBitonic(&r);
            return;
        }
    }
    r.setStatus(.not_found);
    r.sendBody("Not Found") catch {};
}

fn handleBitonic(r: *const zap.Request) !void {
    const bitonic = @import("bitonic-array.zig");
    const allocator = std.heap.page_allocator;

    const body = r.body orelse {
        r.setStatus(.bad_request);
        r.sendBody("{\"error\": \"Missing request body\" }") catch {};
        return;
    };

    var parsed = std.json.parseFromSlice(std.json.Value, allocator, body, .{}) catch {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Invalid JSON\" }") catch {};
        return;
    };

    defer parsed.deinit();

    const obj = parsed.value;
    const length = obj.object.get("length") orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing 'length'\" }") catch {};
        return;
    };

    const start = obj.object.get("start") orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing 'start'\" }") catch {};
        return;
    };

    const end = obj.object.get("end") orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing 'end'\" }") catch {};
        return;
    };

    if (length != .integer or start != .integer or end != .integer) {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Invalid field types\" }") catch {};
        return;
    }

    const result = bitonic.bitonicArray(allocator, @intCast(length.integer), @intCast(start.integer), @intCast(end.integer)) catch {
        r.setStatus(.bad_request);
        const errorMsg = std.fmt.allocPrint(allocator, "{{ \"error\": \"It's not possible to generate sequence of length {} in range [{}, {}]\" }}", .{length.integer, start.integer, end.integer}) catch "{ \"error\": \"Invalid input\" }";
        r.sendBody(errorMsg) catch {};
        return;
    };

    // Format te array as JSON
    var jsonArray = try std.ArrayList(u8).initCapacity(allocator, 256);
    defer jsonArray.deinit(allocator);

    try jsonArray.appendSlice(allocator, "[");
    for (result, 0..) |val, i| {
        if (i > 0) try jsonArray.appendSlice(allocator, ",");
        const valStr = try std.fmt.allocPrint(allocator, "{}", .{val});
        try jsonArray.appendSlice(allocator, valStr);
    }
    try jsonArray.appendSlice(allocator, "]");

    const jsonResponse = try std.fmt.allocPrint(allocator, "{{ \"sequence\": {s} }}", .{jsonArray.items});

    r.setStatus(.ok);
    r.sendBody(jsonResponse) catch {};
}