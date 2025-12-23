const std = @import("std");

pub fn array(comptime T: type) std.array_list.Managed(T) {
    return std.array_list.Managed(T).init(std.heap.page_allocator);
}

pub fn MustFree_Collect(itr: anytype) !std.array_list.Managed(@TypeOf(itr[0])) {
    var list = std.array_list.Managed(@TypeOf(itr[0])).init(&std.heap.page_allocator);

    for (itr) |item| _ = try list.append(item);

    return list;
}
