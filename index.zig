const std = @import("std");
const PFDL = @import("./parser/parse_fmt.zig").ParseFnDeclarationLine;
const WatFunction = @import("./parser/watfunc_struct.zig").WatFunction;
const deinitOperandMap = @import("./parser/watfunc_struct.zig").deinitOperandMap;

pub fn main() !void {
    const N = 1_000_000;

    // Initialize an arena allocator
    var arena_mem = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_mem.deinit();
    var arena = arena_mem.allocator();

    // Rotating pool of 8 function pointers
    var pool: [8]?*WatFunction = .{ null, null, null, null, null, null, null, null };
    var pool_index: usize = 0;

    const start = std.time.nanoTimestamp();

    for (0..N) |_| {
        const line = "export fn add x i32 i32 -> f32 {";

        // Parse function declaration using arena allocator
        const fn_parsed = try PFDL(&arena, line);

        // Allocate a pointer for the function in the arena
        const fn_ptr = try arena.create(WatFunction);
        fn_ptr.* = fn_parsed;

        // Drop the old function in the pool, if any
        if (pool[pool_index] != null) {
            pool[pool_index].?.deinit();
        }

        // Put new function into the pool
        pool[pool_index] = fn_ptr;
        pool_index = (pool_index + 1) % pool.len;
    }

    const end = std.time.nanoTimestamp();
    const elapsed_ms = @as(u64, (@intCast(end - start))) / 1_000_000;
    std.debug.print("Parsed {d} functions in {d} ms\n", .{ N, elapsed_ms });

    // Clean up remaining functions in the pool
    for (pool) |fn_opt| {
        if (fn_opt != null) fn_opt.?.deinit();
    }

    deinitOperandMap();
}
