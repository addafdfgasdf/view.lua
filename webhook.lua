local DeleteWebhook = false -- true || false
local localPlayer = game:GetService("Players").LocalPlayer
local request = http_request or request or syn.request

if not request then
    warn("No supported request function found!")
    return
end

local filename = string.format("log %s %.2f.txt", localPlayer.UserId, tick())

-- Сохраняем оригинал ОДИН РАЗ
local originalRequest = request

-- Единый хук
request = hookfunction(request, newcclosure(function(data)
    local url = tostring(data.Url or "")
    local lowerUrl = url:lower()

    -- Проверяем, является ли запрос к Discord webhook
    if lowerUrl:find("discord") and (lowerUrl:find("webhook") or lowerUrl:find("websec")) then
        rconsolename("Webhook Protector - sufi#1337")
        rconsoleprint("@@RED@@Webhook blocked: " .. url .. "\n")
        rconsoleprint("Method: " .. tostring(data.Method or "GET") .. "\n")
        rconsoleprint("Body: " .. tostring(data.Body or "nil") .. "\n@@RESET@@")

        -- Сохраняем лог
        local logContent = ("Webhook: %s\nMethod: %s\nData Sent: %s"):format(
            url,
            tostring(data.Method or "GET"),
            tostring(data.Body or "nil")
        )
        writefile(filename, logContent)
        rconsoleinfo("Dump saved to: " .. filename)

        if DeleteWebhook then
            -- Пытаемся удалить вебхук
            rconsoleprint("@@YELLOW@@Attempting to DELETE webhook...\n@@RESET@@")
            local deleteSuccess = pcall(function()
                originalRequest({
                    Url = url,
                    Method = "DELETE",
                    Headers = { ["Content-Type"] = "application/json" }
                })
            end)
            if deleteSuccess then
                rconsoleinfo("Webhook deletion request sent.")
            else
                rconsolewarn("Failed to send DELETE request.")
            end
        end

        -- Блокируем исходный запрос
        return -- НЕ вызываем originalRequest => запрос не отправляется
    end

    -- Если не вебхук — пропускаем
    return originalRequest(data)
end))

print("✅ Webhook protector loaded (by pinklass)")
