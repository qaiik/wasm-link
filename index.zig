const std = @import("std");
const print = @import("std").debug.print;
const PFDL = @import("./parser/parse_fmt.zig").ParseFnDeclarationLine;

pub fn main() !void {
    // var allocator = std.heap.page_allocator;
    // var ts = @import("./parser/parse_fmt.zig").ParseFnDeclarationLine(&allocator, "export fn hi i32 i32");
    // print("{}\n", .{try ts});
    // ts.deinit();
    // var a = @import("./util/array.zig").array(u8);
    // try a.append(5);
    // print("{}\n", .{a.items[0]});
    // defer a.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var a = gpa.allocator();

    var b = try PFDL(&a, "export fn add x i32 i32 ->");
    defer b.deinit();
    print("{}\n", .{b});
}
