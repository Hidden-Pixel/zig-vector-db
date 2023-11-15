// const std = @import("std");
// const vec_store = @import("vec_store.zig");
// const VEC_DIM = 512;
// pub const server = struct {
//     v_store: type = undefined,
//     pub fn init(comptime T: type) server {
//         return server{ .v_store = T };
//     }
// };
//
// test "new server" {
//
//     // var gpa_server = std.heap.GeneralPurposeAllocator(.{}){};
//     // var salloc = gpa_server.allocator  var test_allocator = std.testing.allocator;();
//     var test_allocator = std.testing.allocator;
//     const v = vec_store.VecStore(@Vector(VEC_DIM, f32)).init(&test_allocator);
//     _ = v;
//     const v_store: server = server.init(vec_store);
//     _ = v_store;
// }
