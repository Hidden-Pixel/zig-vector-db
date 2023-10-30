const std = @import("std");

const cosineSim = struct {};

pub fn CosineSim(comptime T: type) type {
    _ = T;
    return struct {
        const This = @This();
    };
}
pub fn asdf(v1: @Vector(3, u32), v2: @Vector(3, u32)) @Vector(3, u32) {
    var sum: f64 = undefined;

    _ = sum;
    return v1 * v2;
}

test "vec" {
    const a = @Vector(3, u32){ 1, 2, 3 };
    const b = @Vector(3, u32){ 4, 5, 6 };

    var p = asdf(a, b);
    std.debug.print("{any}\n", .{@TypeOf(b)});
    std.debug.print("product {any}\n", .{p});

    for (p) |element| {
        _ = element;
    }
}

// func dotProduct(v1, v2 []float64) float64 {
// 	var sum float64
// 	for i := 0; i < len(v1); i++ {
// 		sum += v1[i] * v2[i]
// 	}
// 	return sum
// }
