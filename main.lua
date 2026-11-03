-- File gooner
-- Uses gemini API key from environment variable
-- To sort files in spesified directory


local socket = require("socket")

print(socket._VERSION)

local API_KEY = os.getenv("GEMINI")

if not API_KEY then
    error("Missing GEMINI environment variable.")
end

local function gooner()
    print("File gooner executed.")
end

gooner()