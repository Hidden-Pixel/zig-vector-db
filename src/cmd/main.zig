const std = @import("std");
const linked_list = @import("list.zig");

const port_num = 3000;

pub fn main() !void {
    var gpa_server = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa = gpa_server.allocator();

    var v = VecStore(@Vector(512, f32)).init(&gpa);
    _ = v;
    var opts: std.net.StreamServer.Options = std.net.StreamServer.Options{
        .reuse_address = true,
    };

    var server: std.net.StreamServer = std.net.StreamServer.init(opts);
    defer server.deinit();

    // start the server listening on 127.0.0.1
    const addr = try std.net.Address.parseIp("0.0.0.0", port_num);
    try server.listen(addr);
    std.log.info("listening on {d}", .{port_num});

    // start up thread pool
    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{ .allocator = gpa, .n_jobs = 12 });
    defer thread_pool.deinit();

    while (true) {
        var conn = try server.accept();
        _ = thread_pool.spawn(handleConnection, .{conn}) catch |err| {
            std.debug.print("{any}", .{err});
        };
    }
}

// const s = "HTTP/1.1 200 OK\nContent-Type: text/plain\nContent-Length: 11\n\nhello world";
fn handleConnection(conn: std.net.StreamServer.Connection) void {
    var buf: [1024 * 1024]u8 = undefined;
    defer conn.stream.close();

    const n: usize = conn.stream.read(&buf) catch |err| {
        std.log.err("{any}", .{err});
        return;
    };

    // TODO: check for EOF
    // route the message to the appropriate handler function
    switch (buf[0]) {
        1 => {
            GetCosineSim(buf[1..n]);
        },
        2 => {
            // some other message type
        },
        else => {
            std.log.err("no such message type", .{});
        },
    }

    std.log.debug("bytes read: {d} {s}", .{ n, std.fmt.fmtSliceHexLower(buf[0..n]) });
}

fn GetCosineSim(buf: []u8) void {
    std.debug.print("{s}\n", .{std.fmt.fmtSliceHexLower(buf)});
    const floatSlice = std.mem.bytesAsSlice(f32, buf[0..]);
    std.debug.print("{any}\n", .{floatSlice});
}

// ========================== Vector store stuff
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
            _ = vec_dim;
            _ = k;
            // TODO: figure out a way to not have to pass in vec_dim
            _ = epsilon;

            var alloc = self.allocator.*;
            var centroids = std.ArrayList(T).init(alloc);
            defer centroids.deinit();

            // for (0..k) |_| {
            //     var rvec = generateRandomVectorf32(vec_dim);
            //     var vec: T = rvec;
            //     try centroids.append(vec);
            // }
            //
            try centroids.append(@Vector(2, f32){ 8, 9 });
            try centroids.append(@Vector(2, f32){ 2, 2 });
            std.debug.print("random centroids seeded: {any}\n", .{centroids.items});

            while (true) {
                // create clusters clusters is a list of centroids to a list of vectors (both are vector types)
                var clusters = std.ArrayList(std.ArrayList(T)).init(alloc);
                // defer clusters.deinit();
                // we traverse the linked list to look at every vector we have so we can assign it to a cluster
                var current_node = self.vectors.head;
                while (current_node) |point| {
                    // find the closest centroid for node (which contains our actual vector)
                    var belongsTo: T = undefined;
                    var minDist: f32 = std.math.inf(f32);
                    for (centroids.items) |centro| {
                        var dist: f32 = distance(self, point.data, centro);
                        std.debug.print("centroid {any} point {any} dist {d}\n", .{ centro, point.data, dist });
                        if (dist < minDist) {
                            minDist = dist;
                            belongsTo = centro;
                        }
                    }

                    var cluster_arr = std.ArrayList(T).init(alloc);
                    try cluster_arr.append(belongsTo);
                    // defer cluster_arr.deinit();
                    try clusters.append(cluster_arr);
                    current_node = point.next;
                }
                // std.debug.print("CLUSTERS {any}\n", .{clusters});

                // clean up for now
                var idx: i32 = 0;
                _ = idx;
                for (clusters.items) |c| {
                    // std.debug.print("CLUSTER {d}\n", .{idx});
                    // idx += 1;
                    c.deinit();
                    for (c.items) |vector| {
                        _ = vector;
                        // std.debug.print("VECTOR {any}\n", .{vector});
                    }
                }
                clusters.deinit();
                break;
            }
            // _ = epsilon;
            // _ = k;

            // var map = std.AutoHashMap(T, std.ArrayList(T)).init(alloc);
            // _ = map;
            // map.put(key: K, value: V)
            // _ = map;
            //
            //
            //
            // std.MultiArrayList(T).
            // var v3: @Vector(2, f32) = @Vector(2, f32){ 3, 3 };
            // _ = v3;
            // var list = std.ArrayList(@Vector(2, f32)).init(alloc);
            // map.put(T, list);
            // return &map;
            // var mikap: std.AutoHashMap = std.AutoHashMap(comptime K: type, comptime V: type)

        }
    };
}

//
test "std.hash_map basic usage" {
    var map = std.AutoHashMap(u32, u32).init(std.testing.allocator);
    defer map.deinit();

    const count = 5;
    var i: u32 = 0;
    var total: u32 = 0;
    while (i < count) : (i += 1) {
        try map.put(i, i);
        total += i;
    }

    var sum: u32 = 0;
    var it = map.iterator();
    while (it.next()) |kv| {
        sum += kv.key_ptr.*;
    }
    try std.testing.expectEqual(total, sum);

    i = 0;
    sum = 0;
    while (i < count) : (i += 1) {
        try std.testing.expectEqual(i, map.get(i).?);
        sum += map.get(i).?;
    }
    try std.testing.expectEqual(total, sum);
}

test "kmeans" {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var allocator = &gpa.allocator();
    //
    //
    //
    //       		{1, 2},
    // {1.5, 1.8},
    // {2, 2},
    // {8, 8},
    // {8, 9},
    // {9, 11},

    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    try v.add(@Vector(2, f32){ 1, 2 }, "meta");
    try v.add(@Vector(2, f32){ 1.5, 1.8 }, "meta");
    try v.add(@Vector(2, f32){ 2, 2 }, "meta");

    try v.add(@Vector(2, f32){ 8, 8 }, "meta");
    try v.add(@Vector(2, f32){ 8, 9 }, "meta");
    try v.add(@Vector(2, f32){ 9, 11 }, "meta");
    try v.kmeans(2, 0.01, 2);
    v.vectors.removeAll();
}

test "distance" {
    var test_allocator = std.testing.allocator;
    var v1: @Vector(2, f32) = @Vector(2, f32){ 2, 7 };
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    var magnitude = v.distance(v1, v1);
    std.debug.print("distance {d} \n", .{magnitude});
    try std.testing.expect(magnitude == 0);

    var b: @Vector(2, f32) = @Vector(2, f32){ 0, 3 };

    var a: @Vector(2, f32) = @Vector(2, f32){ 4, 0 };

    magnitude = v.distance(a, b);
    try std.testing.expect(magnitude == 5);
    std.debug.print("distance {d} \n", .{magnitude});
}

test "centroid" {
    std.debug.print("\n", .{});
    var test_allocator = std.testing.allocator;
    var v1: @Vector(2, f32) = @Vector(2, f32){ 2, 2 };
    var v2: @Vector(2, f32) = @Vector(2, f32){ 1, 1 };
    var v3: @Vector(2, f32) = @Vector(2, f32){ 3, 3 };
    var list = std.ArrayList(@Vector(2, f32)).init(std.testing.allocator);
    var v = VecStore(@Vector(2, f32)).init(&test_allocator);
    // std.debug.print("VEC LEN {any}\n", .{@typeInfo(@TypeOf(v2)).Vector.len});
    // var v = VecStore(@Vector(3, f32)).init(&test_allocator);
    defer list.deinit();
    try list.append(v2);
    try list.append(v1);
    try list.append(v3);
    var centroid = v.centroid(list);
    std.debug.print("centroid {any}\n", .{centroid});

    _ = list.pop();
    _ = list.pop();
    _ = list.pop();
    v1 = @Vector(2, f32){ -1, -2 };
    v2 = @Vector(2, f32){ 0, 0 };
    v3 = @Vector(2, f32){ 1, 2 };
    try list.append(v2);
    try list.append(v1);
    try list.append(v3);
    centroid = v.centroid(list);
    std.debug.print("centroid {any}\n", .{centroid});
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

test "best match f32" {
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(512, f32)).init(&test_allocator);
    defer v.vectors.removeAll();

    for (0..50) |i| {
        var rvec = generateRandomVectorf32(512);
        var vec: @Vector(512, f32) = rvec;
        try v.add(vec, "meta");
        _ = i;
    }

    var search_match = v.vectors.dequeue();
    if (search_match) |sm| {
        var timer = try std.time.Timer.start();
        var best_match = v.get_best_match(sm);
        var elapsed = timer.read();
        std.debug.print("best match {d} {d}\n", .{ elapsed, best_match });
    }
}

test "best match f64" {
    var test_allocator = std.testing.allocator;
    var v = VecStore(@Vector(512, f64)).init(&test_allocator);
    defer v.vectors.removeAll();

    for (0..50) |i| {
        var rvec = generateRandomVectorf32(512);
        var vec: @Vector(512, f64) = rvec;
        try v.add(vec, "meta");
        _ = i;
    }

    var search_match = v.vectors.dequeue();
    if (search_match) |sm| {
        var timer = try std.time.Timer.start();
        var best_match = v.get_best_match(sm);
        var elapsed = timer.read();
        std.debug.print("best match {d} {d}\n", .{ elapsed, best_match });
    }
}
