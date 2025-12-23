const std = @import("std");
const WatFunction = @import("./watfunc_struct.zig").WatFunction;
const OperandType = @import("watfunc_struct.zig").OperandType;
const stringToOperand = @import("watfunc_struct.zig").stringToOperand;
const array = @import("../util/array.zig").array;
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

pub fn ParseFnDeclarationLine(alc: *std.mem.Allocator, line: []const u8) !WatFunction {
    const spaces_iterator = std.mem.splitAny(u8, line, " ");
    var words_list = try MustFree_Collect([]const u8, spaces_iterator);
    defer words_list.deinit();

    // Determine if exported and starting index
    var ptr: usize = 0;
    var field_exported: bool = false;
    if (std.mem.eql(u8, words_list.items[0], "export")) {
        field_exported = true;
        ptr = 2; // skip "export fn"
    } else if (std.mem.eql(u8, words_list.items[0], "fn")) {
        ptr = 1; // skip "fn"
    } else {
        return FunctionParsingErrors.UnknownFunctionSignature;
    }

    // Function name
    if (ptr >= words_list.items.len) return FunctionParsingErrors.UnknownFunctionSignature;
    const field_name = words_list.items[ptr];
    ptr += 1;

    // Prepare parameter array
    var params = array(ParamStruct);
    defer params.deinit();

    const valid_types = &[_][]const u8{ "i32", "i64", "f32", "f64" };

    while (ptr < words_list.items.len and !std.mem.eql(u8, words_list.items[ptr], "->")) : (ptr += 1) {
        const word = words_list.items[ptr];

        // Check if this word is a type
        var type_value: OperandType = .None;
        for (valid_types) |t| {
            if (std.mem.eql(u8, t, word)) {
                type_value = try stringToOperand(t);
                break;
            }
        }

        if (type_value != .None) {
            // Param is just a type (no name)
            try params.append(ParamStruct{
                .o_type = type_value,
                .name = "",
            });
        } else {
            // Param has a name; next word must be type
            ptr += 1;
            if (ptr >= words_list.items.len) return FunctionParsingErrors.UnknownFunctionSignature;

            const type_word = words_list.items[ptr];
            type_value = .None;
            for (valid_types) |t| {
                if (std.mem.eql(u8, t, type_word)) {
                    type_value = try stringToOperand(t);
                    break;
                }
            }
            if (type_value == .None) return FunctionParsingErrors.UnknownFunctionSignature;

            try params.append(ParamStruct{
                .o_type = type_value,
                .name = word,
            });
        }
    }

    // Return type
    var return_type: ?OperandType = null;
    if (ptr + 1 < words_list.items.len) {
        const ret_word = words_list.items[ptr + 1];
        var type_val: OperandType = .None;
        for (valid_types) |t| {
            if (std.mem.eql(u8, t, ret_word)) {
                type_val = try stringToOperand(t);
                break;
            }
        }
        if (type_val == .None) return FunctionParsingErrors.UnknownFunctionSignature;
        return_type = type_val;
    }

    // Allocate operand types array
    var operand_types = try alc.alloc(OperandType, params.items.len);
    defer alc.free(operand_types);
    for (params.items, 0..) |p, i| {
        operand_types[i] = p.o_type;
    }

    // Build WatFunction
    return try WatFunction.init(
        alc,
        field_name,
        operand_types,
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
