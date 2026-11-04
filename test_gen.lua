-- Generates a directory full of dummy files for the program to test.
-- Usage: lua test_gen.lua [target_directory]

local lfs = package.preload and package.preload.lfs or require("lfs")

local function is_dir(path)
    local mode = lfs and lfs.attributes(path, "mode")
    return mode == "directory"
end

local function ensure_dir(path)
    if path == "" or path == "." then
        return
    end

    if is_dir(path) then
        return
    end

    local parent = path:match("^(.*)[/\\]")
    if parent and parent ~= path then
        ensure_dir(parent)
    end

---@diagnostic disable-next-line: unbalanced-assignments
    local ok, err = lfs and lfs.mkdir(path)
    if not ok then
        if err and err:match("already exists") then
            return
        end

        local command = 'mkdir "' .. path:gsub('"', '\\"') .. '" 2>nul'
        os.execute(command)
    end
end

local function write_file(path, content)
    local dir = path:match("^(.*)[/\\]")
    if dir then
        ensure_dir(dir)
    end

    local file = assert(io.open(path, "wb"))
    file:write(content)
    file:close()
end

local function add_text_file(root, relative_path, content)
    write_file(root .. "\\" .. relative_path:gsub("/", "\\"), content)
end

local function fill_directory(root)
    ensure_dir(root)

    local files = {
        "README.md",
        "notes.txt",
        "todo.md",
        "budget.csv",
        "logs/app.log",
        "logs/error.log",
        "images/cover.png",
        "images/profile.jpg",
        "images/gallery/scan-01.png",
        "images/gallery/scan-02.jpg",
        "music/playlist.txt",
        "videos/demo.mp4",
        "code/main.lua",
        "code/tools/util.lua",
        "code/python/cleanup.py",
        "code/python/report.py",
        "data/users.json",
        "data/settings.yaml",
        "data/metrics.csv",
        "downloads/archive.zip",
        "downloads/setup.tar.gz",
        "docs/guide.md",
        "docs/meeting-notes.txt",
        "misc/random.bin",
        "misc/hello.txt"
    }

    local content_by_name = {
        ["README.md"] = "# Test Project\n\nThis directory is meant to exercise the file organizer.\n",
        ["notes.txt"] = "Remember to back up the project before making large refactors.\n",
        ["todo.md"] = "- [ ] Review build scripts\n- [ ] Update docs\n- [ ] Archive old files\n",
        ["budget.csv"] = "month,spent,notes\njan,1250,launch\nfeb,980,marketing\nmar,1100,team\n",
        ["logs/app.log"] = "INFO startup\nINFO loading config\nWARN cache miss\n",
        ["logs/error.log"] = "ERROR failed to load plugin\nERROR retrying\n",
        ["images/cover.png"] = "PNG placeholder\n",
        ["images/profile.jpg"] = "JPEG placeholder\n",
        ["images/gallery/scan-01.png"] = "PNG scan placeholder\n",
        ["images/gallery/scan-02.jpg"] = "JPEG scan placeholder\n",
        ["music/playlist.txt"] = "track-01.mp3\ntrack-02.mp3\ntrack-03.mp3\n",
        ["videos/demo.mp4"] = "MP4 placeholder content\n",
        ["code/main.lua"] = "local message = 'hello from the test fixture'\nprint(message)\n",
        ["code/tools/util.lua"] = "local function helper(value)\n  return value .. ' processed'\nend\n\nreturn helper\n",
        ["code/python/cleanup.py"] = "def cleanup(path):\n    return path.strip()\n",
        ["code/python/report.py"] = "from pathlib import Path\n\nprint('report')\n",
        ["data/users.json"] = '{\n  "users": [\n    {"id": 1, "name": "Ada"},\n    {"id": 2, "name": "Linus"}\n  ]\n}\n',
        ["data/settings.yaml"] = "theme: dark\nlang: en\neditor: vscode\n",
        ["data/metrics.csv"] = "date,requests,errors\n2024-01-01,300,4\n2024-01-02,420,7\n",
        ["downloads/archive.zip"] = "zip placeholder bytes\n",
        ["downloads/setup.tar.gz"] = "tar.gz placeholder bytes\n",
        ["docs/guide.md"] = "# Guide\n\nUse the project setup instructions in this repo.\n",
        ["docs/meeting-notes.txt"] = "Agenda\n- kickoff\n- planning\n- review\n",
        ["misc/random.bin"] = string.char(0, 23, 67, 89, 255, 1, 3, 8),
        ["misc/hello.txt"] = "hello from a test fixture\n"
    }

    for _, relative_name in ipairs(files) do
        local content = content_by_name[relative_name] or ("dummy content for " .. relative_name .. "\n")
        add_text_file(root, relative_name, content)
    end

    local extra_dir = root .. "\\nested\\deep\\folder"
    ensure_dir(extra_dir)
    add_text_file(root, "nested/deep/folder/extra.txt", "This file sits deep in a nested directory.\n")
end

local target = arg[1] or "test_dir"
fill_directory(target)
print("Created dummy test directory at: " .. target)
