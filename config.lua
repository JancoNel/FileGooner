
local config = {}

local file = io.open(".env", "r")

if not file then
    error("Could not find .env file")
end

for line in file:lines() do
    -- Ignore comments and empty lines
    if not line:match("^%s*#") and line:match("%S") then
        local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")

        if key then
            -- Remove optional surrounding quotes
            value = value:gsub('^"(.*)"$', "%1")
            value = value:gsub("^'(.*)'$", "%1")

            config[key] = value
        end
    end
end

file:close()

return config
