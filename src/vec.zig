const std = @import("std");
pub fn main() !void {
    var test_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    // var arena = std.heap.ArenaAllocator.init(test_allocator);
    // defer arena.deinit();
    var v = Vecs(@Vector(VEC_SIZE, f64)).init(test_allocator.allocator());

    std.debug.print("populating list\n", .{});
    for (0..1000000) |x| {
        _ = x;

        var array: [VEC_SIZE]f64 = undefined;
        const rand = std.crypto.random;

        for (&array) |*item| {
            item.* = rand.float(f64);
        }
        var vec: @Vector(VEC_SIZE, f64) = array;
        try v.add(vec);
    }
    std.debug.print("doing compare now\n", .{});

    var v1: @Vector(VEC_SIZE, f64) = v.get();
    var timer = try std.time.Timer.start();
    v.compare(v1);
    var elapsed = timer.read();
    std.debug.print("Time taken: {}ms\n", .{elapsed});
}

pub fn Vecs(comptime T: type) type {
    return struct {
        const This = @This();
        list: std.ArrayList(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .list = std.ArrayList(T).init(allocator),
            };
        }

        pub fn dotProduct(self: *This, v1: T, v2: T) f64 {
            _ = self;
            var sum = @reduce(.Add, v1 * v2);
            return sum;
        }

        pub fn magnitude(self: *This, v1: T) f64 {
            _ = self;
            var sum = @reduce(.Add, v1 * v1);
            var sqrt_sum = std.math.sqrt(sum);
            return sqrt_sum;
        }

        pub fn cosineSim(self: *This, v1: T, v2: T) f64 {
            var cosine = self.dotProduct(v1, v2) / (self.magnitude(v1) * self.magnitude(v2));
            return cosine;
        }

        pub fn compare(self: *This, v1: T) void {
            var closest: f64 = 0;
            for (self.list.items) |item| {
                var cosine = self.cosineSim(v1, item);
                if (cosine > closest) {
                    closest = cosine;
                }
                // std.debug.print("consine compare {d}\n", .{cosine});
            }
            std.debug.print("closest={d}\n", .{closest});
        }

        pub fn get(self: *This) T {
            return self.list.pop();
        }
        pub fn add(self: *This, v: T) !void {
            try self.list.append(v);
        }

        pub fn deinit(self: *This) void {
            self.list.deinit();
        }
    };
}
const VEC_SIZE = 512;
test "large search" {
    var test_allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(test_allocator);
    defer arena.deinit();
    var v = Vecs(@Vector(VEC_SIZE, f32)).init(arena.allocator());

    std.debug.print("populating list\n", .{});
    for (0..50000) |x| {
        _ = x;

        // var arr: [3]f64 = try createArray(arena.allocator(), 3);
        // _ = arr;
        var array: [VEC_SIZE]f64 = undefined;
        const rand = std.crypto.random;

        // errdefer allocator.free(array);

        for (&array) |*item| {
            item.* = rand.float(f32);
            // item = rand.float(f64); // Initialize array elements to 0
        }

        //
        var vec: @Vector(VEC_SIZE, f32) = array;
        // _ = vec;
        try v.add(vec);
        // var y = try createArray(&arena.allocator(), 512);
        // std.debug.print("index {x}\n", .{x});
    }
    std.debug.print("doing compare now\n", .{});

    var v1: @Vector(VEC_SIZE, f32) = v.get();
    var timer = try std.time.Timer.start();
    v.compare(v1);
    var elapsed = timer.read();
    std.debug.print("Time taken: {}ms\n", .{elapsed});
    // var vec: @Vector(512, f32) = arr1;
    // std.debug.print("{any}\n", .{x});
    // test_allocator.free(x);
}

fn createArray(allocator: std.mem.Allocator, n: usize) ![]f64 {
    _ = allocator;
    _ = n;
    // var array = try allocator.alloc(f64, 3);
    var array: [3]f64 = undefined;
    const rand = std.crypto.random;
    _ = rand;

    // errdefer allocator.free(array);

    for (array) |item| {
        _ = item;
        // item = rand.float(f64); // Initialize array elements to 0
    }

    return &array;
}

test "dot product" {
    const test_allocator = std.testing.allocator;
    var v1: @Vector(3, f64) = @Vector(3, f64){ 1, 2, 3 };
    var v2: @Vector(3, f64) = @Vector(3, f64){ 4, 5, 6 };
    var v = Vecs(@Vector(3, f64)).init(test_allocator);
    var dot_product = v.dotProduct(v1, v2);
    try std.testing.expect(dot_product == 32);

    v.deinit();
}

test "magnitude" {
    const test_allocator = std.testing.allocator;
    var v1: @Vector(2, f64) = @Vector(2, f64){ 2, 7 };
    var v = Vecs(@Vector(2, f64)).init(test_allocator);
    var dot_product = v.magnitude(v1);
    try std.testing.expect(7.280109889280518e+00 == dot_product);

    v.deinit();
}

test "cosine" {
    const test_allocator = std.testing.allocator;
    var v1: @Vector(3, f64) = @Vector(3, f64){ 1, 2, 3 };
    var v2: @Vector(3, f64) = @Vector(3, f64){ 4, 5, 6 };
    var v = Vecs(@Vector(3, f64)).init(test_allocator);
    var cosine = v.cosineSim(v1, v2);
    std.debug.print("cosine={d}\n", .{cosine});

    v.deinit();
}

test "compare" {
    const test_allocator = std.testing.allocator;
    var v1: @Vector(3, f64) = @Vector(3, f64){ 1, 2, 3 };
    var v2: @Vector(3, f64) = @Vector(3, f64){ 4, 5, 6 };
    var v = Vecs(@Vector(3, f64)).init(test_allocator);
    var cosine = v.cosineSim(v1, v2);
    try v.add(v1);
    try v.add(v2);

    std.debug.print("cosine={d}\n", .{cosine});

    v.deinit();
}
