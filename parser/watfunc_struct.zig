const std = @import("std");

pub const OperandType = enum {
    i32,
    i64,
    f32,
    f64,
    None,
};

var _map_initialized: bool = false;
var _operand_map: std.StringHashMap(OperandType) = undefined;

pub fn stringToOperand(s: []const u8) !OperandType {
    if (!_map_initialized) {
        const gpa = std.heap.page_allocator;
        _operand_map = std.StringHashMap(OperandType).init(gpa);

        try _operand_map.put("i32", .i32);
        try _operand_map.put("i64", .i64);
        try _operand_map.put("f32", .f32);
        try _operand_map.put("f64", .f64);

        _map_initialized = true;
    }

    return _operand_map.get(s) orelse OperandType.None;
}

pub fn deinitOperandMap() void {
    if (_map_initialized) {
        _operand_map.deinit();
        _map_initialized = false;
    }
}

pub const WatFunction = struct {
    exported: bool,
    internal_name: []const u8, // heap-allocated string
    params: []OperandType, // heap-allocated array
    return_type: ?OperandType,
    body: [][]const u8, // heap-allocated array of heap-allocated slices
    allocator: *std.mem.Allocator,

    /// Initialize a WatFunction with all heap allocations
    pub fn init(
        allocator: *std.mem.Allocator,
        name: []const u8,
        params: []const OperandType,
        return_type: ?OperandType,
        body: []const []const u8,
    ) !WatFunction {
        const name_heap = try allocator.alloc(u8, name.len);
        @memcpy(name_heap, name);

        const params_heap = try allocator.alloc(OperandType, params.len);

        @memcpy(params_heap, params);

        const body_heap = try allocator.alloc([]const u8, body.len);
        for (body, 0..) |line, i| {
            const line_heap = try allocator.alloc(u8, line.len);
            @memcpy(line_heap, line);
            body_heap[i] = line_heap;
        }

        return WatFunction{
            .allocator = allocator,
            .exported = false,
            .internal_name = name_heap,
            .params = params_heap,
            .return_type = return_type,
            .body = body_heap,
        };
    }

    /// Free all heap allocations
    pub fn deinit(self: *WatFunction) void {
        // Free each line in the body
        var allocator = self.allocator;
        for (self.body) |line| {
            allocator.free(line);
        }
        allocator.free(self.body);
        allocator.free(self.params);
        allocator.free(self.internal_name);
    }
};
