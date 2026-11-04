# FileGooner

FileGooner uses Gemini to suggest a clearer organization for files in a
directory, then applies the returned file moves. It is a small Lua alternative
to manually sorting files or paying for an organizing agent.

## Requirements

- Lua
- LuaFileSystem (`lfs`)
- LuaSec (`ssl.https`)
- `dkjson`
- A Gemini API key

Create a `.env` file in the project directory with your key:

```text
GEMINI=your_gemini_api_key
```

Keep `.env` private; do not commit your API key.

## Run

Choose the directory with a positional path:

```sh
lua main.lua "C:\Users\you\Downloads"
```


If no path is provided, FileGooner prompts for one and uses `test_dir` if the
input is left blank. Paths with spaces can be quoted; forward or backslashes
are accepted.

## What it does

FileGooner scans the selected directory and its subdirectories, sends the paths
to Gemini, and moves files based on the returned suggestions. It creates
destination directories as needed, then removes empty subdirectories left
behind by the moves. The selected directory itself is not removed, and files
are not deleted.

Review the suggested organization carefully by running FileGooner on a
disposable copy first. File moves are applied automatically.
