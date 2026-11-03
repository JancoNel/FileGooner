-- File gooner
-- Uses gemini API key from environment variable
-- To sort files in spesified directory

local ask_gemini = require("gemini")

local function gooner()
    print("File gooner executed.")
end

gooner()

local response = ask_gemini(
    "Explain what a Lua table is in one paragraph."
)

print(response)
