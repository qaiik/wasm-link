const std = @import("std");
const print = @import("std").debug.print;
pub fn main() !void {
    // var allocator = std.heap.page_allocator;
    // var ts = @import("./parser/parse_fmt.zig").ParseFnDeclarationLine(&allocator, "export fn hi i32 i32");
    // print("{}\n", .{try ts});
    // ts.deinit();
    var a = @import("./util/array.zig").array(u8);
    try a.append(5);
    print("{}\n", .{a.items[0]});
    defer a.deinit();
}
