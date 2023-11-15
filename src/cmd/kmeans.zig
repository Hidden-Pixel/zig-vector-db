const std = @import("std");
const print = std.debug.print;

fn random() f64 {
    // Implement a random number generator here.
    return 0.0; // Placeholder
}

fn randomInt(max: usize) usize {
    // Implement a random integer generator here.
    return 0; // Placeholder
}

fn distance(a: [*]f64, b: [*]f64, length: usize) f64 {
    var sum: f64 = 0.0;
    for (std.mem.sliceAsBytes(a[0..length])) |value, i| {
        var diff = a[i] - b[i];
        sum += diff * diff;
    }
    return sum;
}

fn assignClusters(vectors: [[]]f64, clusters: [][]f64) void {
    for (vectors) |vector, i| {
        var min_distance = f64.max;
        var best_j = 0;
        for (clusters) |cluster, j| {
            var dist = distance(vector, cluster, vector.len);
            if (dist < min_distance) {
                min_distance = dist;
                best_j = j;
            }
        }
        for (clusters[best_j]) |*center, k| {
            center.* += vector[k];
        }
    }
}

fn adjustClusters(clusters: [][]f64) bool {
    var should_continue = false;
    for (clusters) |*cluster, j| {
        for (cluster.*) |*center, k| {
            var new_center = center.* / 100.0;
            if (std.math.abs(new_center - center.*) > 0.01) {
                should_continue = true;
            }
            center.* = new_center;
        }
    }
    return should_continue;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;
    defer _ = gpa.deinit();

    var vectors = try allocator.alloc([512]f64, 100);
    defer allocator.free(vectors);

    // Initialize vectors
    for (vectors) |*vector| {
        for (vector.*) |*value, i| {
            value.* = random();
        }
    }

    var k = 3;
    var clusters = try allocator.alloc([512]f64, k);
    defer allocator.free(clusters);

    for (clusters) |*cluster| {
        for (cluster.*) |*value, i| {
            value.* = vectors[randomInt(100)][randomInt(512)]; // Assign random center
        }
    }

    while (adjustClusters(clusters)) {
        assignClusters(vectors, clusters);
    }

    for (clusters) |*cluster, i| {
        print("Cluster {d}\n", .{i});
        for (cluster.*) |center, j| {
            print("{d}: {f}\n", .{j, center});
        }
    }
}
