const std = @import("std");
const ParamStruct = @import("./parse_fmt.zig").ParamStruct;

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
    internal_name: []const u8,
    params: std.array_list.Managed(ParamStruct),
    return_type: ?OperandType,
    body: [][]const u8,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        name: []const u8,
        params: std.array_list.Managed(ParamStruct), // caller gives a list
        return_type: ?OperandType,
        body: []const []const u8,
    ) !WatFunction {
        // Copy the function name
        const name_heap = try allocator.alloc(u8, name.len);
        @memcpy(name_heap, name);

        // Copy body lines
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
            .params = params, // just take ownership, no memcpy
            .return_type = return_type,
            .body = body_heap,
        };
    }

    pub fn loadBody(self: *WatFunction, lines: []const []const u8) !void {
        const allocator = self.allocator;
        var body_heap = try allocator.alloc([]const u8, lines.len);

        for (lines, 0..) |line, i| {
            const line_copy = try allocator.alloc(u8, line.len);
            @memcpy(line_copy, line);
            body_heap[i] = line_copy;
        }

        // Free old body if any
        if (self.body.len != 0) {
            for (self.body) |line| allocator.free(line);
            allocator.free(self.body);
        }

        self.body = body_heap;
    }

    pub fn deinit(self: *WatFunction) void {
        var allocator = self.allocator;

        for (self.body) |line| allocator.free(line);
        allocator.free(self.body);

        self.params.deinit();
        allocator.free(self.internal_name);
    }
};
