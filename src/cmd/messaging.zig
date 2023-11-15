const std = @import("std");
pub const COSINE_SIM: u8 = 1;

pub const message = struct {
    queue_name: []const u8,
    data: []u8,
};

pub const message_envelope = struct {
    message_type: u8,
    payload: message,
};

fn sendEnqueue(queue: []const u8, data: []u8) *message_envelope {
    var m = message{ .queue_name = queue, .data = data };
    var b = message_envelope{ .message_type = COSINE_SIM, .payload = m };
    return &b;
}

test "pack message" {
    var x = [_]u8{ 1, 2, 3, 4 };
    var m = sendEnqueue("queue name", &x);
    var bytes = std.mem.asBytes(m);
    std.debug.print("raw bytes {any}\n", .{bytes});
    std.debug.print("{any}\n", .{m});
}
// //
// test "message envelope" {
//     var x = [_]u8{ 1, 2, 3, 4 };
//     // populate the struct fields
//     var my_struct = message{ .queue_name = "hello", .data = &x };
//     // convert the message body to bytes
//     var my_struct_as_bytes = std.mem.asBytes(&my_struct);
//     // pack the message body in the message header
//     var my_struct_envelope = message_envelope.message_envelope{ .message_type = 1, .message_contents = my_struct_as_bytes };
//     // convert the message body packed in the header to bytes
//     var my_struct_envelope_as_bytes = std.mem.asBytes(&my_struct_envelope);
//
//     // convert the whole thing back to a new message header struct
//     const marshalled_envelope: *message_envelope = @ptrCast(my_struct_envelope_as_bytes);
//     // extract the message body from the unmarshalled header message
//     const marshalled_payload: *message = @ptrCast(@alignCast(marshalled_envelope.message_contents));
//
//     // test the original struct is in tact
//     const equal = std.mem.eql(u8, marshalled_payload.queue_name, "hello");
//     try std.testing.expect(equal);
// }
