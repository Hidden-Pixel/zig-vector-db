const std = @import("std");
const linked_list = @import("list.zig");

pub fn VecStore(comptime T: type) type {
    return struct {
        const This = @This();
        vectors: linked_list.LinkedList(T),

        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .vectors = linked_list.LinkedList(T).init(allocator),
            };
        }

        pub fn dotProduct(self: *This, v1: T, v2: T) f32 {
            _ = self;
            return @reduce(.Add, v1 * v2);
        }

        pub fn magnitude(self: *This, v1: T) f32 {
            _ = self;
            var sum = @reduce(.Add, v1 * v1);
            var sqrt_sum = std.math.sqrt(sum);
            return sqrt_sum;
        }

        pub fn cosineSim(self: *This, v1: T, v2: T) f32 {
            return self.dotProduct(v1, v2) / (self.magnitude(v1) * self.magnitude(v2));
        }

        pub fn get_best_match(self: *This, v: T) f32 {
            var best_match: f32 = 0;
            var current_node = self.vectors.head;
            while (current_node) |node| {
                var cosine = self.cosineSim(v, node.data);
                if (cosine > best_match) {
                    best_match = cosine;
                }
                current_node = node.next;
            }
            return best_match;
        }

        pub fn add(self: *This, v: T, meta: []const u8) !void {
            try self.vectors.add(v, meta);
        }
    };
}

test "dot product" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(3, f32) = @Vector(3, f32){ 1, 2, 3 };
    var v2: @Vector(3, f32) = @Vector(3, f32){ 4, 5, 6 };
    var v = VecStore(@Vector(3, f32)).init(&test_allocator);
    var dot_product = v.dotProduct(v1, v2);
    try std.testing.expect(dot_product == 32);
}

test "magnitude" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(2, f32) = @Vector(2, f32){ 2, 7 };
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    var magnitude = v.magnitude(v1);
    _ = magnitude;
    // try std.testing.expect(7.280109889280518e+00 == magnitude);
}

test "cosine" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(3, f32) = @Vector(3, f32){ 1, 2, 3 };
    var v2: @Vector(3, f32) = @Vector(3, f32){ 4, 5, 6 };
    var v = VecStore(@Vector(3, f32)).init(&test_allocator);
    var cosine = v.cosineSim(v1, v2);
    _ = cosine;
    // try std.testing.expect(cosine == 0.9746318461970762);
}

test "best match" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(3, f32) = @Vector(3, f32){ 1, 2, 3 };
    var v2: @Vector(3, f32) = @Vector(3, f32){ 4, 5, 6 };
    var v = VecStore(@Vector(3, f32)).init(&test_allocator);
    try v.add(v1, "some meta data");
    var best_match = v.get_best_match(v2);
    _ = best_match;
    // std.debug.print("best match {d}\n", .{best_match});
    // try std.testing.expect(best_match == 0.9746318461970762);
    v.vectors.removeAll();
}

fn generateRandomVectorf64(comptime n: usize) [n]f64 {
    var numbers: [n]f64 = undefined;
    var rnd = std.crypto.random;

    for (&numbers) |*val| {
        val.* += rnd.float(f64);
    }
    return numbers;
}

fn generateRandomVectorf32(comptime n: usize) [n]f32 {
    var numbers: [n]f32 = undefined;
    var rnd = std.crypto.random;

    for (&numbers) |*val| {
        val.* += rnd.float(f32);
    }
    return numbers;
}

test "stuff" {
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(1024, f32)).init(&test_allocator);
    // try v.add(v1, "some meta data");
    for (0..100) |i| {
        try v.add(generateRandomVectorf32(1024), "meta data");
        _ = i;
    }
    v.vectors.removeAll();
    var search_match = v.vectors.dequeue();
    if (search_match) |sm| {
        var best_match = v.get_best_match(sm);
        std.debug.print("best match {d}\n", .{best_match});
    } else {
        std.debug.print("dequeue is null\n", .{});
    }
    // var rndVec = generateRandomVectorf32(512);
    // _ = rndVec;
    // std.debug.print("rnd vec {any}\n", .{rndVec});
}