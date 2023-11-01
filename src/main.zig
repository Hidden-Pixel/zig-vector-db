const std = @import("std");
const queue = @import("list.zig");

const port_num = 3000;

pub fn main() !void {
    var gpa_server = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa = gpa_server.allocator();

    var opts: std.net.StreamServer.Options = std.net.StreamServer.Options{
        .reuse_address = true,
    };

    var server: std.net.StreamServer = std.net.StreamServer.init(opts);
    defer server.deinit();

    // start the server listening on 127.0.0.1
    const addr = try std.net.Address.parseIp("0.0.0.0", port_num);
    try server.listen(addr);
    std.debug.print("listening on {d}\n", .{port_num});

    // start up thread pool
    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{ .allocator = gpa, .n_jobs = 12 });
    defer thread_pool.deinit();

    while (true) {
        var conn = try server.accept();
        try thread_pool.spawn(handleConnection, .{conn});
    }
}

// const s = "HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 11\n\nhello world";
fn handleConnection(conn: std.net.StreamServer.Connection) void {
    std.debug.print("in handle conn \n", .{});
    var y: i32 = 1000;
    _ = y;
    var buf: [1024]u8 = undefined;

    _ = conn.stream.read(&buf) catch |err| {
        std.debug.print("err", .{err});
    };

    //     catch |err| {
    //     std.debug.print("err {any}", .{err});
    // };
    // _ = bytes_read;
    std.debug.print("read in {s}", .{buf});

    // _ = conn.stream.write("hello") catch |err| {
    //     std.debug.print("{any}", .{err});
    // };
    conn.stream.close();
    std.debug.print("closing connection\n", .{});
    return;
}
