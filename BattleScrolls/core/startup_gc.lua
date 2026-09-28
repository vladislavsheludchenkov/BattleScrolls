-- Keep this as the LAST manifest entry, after every Lua/XML file and before
-- the engine loads this addon's SavedVariables. Loading leaves dead main
-- chunks and compiler temporaries in the shared Lua heap. Collecting here
-- lets the saved graph reuse their allocator space instead of growing the
-- console Add-On Memory gauge, even when collection itself barely lowers it.
collectgarbage("collect")
