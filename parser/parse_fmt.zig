const std = @import("std");
const WatFunction = @import("./watfunc_struct.zig").WatFunction;
const OperandType = @import("watfunc_struct.zig").OperandType;
const stringToOperand = @import("watfunc_struct.zig").stringToOperand;
const array = @import("../util/array.zig");
const MustFree_Collect = @import("../util/array.zig").MustFree_Collect;

pub const FunctionParsingErrors = error{UnknownFunctionSignature};

pub const ParamStruct = struct {
    name: ?[]const u8,
    o_type: OperandType,
};

pub fn contains(haystack: [][]const u8, needle: []const u8) bool {
    for (haystack) |item| {
        if (std.mem.eql(u8, item, needle)) {
            return true;
        }
    }
    return false;
}

pub fn ParseFnDeclarationLine(allocator: *std.mem.Allocator, line: []const u8) !WatFunction {
    const spaces_iterator = std.mem.splitAny(u8, line, " ");
    var words_list = try MustFree_Collect(spaces_iterator);
    defer words_list.deinit();

    var ptr: usize = if (std.mem.eql(u8, words_list[0], "export")) 2 else if (std.mem.eql(u8, words_list[0], "fn")) 1 else 0;
    if (ptr == 0) return FunctionParsingErrors.UnknownFunctionSignature;

    var field_exported: bool = undefined;
    field_exported = (ptr - 1) != 0;

    var field_name: []const u8 = undefined;
    ptr += 1;
    field_name = words_list[ptr];

    const params = array(ParamStruct);
    defer params.deinit();

    while (ptr < words_list.len and !std.mem.eql(u8, words_list[ptr], "->")) : (ptr += 1) {
        // try params.append(ParamStruct{
        //     .o_type = stringToOperand(words_list[ptr]),
        //     name:
        // });

        if (contains(.{ "i32", "i64", "f32", "f64" }, words_list[ptr])) {
            try params.append(ParamStruct{
                .o_type = stringToOperand(words_list[ptr + 1]),
                .name = words_list[ptr],
            });
            ptr += 1;
            continue;
        } else {
            try params.append(ParamStruct{
                .o_type = stringToOperand(words_list[ptr]),
                .name = "",
            });
        }
    }

    const return_type: ?OperandType = null;

    // Build and return the WatFunction with empty body
    return try WatFunction.init(
        allocator,
        field_name,
        params.items,
        return_type,
        &.{}, // empty body
    );
}

// const WatIrParser = struct {
//     source: []const u8,
//     pub fn init(source: []const u8) WatIrParser {
//         return WatIrParser{ .source = source };
//     }

//     pub fn Parse(self: *WatIrParser) ![]WatFunction {
//         const source = self.source;
//         const lines_iterator = std.mem.split(source, "\n");

//         const allocator: *std.mem.Allocator = std.heap.page_allocator;
//         var lines = MustFree_Collect([]const u8, allocator, lines_iterator);
//         defer lines.deinit();

//         //maybe later add a direct equals of 0..9 == "export fn" or 0.2 == "fn" but avoid buffer overflow

//         const WatFunc_allocator = std.heap.page_allocator;
//         var functions = std.ArrayList([]WatFunction).init(WatFunc_allocator);
//         for (0..lines.len) |i| {
//             const line = source[i];
//             if (std.mem.startsWith([]const u8, line, "export fn")) {
//                 try functions.append(WatFunction{
//                     .exported = true,
//                     .internal_name =
//                 });
//             } else if (std.mem.startsWith([]const u8, line, "fn")) {
//                 //dc
//             }
//         }

//         //we need to copy functions into a slice, deinit the arraylist and then return the slice
//         functions.deinit();
//     }
// };
