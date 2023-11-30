const std = @import("std");

pub fn LinkedList(comptime T: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            centroid: T,
            members: std.ArrayList(T),
            next: ?*Node,
        };

        allocator: *std.mem.Allocator,
        head: ?*Node,
        len: usize,

        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .head = null,
                .len = 0,
            };
        }

        pub fn append(self: *This, centroid: T, members: std.ArrayList(T)) !void {
            const new_node: *Node = try self.allocator.create(Node);
            new_node.* = Node{ .centroid = centroid, .members = members, .next = self.head };
            self.head = new_node;
            self.len += 1;
        }

        pub fn removeAll(self: *This) void {
            var current_node: ?*Node = self.head;
            while (current_node) |node| {
                current_node = node.next;

                node.members.deinit();
                self.allocator.destroy(node);
            }
            self.head = null;
            self.len = 0;
        }

        pub fn print(self: *This) void {
            var current_node = self.head;
            while (current_node) |node| {
                std.debug.print("centroid {any}\n", .{node.centroid});
                for (node.members.items) |member| {
                    std.debug.print("\tmember {any}\n", .{member});
                }
                current_node = node.next;
            }
        }
    };
}
