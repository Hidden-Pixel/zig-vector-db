const std = @import("std");

const ENQUEUE_MSG_TYPE: u8 = 1;

pub const enqueue_msg = struct {
    queue_name: []const u8,
    data: []u8,
};

pub const envelope = struct {
    message_type: u8,
    message_contents: []u8,
};

test "message envelope" {
    var x = [_]u8{ 3, 1 };
    var my_struct = enqueue_msg{ .queue_name = "hello", .data = &x };
    var msg = std.mem.asBytes(&my_struct);
    var env = envelope{ .message_type = 1, .message_contents = msg };

    var payload = std.mem.asBytes(&env);

    for (payload) |byte| {
        _ = byte;
        // std.debug.print("{d}\n", .{byte});
    }
    // var bytes = std.mem.asBytes(&my_struct);
    const recv: *envelope = @ptrCast(payload);
    std.debug.print("env msg type {d}\n", .{recv.message_type});
    std.debug.print("msg content {any}\n", .{recv.message_contents});

    const payload_recv: *enqueue_msg = @ptrCast(@alignCast(recv.message_contents));
    std.debug.print("payload q name {s}\n", .{payload_recv.queue_name});

    // std.debug.print("{any}\n", .{mystruct});
}
