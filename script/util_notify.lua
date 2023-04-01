local util_notify = {}

-- 消息队列
local msg_queue = {}

local function urlencodeTab(params)
    local msg = {}
    for k, v in pairs(params) do
        table.insert(msg, string.urlEncode(k) .. "=" .. string.urlEncode(v))
        table.insert(msg, "&")
    end
    table.remove(msg)
    return table.concat(msg)
end

local notify = {
    -- 发送到 telegram
    ["telegram"] = function(msg)
        if config.TELEGRAM_PROXY_API == nil or config.TELEGRAM_PROXY_API == "" then
            log.error("util_notify", "未配置 `config.TELEGRAM_PROXY_API`")
            return
        end

        local header = {
            ["content-type"] = "text/plain",
            ["x-disable-web-page-preview"] = "1",
            ["x-chat-id"] = config.TELEGRAM_CHAT_ID or "",
            ["x-token"] = config.TELEGRAM_TOKEN or ""
        }

        log.info("util_notify", "POST", config.TELEGRAM_PROXY_API)
        return util_http.fetch(nil, "POST", config.TELEGRAM_PROXY_API, header, msg)
    end,
    -- 发送到 gotify
    ["gotify"] = function(msg)
        if config.GOTIFY_API == nil or config.GOTIFY_API == "" then
            log.error("util_notify", "未配置 `config.GOTIFY_API`")
            return
        end
        if config.GOTIFY_TOKEN == nil or config.GOTIFY_TOKEN == "" then
            log.error("util_notify", "未配置 `config.GOTIFY_TOKEN`")
            return
        end

        local url = config.GOTIFY_API .. "/message?token=" .. config.GOTIFY_TOKEN
        local header = {
            ["Content-Type"] = "application/json; charset=utf-8"
        }
        local body = {
            title = config.GOTIFY_TITLE,
            message = msg,
            priority = config.GOTIFY_PRIORITY
        }
        local json_data = json.encode(body)
        json_data = string.gsub(json_data, "\\b", "\\n")

        log.info("util_notify", "POST", config.GOTIFY_API)
        return util_http.fetch(nil, "POST", url, header, json_data)
    end,
    -- 发送到 pushdeer
    ["pushdeer"] = function(msg)
        if config.PUSHDEER_API == nil or config.PUSHDEER_API == "" then
            log.error("util_notify", "未配置 `config.PUSHDEER_API`")
            return
        end
        if config.PUSHDEER_KEY == nil or config.PUSHDEER_KEY == "" then
            log.error("util_notify", "未配置 `config.PUSHDEER_KEY`")
            return
        end

        local header = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        }
        local body = {
            pushkey = config.PUSHDEER_KEY or "",
            type = "text",
            text = msg
        }

        log.info("util_notify", "POST", config.PUSHDEER_API)
        return util_http.fetch(nil, "POST", config.PUSHDEER_API, header, urlencodeTab(body))
    end,
    -- 发送到 bark
    ["bark"] = function(msg)
        if config.BARK_API == nil or config.BARK_API == "" then
            log.error("util_notify", "未配置 `config.BARK_API`")
            return
        end
        if config.BARK_KEY == nil or config.BARK_KEY == "" then
            log.error("util_notify", "未配置 `config.BARK_KEY`")
            return
        end

        local header = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        }
        local body = {
            body = msg
        }
        local url = config.BARK_API .. "/" .. config.BARK_KEY

        log.info("util_notify", "POST", url)
        return util_http.fetch(nil, "POST", url, header, urlencodeTab(body))
    end,
    -- 发送到 dingtalk
    ["dingtalk"] = function(msg)
        if config.DINGTALK_WEBHOOK == nil or config.DINGTALK_WEBHOOK == "" then
            log.error("util_notify", "未配置 `config.DINGTALK_WEBHOOK`")
            return
        end

        local header = {
            ["Content-Type"] = "application/json; charset=utf-8"
        }
        local body = {
            msgtype = "text",
            text = {
                content = msg
            }
        }
        local json_data = json.encode(body)
        -- LuatOS Bug, json.encode 会将 \n 转换为 \b
        json_data = string.gsub(json_data, "\\b", "\\n")

        log.info("util_notify", "POST", config.DINGTALK_WEBHOOK)
        return util_http.fetch(nil, "POST", config.DINGTALK_WEBHOOK, header, json_data)
    end,
    -- 发送到 feishu
    ["feishu"] = function(msg)
        if config.FEISHU_WEBHOOK == nil or config.FEISHU_WEBHOOK == "" then
            log.error("util_notify", "未配置 `config.FEISHU_WEBHOOK`")
            return
        end

        local header = {
            ["Content-Type"] = "application/json; charset=utf-8"
        }
        local body = {
            msg_type = "text",
            content = {
                text = msg
            }
        }
        local json_data = json.encode(body)
        -- LuatOS Bug, json.encode 会将 \n 转换为 \b
        json_data = string.gsub(json_data, "\\b", "\\n")

        log.info("util_notify", "POST", config.FEISHU_WEBHOOK)
        return util_http.fetch(nil, "POST", config.FEISHU_WEBHOOK, header, json_data)
    end,
    -- 发送到 wecom
    ["wecom"] = function(msg)
        if config.WECOM_WEBHOOK == nil or config.WECOM_WEBHOOK == "" then
            log.error("util_notify", "未配置 `config.WECOM_WEBHOOK`")
            return
        end

        local header = {
            ["Content-Type"] = "application/json; charset=utf-8"
        }
        local body = {
            msgtype = "text",
            text = {
                content = msg
            }
        }
        local json_data = json.encode(body)
        -- LuatOS Bug, json.encode 会将 \n 转换为 \b
        json_data = string.gsub(json_data, "\\b", "\\n")

        log.info("util_notify", "POST", config.WECOM_WEBHOOK)
        return util_http.fetch(nil, "POST", config.WECOM_WEBHOOK, header, json_data)
    end,
    -- 发送到 pushover
    ["pushover"] = function(msg)
        if config.PUSHOVER_API_TOKEN == nil or config.PUSHOVER_API_TOKEN == "" then
            log.error("util_notify", "未配置 `config.PUSHOVER_API_TOKEN`")
            return
        end
        if config.PUSHOVER_USER_KEY == nil or config.PUSHOVER_USER_KEY == "" then
            log.error("util_notify", "未配置 `config.PUSHOVER_USER_KEY`")
            return
        end

        local header = {
            ["Content-Type"] = "application/json; charset=utf-8"
        }
        local body = {
            token = config.PUSHOVER_API_TOKEN,
            user = config.PUSHOVER_USER_KEY,
            message = msg
        }

        local json_data = json.encode(body)
        -- LuatOS Bug, json.encode 会将 \n 转换为 \b
        json_data = string.gsub(json_data, "\\b", "\\n")

        local url = "https://api.pushover.net/1/messages.json"

        log.info("util_notify", "POST", url)
        return util_http.fetch(nil, "POST", url, header, json_data)
    end,
    -- 发送到 inotify
    ["inotify"] = function(msg)
        if config.INOTIFY_API == nil or config.INOTIFY_API == "" then
            log.error("util_notify", "未配置 `config.INOTIFY_API`")
            return
        end
        if not config.INOTIFY_API:endsWith(".send") then
            log.error("util_notify", "`config.INOTIFY_API` 必须以 `.send` 结尾")
            return
        end

        local url = config.INOTIFY_API .. "/" .. string.urlEncode(msg)

        log.info("util_notify", "GET", url)
        return util_http.fetch(nil, "GET", url)
    end,
    -- 发送到 next-smtp-proxy
    ["next-smtp-proxy"] = function(msg)
        if config.NEXT_SMTP_PROXY_API == nil or config.NEXT_SMTP_PROXY_API == "" then
            log.error("util_notify", "未配置 `config.NEXT_SMTP_PROXY_API`")
            return
        end
        if config.NEXT_SMTP_PROXY_USER == nil or config.NEXT_SMTP_PROXY_USER == "" then
            log.error("util_notify", "未配置 `config.NEXT_SMTP_PROXY_USER`")
            return
        end
        if config.NEXT_SMTP_PROXY_PASSWORD == nil or config.NEXT_SMTP_PROXY_PASSWORD == "" then
            log.error("util_notify", "未配置 `config.NEXT_SMTP_PROXY_PASSWORD`")
            return
        end
        if config.NEXT_SMTP_PROXY_HOST == nil or config.NEXT_SMTP_PROXY_HOST == "" then
            log.error("util_notify", "未配置 `config.NEXT_SMTP_PROXY_HOST`")
            return
        end
        if config.NEXT_SMTP_PROXY_PORT == nil or config.NEXT_SMTP_PROXY_PORT == "" then
            log.error("util_notify", "未配置 `config.NEXT_SMTP_PROXY_PORT`")
            return
        end
        if config.NEXT_SMTP_PROXY_TO_EMAIL == nil or config.NEXT_SMTP_PROXY_TO_EMAIL == "" then
            log.error("util_notify", "未配置 `config.NEXT_SMTP_PROXY_TO_EMAIL`")
            return
        end

        local header = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        }
        local body = {
            user = config.NEXT_SMTP_PROXY_USER,
            password = config.NEXT_SMTP_PROXY_PASSWORD,
            host = config.NEXT_SMTP_PROXY_HOST,
            port = config.NEXT_SMTP_PROXY_PORT,
            form_name = config.NEXT_SMTP_PROXY_FORM_NAME,
            to_email = config.NEXT_SMTP_PROXY_TO_EMAIL,
            subject = config.NEXT_SMTP_PROXY_SUBJECT,
            text = msg
        }

        log.info("util_notify", "POST", config.NEXT_SMTP_PROXY_API)
        return util_http.fetch(nil, "POST", config.NEXT_SMTP_PROXY_API, header, urlencodeTab(body))
    end
}

local function append()
    local msg = "\n"

    -- 本机号码
    local number = mobile.number(mobile.simid())
    if number then
        msg = msg .. "\n本机号码: " .. number
    end

    -- 开机时长
    local ms = mcu.ticks()
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    seconds = seconds % 60
    minutes = minutes % 60
    local boot_time = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    if ms >= 0 then
        msg = msg .. "\n开机时长: " .. boot_time
    end

    -- 运营商
    local oper = util_mobile.getOper(true)
    if oper ~= "" then
        msg = msg .. "\n运营商: " .. oper
    end

    -- 信号
    local rsrp = mobile.rsrp()
    if rsrp ~= 0 then
        msg = msg .. "\n信号: " .. rsrp .. "dBm"
    end

    -- 频段
    local band = util_mobile.getBand()
    if band >= 0 then
        msg = msg .. "\n频段: B" .. band
    end

    -- 流量统计
    local uplinkGB, uplinkB, downlinkGB, downlinkB = mobile.dataTraffic()
    uplinkB = uplinkGB * 1024 * 1024 * 1024 + uplinkB
    downlinkB = downlinkGB * 1024 * 1024 * 1024 + downlinkB
    local function formatBytes(bytes)
        if bytes < 1024 then
            return bytes .. "B"
        elseif bytes < 1024 * 1024 then
            return string.format("%.2fKB", bytes / 1024)
        elseif bytes < 1024 * 1024 * 1024 then
            return string.format("%.2fMB", bytes / 1024 / 1024)
        else
            return string.format("%.2fGB", bytes / 1024 / 1024 / 1024)
        end
    end
    -- msg = msg .. "\n流量: ↑" .. formatBytes(uplinkB) .. " ↓" .. formatBytes(downlinkB)

    -- 位置
    local _, _, map_link = util_location.get()
    if map_link ~= "" then
        msg = msg .. "\n位置: " .. map_link -- 这里使用 U+00a0 防止换行
    end

    return msg
end

--- 发送通知
-- @param msg 消息内容
-- @param channel 通知渠道
-- @return true: 无需重发, false: 需要重发
function util_notify.send(msg, channel)
    log.info("util_notify.send", "发送通知", channel)

    -- 判断消息内容 msg
    if type(msg) ~= "string" then
        log.error("util_notify.send", "发送通知失败", "参数类型错误", type(msg))
        return true
    end
    if msg == "" then
        log.error("util_notify.send", "发送通知失败", "消息为空")
        return true
    end

    -- 判断通知渠道 channel
    if channel and notify[channel] == nil then
        log.error("util_notify.send", "发送通知失败", "未知通知渠道", channel)
        return true
    end

    -- 通知内容追加更多信息
    if config.NOTIFY_APPEND_MORE_INFO then
        msg = msg .. append()
    end

    -- 发送通知
    local code, headers, body = notify[channel](msg)
    if code == nil then
        log.info("util_notify.send", "发送通知失败, 无需重发", "code:", code, "body:", body)
        return true
    end
    if code == -6 then
        -- 发生在 url 过长时, 重发也不会成功
        log.info("util_notify.send", "发送通知失败, 无需重发", "code:", code, "body:", body)
        return true
    end
    if code >= 200 and code < 500 then
        -- http 2xx 成功
        -- http 3xx 重定向, 重发也不会成功
        -- http 4xx 客户端错误, 重发也不会成功
        log.info("util_notify.send", "发送通知成功", "code:", code, "body:", body)
        return true
    end
    log.error("util_notify.send", "发送通知失败, 等待重发", "code:", code, "body:", body)
    return false
end

--- 添加到消息队列
-- @param msg 消息内容
-- @param channels 通知渠道
function util_notify.add(msg, channels)
    if type(msg) == "table" then
        msg = table.concat(msg, "\n")
    end

    channels = channels or config.NOTIFY_TYPE

    if type(channels) ~= "table" then
        channels = {channels}
    end

    for _, channel in ipairs(channels) do
        table.insert(msg_queue, {channel = channel, msg = msg, retry = 0})
    end
    sys.publish("NEW_MSG")
    log.debug("util_notify.add", "添加到消息队列, 当前队列长度:", #msg_queue)
end

-- 轮询消息队列
-- 发送成功则从消息队列中删除
-- 发送失败则等待下次轮询
local function poll()
    local item, result
    while true do
        -- 消息队列非空, 且网络已注册
        if next(msg_queue) ~= nil and mobile.status() == 1 then
            log.debug("util_notify.poll", "轮询消息队列中, 当前队列长度:", #msg_queue)

            item = msg_queue[1]
            table.remove(msg_queue, 1)

            if item.retry > (config.NOTIFY_RETRY_MAX or 100) then
                log.error("util_notify.poll", "超过最大重发次数", "msg:", item.msg)
            else
                result = util_notify.send(item.msg, item.channel)
                item.retry = item.retry + 1

                if not result then
                    -- 发送失败, 移到队尾
                    table.insert(msg_queue, item)
                    sys.wait(5000)
                end
            end
            sys.wait(50)
        else
            sys.waitUntil("NEW_MSG", 1000 * 10)
        end
    end
end

sys.taskInit(poll)

return util_notify
