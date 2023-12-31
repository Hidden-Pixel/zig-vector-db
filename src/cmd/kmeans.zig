const std = @import("std");
const L = @import("list.zig");

pub fn VecStore(comptime T: type) type {
    return struct {
        const This = @This();
        vectors: std.ArrayList(T),
        allocator: *std.mem.Allocator,
        kmeans_groups: L.LinkedList(T),

        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .vectors = std.ArrayList(T).init(allocator.*),
                .kmeans_groups = L.LinkedList(T).init(allocator),
            };
        }

        pub fn dotProduct(self: *This, v1: T, v2: T) f32 {
            _ = self;
            return @as(f32, @floatCast(@reduce(.Add, v1 * v2)));
        }

        pub fn distance(self: *This, v1: T, v2: T) f32 {
            var x: T = v2 - v1;
            return magnitude(self, x);
        }

        pub fn magnitude(self: *This, v1: T) f32 {
            _ = self;
            var sum = @as(f32, @floatCast(@reduce(.Add, v1 * v1)));
            var sqrt_sum = Q_sqrt(sum);
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
            _ = meta;
            try self.vectors.append(v);
        }

        pub fn calculateCentroid(self: *This, cluster: std.ArrayList(T)) T {
            _ = self;
            var n: T = undefined;
            for (cluster.items) |point| {
                n += point;
            }

            const result: T = @splat(@floatFromInt(cluster.items.len));
            return n / result;
        }

        pub fn deinit(self: *This) void {
            self.kmeans_groups.removeAll();
            self.vectors.deinit();
        }

        // TODO:(dean) This is a terrible function - clean it up sometime.
        pub fn pickRandomVectors(self: *This, comptime num_clusters: usize) ![num_clusters]T {
            var returns: [num_clusters]T = undefined;
            var x: u32 = 0;
            var rnd_vecs: std.ArrayList(T) = std.ArrayList(T).init(self.allocator.*);
            var randomIndices = std.AutoHashMap(usize, bool).init(self.allocator.*);
            defer randomIndices.deinit();
            defer rnd_vecs.deinit();
            while (x < num_clusters) {
                var idx: usize = 0;
                var n: usize = std.crypto.random.intRangeAtMost(usize, 0, self.vectors.items.len - 1);

                idx = n % self.vectors.items.len;
                if (randomIndices.get(n) == null) {
                    try randomIndices.put(n, true);
                    try rnd_vecs.append(self.vectors.items[n]);
                    x += 1;
                }
            }

            for (rnd_vecs.items, 0..) |item, i| {
                returns[i] = item;
            }
            return returns;
        }

        // k is the number of clusters to make
        pub fn kmeans(self: *This, comptime k: usize, epsilon: f32) !void {
            var alloc = self.allocator.*;

            // centroids and newCentroids are are lists for the number of clusters.
            // we have two because we swap from new to old and recalculate.
            // these could probably be fix sized arrays.
            var centroids = std.ArrayList(T).init(alloc);
            var newCentroids = std.ArrayList(T).init(alloc);

            // create clusters clusters is a list of centroids to a list of vectors (both are vector types)
            var clusters: std.ArrayList(std.ArrayList(T)) = std.ArrayList(std.ArrayList(T)).init(alloc);

            // clean ups
            defer clusters.deinit();
            defer centroids.deinit();
            defer newCentroids.deinit();

            // this seens our kmeans clusters. we pick existing vectors randomly
            // and try then as clusters since this is unsupervised in a sense.
            var rnd_vector_seeds: [k]T = self.pickRandomVectors(k) catch |err| {
                std.log.err("error picking random seed vectors {any}\n", .{err});
                return;
            };

            for (rnd_vector_seeds) |rnd_vec| {
                try centroids.append(rnd_vec);
            }

            // Initialize the arraylists that will contain the vectors for each centroid
            for (0..k) |_| {
                try clusters.append(std.ArrayList(T).init(alloc));
            }

            // what this loop does is compare every point and see how close it is to every
            // centroid and assign it to the closest one.
            while (true) {
                for (self.vectors.items) |vec| {
                    var belongsTo: usize = 0; // the index of the cluster we assign the vector to
                    var minDist: f32 = std.math.inf(f32);
                    for (centroids.items, 0..) |centroid, i| {
                        var dist: f32 = distance(self, vec, centroid);
                        if (dist < minDist) {
                            minDist = dist;
                            belongsTo = i;
                        }
                    }
                    try clusters.items[belongsTo].append(vec);
                }

                for (clusters.items) |cluster| {
                    var centroid_for_cluster = self.calculateCentroid(cluster);
                    try newCentroids.append(centroid_for_cluster);
                }

                var moved: bool = false;
                for (centroids.items, newCentroids.items) |old, new| {
                    if (self.distance(old, new) > epsilon) {
                        moved = true;
                        break;
                    }
                }

                // if we did not move, then we have good enough centroids
                // were done so clean up.
                if (!moved) {
                    for (centroids.items, clusters.items) |centroid, clusters_items| {
                        try self.kmeans_groups.append(centroid, clusters_items);
                    }

                    return;
                }

                // copy over the newly calculated centroids into the main centroids
                // collection
                centroids.clearRetainingCapacity();
                for (newCentroids.items) |item| {
                    try centroids.append(item);
                }
                newCentroids.clearRetainingCapacity();

                // clean up all clusters as well since we are going to re-calculate
                // them all on the next loop
                for (clusters.items) |*c| {
                    c.clearRetainingCapacity();
                }
            }
        }
    };
}

test "allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    std.debug.print("\n", .{});
    var allocator = arena.allocator();

    var t = std.time.milliTimestamp();
    const DIMS: usize = 2;
    const GROUPS: usize = 3;

    var v = VecStore(@Vector(DIMS, f32)).init(&allocator);
    for (0..50) |_| {
        var vec: @Vector(DIMS, f32) = generateRandomVectorf32(DIMS);
        try v.add(vec, "");
    }
    try v.kmeans(GROUPS, 0.01);
    var end = std.time.milliTimestamp();
    std.debug.print("kmeans time: {d}ms\n", .{end - t});
    v.kmeans_groups.print();
    v.deinit();
}

test "larger kmeans" {
    var t = std.time.milliTimestamp();
    const DIMS: usize = 512;
    const GROUPS: usize = 32;
    var test_allocator = std.testing.allocator;

    var v = VecStore(@Vector(DIMS, f32)).init(&test_allocator);
    for (0..5000) |_| {
        var vec: @Vector(DIMS, f32) = generateRandomVectorf32(DIMS);
        try v.add(vec, "");
    }
    try v.kmeans(GROUPS, 0.01);
    var end = std.time.milliTimestamp();
    std.debug.print("kmeans time: {d}ms\n", .{end - t});
    // v.kmeans_groups.print();
    v.deinit();
}

test "kmeans 3 groups 2 dims" {
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    try v.add(@Vector(2, f32){ 1, 2 }, "meta");
    try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
    try v.add(@Vector(2, f32){ 2, 2 }, "meta");

    try v.add(@Vector(2, f32){ 20, 24 }, "meta");
    try v.add(@Vector(2, f32){ 19, 14 }, "meta");
    try v.add(@Vector(2, f32){ 23, 22 }, "meta");

    try v.add(@Vector(2, f32){ 8, 8 }, "meta");
    try v.add(@Vector(2, f32){ 8, 9 }, "meta");
    try v.add(@Vector(2, f32){ 9, 11 }, "meta");
    try v.kmeans(3, 0.00001);
    v.kmeans_groups.print();
    v.deinit();
}

test "kmeans 2 groups 2 dims" {
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    try v.add(@Vector(2, f32){ 1, 2 }, "meta");
    try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
    try v.add(@Vector(2, f32){ 2, 2 }, "meta");

    try v.add(@Vector(2, f32){ 8, 8 }, "meta");
    try v.add(@Vector(2, f32){ 8, 9 }, "meta");
    try v.add(@Vector(2, f32){ 9, 11 }, "meta");
    try v.kmeans(2, 0.01);
    v.kmeans_groups.print();
    v.deinit();
}

test "kmeans 2 groups 3 dims" {
    const dims: usize = 3;
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(dims, f32)).init(&test_allocator);
    try v.add(@Vector(dims, f32){ 1, 2, 3 }, "meta");
    try v.add(@Vector(dims, f32){ 1.5, 1.8, 2.2 }, "meta");
    try v.add(@Vector(dims, f32){ 2, 2, 3 }, "meta");

    try v.add(@Vector(dims, f32){ 8, 8, 9 }, "meta");
    try v.add(@Vector(dims, f32){ 8, 9, 10 }, "meta");
    try v.add(@Vector(dims, f32){ 9, 11, 13 }, "meta");
    try v.kmeans(2, 0.001);
    v.kmeans_groups.print();
    v.deinit();
}
//
// test "centroid mappings" {
//     var test_allocator = std.testing.allocator;
//     var vs = VecStore(@Vector(2, f32)).init(&test_allocator);
//     defer vs.kmeans_groups.removeAll();
//     var centroid = @Vector(2, f32){ 1, 2 };
//     var members = std.ArrayList(@Vector(2, f32)).init(test_allocator);
//     try vs.kmeans_groups.append(centroid, members);
// }
//
// test "get random vectors" {
//     var test_allocator = std.testing.allocator;
//     var v = VecStore(@Vector(2, f32)).init(&test_allocator);
//     try v.add(@Vector(2, f32){ 1, 2 }, "meta");
//     try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
//     try v.add(@Vector(2, f32){ 2, 2 }, "meta");
//
//     try v.add(@Vector(2, f32){ 8, 8 }, "meta");
//     try v.add(@Vector(2, f32){ 8, 9 }, "meta");
//     try v.add(@Vector(2, f32){ 9, 11 }, "meta");
//     var points = try v.pickRandomVectors(2);
//     _ = points;
//     v.vectors.deinit();
// }

fn generateRandomVectorf32(comptime n: usize) [n]f32 {
    var numbers: [n]f32 = undefined;
    var rnd = std.crypto.random;

    for (&numbers) |*val| {
        val.* = rnd.float(f32);
    }
    return numbers;
}
pub fn Q_sqrt(number: f32) f32 {
    var i: i32 = undefined;
    var x2: f32 = undefined;
    var y: f32 = undefined;
    const threehalfs: f32 = 1.5;

    x2 = number * 0.5;
    y = number;
    i = @as(i32, @bitCast(y));
    i = 0x5f3759df - (i >> 1);
    y = @as(f32, @bitCast(i));
    y = y * (threehalfs - (x2 * y * y));

    return 1 / y;
}
test "sqrt 4" {
    var x = Q_sqrt(4);
    std.debug.print("Q_sqrt 4 {d}\n", .{x});
}
test "sqrt 9" {
    var x = Q_sqrt(9);
    std.debug.print("Q_sqrt 9 {d}\n", .{x});
}
test "Q_sqrt" {
    var t = std.time.milliTimestamp();
    for (0..1000000) |i| {
        _ = Q_sqrt(@as(f32, @floatFromInt(i)));
    }
    var end = std.time.milliTimestamp();
    std.debug.print("\ntotal time fast sqrt: {d}\n", .{end - t});

    t = std.time.milliTimestamp();
    for (0..1000000) |i| {
        _ = std.math.sqrt(i);
    }
    end = std.time.milliTimestamp();
    std.debug.print("total time reg sqrt: {d}\n", .{end - t});
}
