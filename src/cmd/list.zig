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
        tail: ?*Node,

        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .head = null,
                .tail = null,
            };
        }

        // Enqueues 'data' onto the queue.
        pub fn append(self: *This, centroid: T, members: std.ArrayList(T)) !void {
            const new_node = try self.allocator.create(Node);
            new_node.* = Node{ .centroid = centroid, .members = members, .next = null };

            // if the tail is not null, then make the current tail
            // point to the new node we are adding.
            // else the queue is empty so also set the head to
            // the same node.
            if (self.tail) |tail| {
                tail.next = new_node;
            } else {
                self.head = new_node;
            }
            self.tail = new_node;
        }

        pub fn removeAll(self: *This) void {
            var current_node: ?*Node = self.head;
            while (current_node) |node| {
                current_node = node.next;

                node.members.deinit();
                self.allocator.destroy(node);
            }
            self.head = null;
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
