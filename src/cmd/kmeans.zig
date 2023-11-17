const std = @import("std");
const linked_list = @import("list.zig");
pub fn VecStore(comptime T: type) type {
    return struct {
        const This = @This();
        vectors: linked_list.LinkedList(T),
        allocator: *std.mem.Allocator,
        pub fn init(allocator: *std.mem.Allocator) This {
            return .{
                .vectors = linked_list.LinkedList(T).init(allocator),
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

        pub fn add(self: *This, v: T, meta: []const u8) !void {
            try self.vectors.add(v, meta);
        }

        // kmeans stuff
        pub fn centroid(self: *This, cluster: std.ArrayList(T)) T {
            _ = self;
            var n: T = undefined;
            for (cluster.items) |point| {
                n += point;
            }

            const result: T = @splat(@floatFromInt(cluster.items.len));
            return n / result;
        }

        pub fn kmeans(self: *This, comptime k: usize, epsilon: f32, comptime vec_dim: usize) !void {
            // TODO: figure out a way to not have to pass in vec_dim

            var alloc = self.allocator.*;
            var centroids = std.ArrayList(T).init(alloc);
            var newCentroids = std.ArrayList(T).init(alloc);
            defer centroids.deinit();
            defer newCentroids.deinit();

            for (0..k) |_| {
                var rvec = generateRandomVectorf32(vec_dim);
                var vec: T = rvec;
                try centroids.append(vec);
            }
            //
            // try centroids.append(@Vector(2, f32){ 8, 9 });
            // try centroids.append(@Vector(2, f32){ 2, 2 });
            var loops: u32 = 0;
            _ = loops;
            while (true) {
                // create clusters clusters is a list of centroids to a list of vectors (both are vector types)
                var clusters = std.ArrayList(std.ArrayList(T)).init(alloc);

                // Initialize the arraylists that will contain the vectors for each centroid
                for (0..k) |_| {
                    try clusters.append(std.ArrayList(T).init(alloc));
                }
                // we traverse the linked list to look at every vector we have so we can assign it to a cluster
                var current_node = self.vectors.head;
                while (current_node) |point| {
                    // find the closest centroid for node (which contains our actual vector)
                    var belongsTo: usize = 0;
                    var minDist: f32 = std.math.inf(f32);
                    for (centroids.items, 0..) |centro, i| {
                        var dist: f32 = distance(self, point.data, centro);
                        std.debug.print("centroid {any} point {any} dist {d}\n", .{ centro, point.data, dist });
                        if (dist < minDist) {
                            minDist = dist;
                            belongsTo = i;
                        }
                    }
                    try clusters.items[belongsTo].append(point.data);
                    current_node = point.next;
                }

                for (clusters.items) |cluster| {
                    try newCentroids.append(self.centroid(cluster));
                }

                var moved: bool = false;
                for (centroids.items, newCentroids.items) |c, i| {
                    if (self.distance(c, i) > epsilon) {
                        moved = true;
                        break;
                    }
                }

                if (!moved) {
                    std.debug.print("Were DON {any}\n", .{centroids.items});
                    for (clusters.items) |c| {
                        c.deinit();
                    }
                    clusters.deinit();
                    return;
                }

                centroids.clearRetainingCapacity();
                for (newCentroids.items) |item| {
                    try centroids.append(item);
                }
                newCentroids.clearRetainingCapacity();

                // loops += 1;
                // if (loops > 1) {
                //     clusters.deinit();
                //     for (clusters.items) |c| {
                //         c.deinit();
                //     }
                //     return;
                // }
                for (clusters.items) |c| {
                    c.deinit();
                }
                clusters.deinit();

                // break;
            }
        }
    };
}
test "kmeans" {
    std.debug.print("\n", .{});
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    try v.add(@Vector(2, f32){ 1, 2 }, "meta");
    // try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
    // try v.add(@Vector(2, f32){ 2, 2 }, "meta");

    // try v.add(@Vector(2, f32){ 8, 8 }, "meta");
    // try v.add(@Vector(2, f32){ 8, 9 }, "meta");
    try v.add(@Vector(2, f32){ 9, 11 }, "meta");
    try v.kmeans(2, 0.01, 2);
    v.vectors.removeAll();
}
fn generateRandomVectorf32(comptime n: usize) [n]f32 {
    var numbers: [n]f32 = undefined;
    var rnd = std.crypto.random;

    for (&numbers) |*val| {
        val.* += rnd.float(f32);
    }
    return numbers;
}
