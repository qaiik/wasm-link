const std = @import("std");

pub fn array(comptime T: type) std.array_list.Managed(T) {
    return std.array_list.Managed(T).init(std.heap.page_allocator);
}

pub fn MustFree_Collect(comptime T: type, itr: anytype) !std.array_list.Managed(T) {
    var list = std.array_list.Managed(T).init(std.heap.page_allocator);

    var it = itr; // make a mutable copy of the iterator
    while (true) {
        const item = it.next();
        if (item == null) break;
        _ = try list.append(item.?); // unwrap the optional
    }

    return list;
}
