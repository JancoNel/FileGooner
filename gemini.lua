-- Basically consutrcts Gemini API object and dies

local https = require("ssl.https") -- Luasec
local ltn12 = require("ltn12")
local json = require("dkjson") -- Lua json

local config = require("config") -- Hopefully the only time config will be used

local API_KEY = config.GEMINI
local MODEL = "gemini-3.8-flash"

if not API_KEY then
    error("Missing GEMINI environment variable.")
end

local function ask_gemini(prompt)

    local url =
        "https://generativelanguage.googleapis.com/v1beta/models/"
        .. MODEL .. ":generateContent"

    -- Construct the request body
    local payload = {
        contents = {
            {
                parts = {
                    { text = prompt }
                }
            }
        }
    }

    local request_body = json.encode(payload)
    local response_body = {}

    -- Send HTTPS POST request
    local result, status_code, headers, status = https.request({
        url = url,
        method = "POST",

        headers = {
            ["Content-Type"] = "application/json",
            ["x-goog-api-key"] = API_KEY,
            ["Content-Length"] = tostring(#request_body)
        },

        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body)
    })

    if not result then
        error("HTTP request failed: " .. tostring(status_code))
    end

    local response = table.concat(response_body)

    if status_code ~= 200 then
        error("Gemini returned HTTP " .. tostring(status_code)
            .. "\n" .. response)
    end

    -- Decode JSON response
    local decoded, _, err = json.decode(response)

    if not decoded then
        error("JSON decoding failed: " .. tostring(err))
    end

    -- Extract generated text
    local text =
        decoded.candidates[1].content.parts[1].text

    return text
end

return ask_gemini
