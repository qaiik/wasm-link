const std = @import("std");
const MustFree_Collect = @import("../util/qol.zig").collect;

pub const FnBodyPtr = struct {
    start_line: usize,
    end_line: usize,
};

pub const FnParseError = error{
    UnexpectedEndOfFile,
    NestedFunctionDetected,
};

pub fn find_funcs(source: []const u8, allocator: std.mem.Allocator) ![]FnBodyPtr {
    var lines = try MustFree_Collect([]const u8, std.mem.splitAny(u8, source, "\n"));
    var functions = std.array_list.Managed(FnBodyPtr).init(allocator);

    var line_index: usize = 0;
    while (line_index < lines.items.len) : (line_index += 1) {
        const line = lines.items[line_index];

        // Ignore fn after a semicolon
        const semicolon_pos = std.mem.indexOf(u8, line, ";");
        const fn_pos = std.mem.indexOf(u8, line, "fn");
        const export_fn_pos = std.mem.indexOf(u8, line, "export fn");

        const is_fn_line =
            ((fn_pos != null and (semicolon_pos == null or fn_pos.? < semicolon_pos.?)) or
                (export_fn_pos != null and (semicolon_pos == null or export_fn_pos.? < semicolon_pos.?))) and
            (std.mem.startsWith(u8, line, "fn") or std.mem.startsWith(u8, line, "export fn"));

        if (is_fn_line) {
            const start_line = line_index;
            var brace_count: usize = 0;
            var found_opening: bool = false;

            while (line_index < lines.items.len) : (line_index += 1) {
                const l = lines.items[line_index];

                for (l) |c| {
                    if (c == '{') {
                        brace_count += 1;
                        found_opening = true;
                    } else if (c == '}') {
                        if (brace_count == 0) break; // unmatched closing, stop
                        brace_count -= 1;
                        if (brace_count == 0 and found_opening) break;
                    }
                }

                // We no longer treat fn inside braces as an error
                if (found_opening and brace_count == 0) break;
            }

            if (!found_opening or brace_count != 0) {
                std.debug.print("Unexpected end of file at line {d}: {s}\n", .{ line_index, line });
                return FnParseError.UnexpectedEndOfFile;
            }

            try functions.append(FnBodyPtr{
                .start_line = start_line,
                .end_line = line_index,
            });
        }
    }

    const result = try allocator.alloc(FnBodyPtr, functions.items.len);
    std.mem.copyForwards(FnBodyPtr, result, functions.items);
    lines.deinit();
    return result;
}
