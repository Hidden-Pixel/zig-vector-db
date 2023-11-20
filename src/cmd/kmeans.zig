const std = @import("std");
pub fn VecStore(comptime T: type) type {
    return struct {
        const This = @This();
        vectors: std.ArrayList(T),
        allocator: *std.mem.Allocator,
        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .vectors = std.ArrayList(T).init(allocator.*),
                .allocator = allocator,
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

        pub fn add(self: *This, v: T ) !void {
            try self.vectors.append(v);
        }

        // kmeans stuff
        pub fn calc_centroid(self: *This, cluster: std.ArrayList(T)) T {
            _ = self;
            var n: T = undefined;
            for (cluster.items) |point| {
                n += point;
            }

            const result: T = @splat(@floatFromInt(cluster.items.len));
            return n / result;
        }

        pub fn pickRandomVectors(self: *This, comptime k: usize) ![k]T {
            var returns: [k]T = undefined;
            var x: u32 = 0;
            var rnd_vecs: std.ArrayList(T) = std.ArrayList(T).init(self.allocator.*);
            var randomIndices = std.AutoHashMap(usize, bool).init(self.allocator.*);
            defer randomIndices.deinit();
            defer rnd_vecs.deinit();
            while (x < k) {
                var idx: usize = 0;
                var n: usize = std.crypto.random.intRangeAtMost(usize, 0, self.vectors.items.len - 1);

                idx = n % self.vectors.items.len;
                if (randomIndices.get(n) == null) {
                    try randomIndices.put(n, true);
                    std.debug.print("Choosing: {any}\n", .{self.vectors.items[n]});
                    try rnd_vecs.append(self.vectors.items[n]);
                    x += 1;
                }
            }

            for (rnd_vecs.items, 0..) |item, i| {
                returns[i] = item;
            }
            return returns;
        }

        pub fn kmeans(self: *This, comptime k: usize, epsilon: f32) !void {
            var alloc = self.allocator.*;
            var centroids = std.ArrayList(T).init(alloc);
            var newCentroids = std.ArrayList(T).init(alloc);
            // create clusters clusters is a list of centroids to a list of vectors (both are vector types)
            var clusters: std.ArrayList(std.ArrayList(T)) = std.ArrayList(std.ArrayList(T)).init(alloc);
            defer clusters.deinit();
            defer centroids.deinit();
            defer newCentroids.deinit();

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
            while (true) {
                // we traverse the linked list to look at every vector we have so we can assign it to a cluster
                for (self.vectors.items) |vec| {
                    // find the closest centroid for node (which contains our actual vector)
                    var belongsTo: usize = 0;
                    var minDist: f32 = std.math.inf(f32);
                    for (centroids.items, 0..) |centroid, idx| {
                        var dist: f32 = distance(self, vec, centroid);
                        if (dist < minDist) {
                            minDist = dist;
                            belongsTo = idx;
                        }
                    }
                    try clusters.items[belongsTo].append(vec);
                }

                for (clusters.items) |cluster| {
                    try newCentroids.append(self.calc_centroid(cluster));
                }

                var moved: bool = false;
                for (centroids.items, newCentroids.items) |old, new| {
                    if (self.distance(old, new) > epsilon) {
                        moved = true;
                        break;
                    }
                }

                // if we did not move, then we have good enough centroids
                // were done.
                if (!moved) {
                    std.debug.print("Centroids: {any}\n", .{centroids.items});
                    for (clusters.items) |*c| {
                        c.deinit();
                    }
                    std.debug.print("\n", .{});
                    return;
                }

                centroids.clearRetainingCapacity();
                for (newCentroids.items) |item| {
                    try centroids.append(item);
                }
                newCentroids.clearRetainingCapacity();

                for (clusters.items) |*c| {
                    c.clearRetainingCapacity();
                }
            }
        }
    };
}

test "kmeans" {
    std.debug.print("\n", .{});
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    try v.add(@Vector(2, f32){ 1, 2 }, "meta");
    try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
    try v.add(@Vector(2, f32){ 2, 2 }, "meta");

    try v.add(@Vector(2, f32){ 8, 8 }, "meta");
    try v.add(@Vector(2, f32){ 8, 9 }, "meta");
    try v.add(@Vector(2, f32){ 9, 11 }, "meta");
    try v.kmeans(2, 0.001);
    v.vectors.deinit();
}

fn generateRandomVectorf32(comptime n: usize) [n]f32 {
    var numbers: [n]f32 = undefined;
    var rnd = std.crypto.random;

    for (numbers) |val| {
        val += rnd.float(f32);
    }
    return numbers;
}

test "get random vectors" {
    std.debug.print("\n", .{});
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    try v.add(@Vector(2, f32){ 1, 2 }, "meta");
    try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
    try v.add(@Vector(2, f32){ 2, 2 }, "meta");

    try v.add(@Vector(2, f32){ 8, 8 }, "meta");
    try v.add(@Vector(2, f32){ 8, 9 }, "meta");
    try v.add(@Vector(2, f32){ 9, 11 }, "meta");
    _ = try v.pickRandomVectors(2);
    v.vectors.deinit();
}
