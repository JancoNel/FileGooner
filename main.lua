-- File gooner
-- Uses gemini API key from environment variable
-- To sort files in spesified directory

Luarocks = require("luarocks.loader")

API_KEY = os.getenv("GEMINI")

local function gooner()
    print("File gooner executed.")
end

