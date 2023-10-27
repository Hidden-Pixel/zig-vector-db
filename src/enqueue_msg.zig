const std = @import("std");

const ENQUEUE_MSG_TYPE: u8 = 1;

pub const message_payload = struct {
    queue_name: []const u8,
    data: []u8,
};

pub const message_header = struct {
    message_type: u8,
    message_contents: []u8,
};

test "message envelope" {
    var x = [_]u8{ 1, 2, 3, 4 };
    var my_struct = message_payload{ .queue_name = "hello", .data = &x };
    var msg = std.mem.asBytes(&my_struct);

    var env = message_header{ .message_type = 1, .message_contents = msg };

    var payload = std.mem.asBytes(&env);

    for (payload) |byte| {
        _ = byte;
        // std.debug.print("{d}\n", .{byte});
    }

    std.debug.print("x type {any}\n", .{@TypeOf(x)});
    // var bytes = std.mem.asBytes(&my_struct);
    const rec: *message_header = @ptrCast(payload);
    std.debug.print("env msg type {d}\n", .{rec.message_type});
    std.debug.print("msg content {any}\n", .{rec.message_contents});

    const payload_recv: *message_payload = @ptrCast(@alignCast(rec.message_contents));
    std.debug.print("payload q name {s}\n", .{payload_recv.queue_name});

    // std.debug.print("{any}\n", .{mystruct});
}
