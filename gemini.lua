-- gemini.lua
-- This file essentially just creates a single object and dies, simular to how humans reproduce just to die.

local https = require("ssl.https") -- luasec
local ltn12 = require("ltn12")
local json = require("dkjson") -- json but in lua

local config = require("config") -- for loading config

local API_KEY = config.GEMINI -- I would prefer only having this used only in this file to reduce attack surface.

if not API_KEY or API_KEY == "" then
    error("Missing GEMINI API key in config.")
end

local MODELS = {
    --"gemini-3.8-flash",
    "gemini-3.6-flash",
    "gemini-3.5-flash-lite"
}

-- Makes one request using a specified model.
local function request_model(model, prompt)

    local url =
        "https://generativelanguage.googleapis.com/v1beta/models/"
        .. model .. ":generateContent"

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

    local result, status_code, headers, status =
        https.request({
            url = url,
            method = "POST",
            timeout = 30,

            headers = {
                ["Content-Type"] = "application/json",
                ["x-goog-api-key"] = API_KEY,
                ["Content-Length"] = tostring(#request_body)
            },

            source = ltn12.source.string(request_body),
            sink = ltn12.sink.table(response_body)
        })

    if not result then
        return nil, "HTTP transport failure: " .. tostring(status_code)
    end

    local response = table.concat(response_body)
    status_code = tonumber(status_code)

    if status_code ~= 200 then
        return nil,
            "HTTP " .. tostring(status_code) .. ": " .. response,
            status_code
    end

    local decoded, _, err = json.decode(response)

    if not decoded then
        return nil, "JSON decoding failed: " .. tostring(err)
    end


    local candidate = decoded.candidates
        and decoded.candidates[1]

    if not candidate or not candidate.content then
        return nil, "Gemini returned no usable candidate: " .. response
    end

    local output = {}

    for _, part in ipairs(candidate.content.parts or {}) do
        if part.text then
            table.insert(output, part.text)
        end
    end

    if #output == 0 then
        return nil, "Gemini returned no text."
    end

    return table.concat(output, "\n")
end

local function ask_gemini(prompt)

    for i, model in ipairs(MODELS) do

        print("Trying model: " .. model)

        local response, err, status_code =
            request_model(model, prompt)

        if response then
            print("Successfully used: " .. model)
            return response, model
        end

        if status_code == 503 then

            print(model .. " unavailable. Trying next model...")

        else

            error(
                "Gemini request failed using "
                .. model .. ":\n" .. tostring(err),
                2
            )

        end
    end

    error(
        "All configured Gemini models are currently unavailable.",
        2
    )
end

return ask_gemini
