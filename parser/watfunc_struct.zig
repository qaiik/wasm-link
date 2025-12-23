const std = @import("std");

pub const OperandType = enum {
    i32,
    i64,
    f32,
    f64,
};

fn stringToOperand(s: []const u8) ?OperandType {
    const mapping = .{
        .{ "i32", OperandType.i32 },
        .{ "i64", OperandType.i64 },
        .{ "f32", OperandType.f32 },
        .{ "f64", OperandType.f64 },
    };

    for (mapping) |entry| {
        if (std.mem.eql(u8, s, entry[0])) return entry[1];
    }
    return null;
}

pub const WatFunction = struct {
    exported: bool,
    internal_name: []const u8, // heap-allocated string
    params: []OperandType, // heap-allocated array
    return_type: ?OperandType,
    body: [][]const u8, // heap-allocated array of heap-allocated slices

    /// Initialize a WatFunction with all heap allocations
    pub fn init(
        allocator: *std.mem.Allocator,
        name: []const u8,
        params: []OperandType,
        return_type: ?OperandType,
        body: [][]const u8,
    ) !WatFunction {
        // Heap copy of the internal name
        const name_heap = try allocator.alloc(u8, name.len);
        std.mem.copy(u8, name_heap, name);

        // Heap copy of the params
        const params_heap = try allocator.alloc(OperandType, params.len);
        std.mem.copy(OperandType, params_heap, params);

        // Heap copy of the body outer slice
        const body_heap = try allocator.alloc([]const u8, body.len);
        for (body, 0..) |line, i| {
            // Allocate each inner slice on the heap
            const line_heap = try allocator.alloc(u8, line.len);
            std.mem.copy(u8, line_heap, line);
            body_heap[i] = line_heap;
        }

        return WatFunction{
            .exported = false,
            .internal_name = name_heap,
            .params = params_heap,
            .return_type = return_type,
            .body = body_heap,
        };
    }

    /// Free all heap allocations
    pub fn deinit(self: *WatFunction, allocator: *std.mem.Allocator) void {
        // Free each line in the body
        for (self.body) |line| {
            allocator.free(line);
        }
        allocator.free(self.body);
        allocator.free(self.params);
        allocator.free(self.internal_name);
    }
};
