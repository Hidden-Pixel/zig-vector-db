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
