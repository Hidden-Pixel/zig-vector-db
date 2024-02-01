const std = @import("std");
const asdf = @import("cmd/http_server.zig");

pub fn main() !void {
    std.log.info("server starting...", .{});
    asdf.start();
}
