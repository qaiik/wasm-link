const std = @import("std");
const print = std.debug.print;
const find_funcs = @import("./parser/find_fns.zig").find_funcs;
const FnBodyPtr = @import("./parser/find_fns.zig").FnBodyPtr;
const PFDL = @import("./parser/parse_fmt.zig").PFDL;
const qol = @import("./util/qol.zig");
pub fn main() !void {
    var allocator = std.heap.page_allocator;

    const source =
        "fn first x i32 i32 -> i32 {\n" ++
        "    const x = 1;\n" ++
        "}\n";

    const funcs = try find_funcs(source, allocator);
    defer allocator.free(funcs);

    const array = try qol.collected_split(source, "\n");
    defer array.deinit();
    var wf = try PFDL(allocator, array.items[funcs[0].start_line]);
    defer wf.deinit();
    print("{}\n", .{wf});
    print("{}\n", .{wf.params.items[0]});

    for (funcs) |f| {
        print("Function from line {} to {}\n", .{ f.start_line, f.end_line });
    }
}
