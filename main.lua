-- File gooner
-- Uses gemini API key from environment variable
-- To sort files in spesified directory

local lfs = require("lfs")
local ask_gemini = require("gemini")
local json = require("dkjson")

local function  gooner()
    print("FileGooner executting...")

end

gooner()

local path_separator = package.config:sub(1, 1)

local function normalize_path(path)
    path = path:gsub("/", path_separator)
    path = path:gsub("\\", path_separator)
    path = path:match("^%s*(.-)%s*$")

    local first = path:sub(1, 1)
    local last = path:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
        path = path:sub(2, -2):match("^%s*(.-)%s*$")
    end

    return path
end

local function get_target_directory()
    local parts = {}
    local index = 1

    while index <= #arg do
        local value = arg[index]
        if value == "-d" or value == "--dir" or value == "--directory" then
            index = index + 1
            if not arg[index] then
                error("Expected a directory name or path after " .. value, 0)
            end
            table.insert(parts, arg[index])
        elseif value:match("^%-%-dir=") or value:match("^%-%-directory=") then
            table.insert(parts, value:match("^%-%-[^=]+=(.*)$"))
        else
            table.insert(parts, value)
        end
        index = index + 1
    end

    local input
    if #parts > 0 then
        input = table.concat(parts, " ")
    else
        io.write("Directory to organize (default: test_dir): ")
        input = io.read("*l")
        if not input or input:match("^%s*$") then
            input = "test_dir"
        end
    end

    local directory = normalize_path(input)
    local attributes = lfs.attributes(directory)
    if not attributes then
        error("Directory does not exist: " .. directory, 0)
    end
    if attributes.mode ~= "directory" then
        error("Path is not a directory: " .. directory, 0)
    end

    return directory
end

local function join_path(directory, name)
    if directory:sub(-1) == path_separator then
        return directory .. name
    end
    return directory .. path_separator .. name
end

local target_directory = get_target_directory()
print("Organizing directory: " .. target_directory)

local files = {}

local function scan_directory(dir) -- This algo is so cool , I kinda want to store it somewhere cool in my notes
    for file in lfs.dir(dir) do
        if file ~= "." and file ~= ".." then
            local path = join_path(dir, file)
            table.insert(files, path)

            if lfs.attributes(path, "mode") == "directory" then
                scan_directory(path)
            end
        end
    end
end

scan_directory(target_directory)

-- Convert files into pwetty json stwing
local json_string = json.encode(files, {indent = true})

local response =
    ask_gemini(
    [[
You are a file-organization assistant. I will provide a JSON array of paths
belonging to files and directories inside a target directory.

Suggest a clearer, sensible directory structure by proposing file moves.
Do not rename files. Do not delete anything. Do not move directories.

Return ONLY valid JSON: an array of objects, each with exactly these fields:
- "source": the existing relative path of a file
- "destination": its proposed new relative path

Rules:
- Every source must be one of the paths I provided.
- Every destination must remain inside the target directory.
- Do not propose moving a file to its current location.
- Do not propose multiple destinations for the same source.
- You may propose new directories, but do not include directory-creation
  instructions; the program will create needed directories.
- Prefer a small number of useful, well-defined categories.
- If no moves are useful, return [].
- Do not include explanations, Markdown fences, or any text outside the JSON.

Here is the file list:
]] ..
        json_string
)

-- print(response)
--print(json_string)

-- Now we need to parse the response and move the files accordingly
local moves, _, err = json.decode(response)

if not moves then
    error("Failed to decode Gemini response: " .. tostring(err))
end

-- move ops
for _, move in ipairs(moves) do
    local source = normalize_path(move.source)
    local destination = normalize_path(move.destination)

    -- Input validition XD
    if lfs.attributes(source, "mode") ~= "file" then
        print("Source file does not exist: " .. source)
        goto continue
    end


    local dest_dir = destination:match("^(.*)[/\\][^/\\]+$")
    if dest_dir and lfs.attributes(dest_dir, "mode") ~= "directory" then
        lfs.mkdir(dest_dir)
    end

    -- Move the file
    local success, err_msg = os.rename(source, destination)
    if not success then
        print("Failed to move file from " .. source .. " to " .. destination .. ": " .. tostring(err_msg))
    else
        print("Moved file from " .. source .. " to " .. destination)
    end

    ::continue::
end