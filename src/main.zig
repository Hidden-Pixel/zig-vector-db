const std = @import("std");
const queue = @import("queue.zig");

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

const s = "HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 11\n\nhello world";
fn handleConnection(conn: std.net.StreamServer.Connection) void {
    // const msg = "hello\n";
    // _ = msg;

    _ = conn.stream.write(s) catch |err| {
        // _ = err;
        std.debug.print("{any}", .{err});
        // };
        // switch (err) {
        // else => {
        //     return;
        // },
    };
    conn.stream.close();
    return;
    // _ = try conn.stream.write(msg);
}
