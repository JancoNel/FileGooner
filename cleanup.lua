local lfs = require("lfs")

local path_separator = package.config:sub(1, 1)

local function join_path(directory, name)
    if directory:sub(-1) == path_separator then
        return directory .. name
    end
    return directory .. path_separator .. name
end

local function is_empty_directory(path)
    for name in lfs.dir(path) do
        if name ~= "." and name ~= ".." then
            return false
        end
    end

    return true
end

local function clean_children(directory)
    local children = {}
    for name in lfs.dir(directory) do
        if name ~= "." and name ~= ".." then
            table.insert(children, name)
        end
    end

    local removed_count = 0
    for _, name in ipairs(children) do
        local child_path = join_path(directory, name)
        local child_mode = lfs.symlinkattributes(child_path, "mode")

        -- Do not traverse symlinks, even when they point to directories.
        if child_mode == "directory" then
            removed_count = removed_count + clean_children(child_path)

            local empty_after_cleanup = is_empty_directory(child_path)
            if empty_after_cleanup and is_empty_directory(child_path) then
                local removed, err = lfs.rmdir(child_path)
                if not removed then
                    error("Could not remove empty directory " .. child_path .. ": " .. tostring(err), 0)
                end
                removed_count = removed_count + 1
            end
        end
    end

    return removed_count
end

local function clean_empty_directories(root)
    local attributes = lfs.attributes(root)
    if not attributes then
        error("Cleanup root does not exist: " .. root, 0)
    end
    if attributes.mode ~= "directory" then
        error("Cleanup root is not a directory: " .. root, 0)
    end

    return clean_children(root)
end

return clean_empty_directories
