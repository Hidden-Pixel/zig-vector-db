const std = @import("std");
const q = @import("list.zig");

pub fn VecStore(comptime T: type) type {
    return struct {
        const This = @This();
        vectors: q.LinkedList(T),

        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .vectors = q.LinkedList(T).init(allocator),
            };
        }

        pub fn dotProduct(self: *This, v1: T, v2: T) f64 {
            _ = self;
            return @reduce(.Add, v1 * v2);
        }

        pub fn magnitude(self: *This, v1: T) f64 {
            _ = self;
            var sum = @reduce(.Add, v1 * v1);
            var sqrt_sum = std.math.sqrt(sum);
            return sqrt_sum;
        }

        pub fn cosineSim(self: *This, v1: T, v2: T) f64 {
            return self.dotProduct(v1, v2) / (self.magnitude(v1) * self.magnitude(v2));
        }

        pub fn compare(self: *This, v: T) f64 {
            var best_match: f64 = 0;
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

        pub fn add(self: *This, v: T) !void {
            try self.vectors.add(v);
        }
    };
}

test "dot product" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(3, f64) = @Vector(3, f64){ 1, 2, 3 };
    var v2: @Vector(3, f64) = @Vector(3, f64){ 4, 5, 6 };
    var v = VecStore(@Vector(3, f64)).init(&test_allocator);
    var dot_product = v.dotProduct(v1, v2);
    try std.testing.expect(dot_product == 32);
}

test "magnitude" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(2, f64) = @Vector(2, f64){ 2, 7 };
    var v = VecStore(@Vector(2, f64)).init(&test_allocator);
    var magnitude = v.magnitude(v1);
    try std.testing.expect(7.280109889280518e+00 == magnitude);
}

test "cosine" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(3, f64) = @Vector(3, f64){ 1, 2, 3 };
    var v2: @Vector(3, f64) = @Vector(3, f64){ 4, 5, 6 };
    var v = VecStore(@Vector(3, f64)).init(&test_allocator);
    var cosine = v.cosineSim(v1, v2);
    try std.testing.expect(cosine == 0.9746318461970762);
}

test "walk" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(3, f64) = @Vector(3, f64){ 1, 2, 3 };
    var v2: @Vector(3, f64) = @Vector(3, f64){ 4, 5, 6 };
    var v = VecStore(@Vector(3, f64)).init(&test_allocator);
    try v.add(v1);
    var best_match = v.compare(v2);
    try std.testing.expect(best_match == 0.9746318461970762);
    v.vectors.removeAll();
    // std.debug.print("Best match {d}\n", .{best_match});
}

const VEC_SIZE = std.math.pow(i32, 2, 8);
test "vec tize" {
    const v = @Vector(1000, f64);
    _ = v;
}
test "large search" {
    std.debug.print("VEC_SIZE {d}\n", .{VEC_SIZE});
    var test_allocator = std.testing.allocator;
    // var arena = std.heap.ArenaAllocator.init(test_allocator);
    // defer arena.deinit();
    var v = VecStore(@Vector(VEC_SIZE, f64)).init(&test_allocator);

    std.debug.print("populating list\n", .{});
    for (0..500) |x| {
        _ = x;

        var array: [VEC_SIZE]f64 = undefined;
        const rand = std.crypto.random;

        for (&array) |*item| {
            item.* = rand.float(f64);
        }

        //
        var vec: @Vector(VEC_SIZE, f64) = array;
        try v.add(vec);
    }
    std.debug.print("doing compare now\n", .{});
    var vx = v.vectors.dequeue();
    // v.compare(vx);
    var timer = try std.time.Timer.start();
    if (vx) |vv| {
        var compared = v.compare(vv);
        std.debug.print("compared {d}\n", .{compared});
    }
    var elapsed = timer.read();
    std.debug.print("Time taken: {}ms\n", .{elapsed});

    defer v.vectors.removeAll();
    // var v1: @Vector(VEC_SIZE, f64) = i;
    // v.compare(v1);
}
