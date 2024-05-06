local util_notify_channel = require "util_notify_channel"

local util_notify = {}

-- 消息队列
local msg_queue = {}
-- 发送计数
local msg_count = 0
local error_count = 0

--- 发送通知
-- @param msg 消息内容
-- @param channel 通知渠道
-- @return true: 无需重发, false: 需要重发
local function send(msg, channel)
    log.info("util_notify.send", "发送通知", channel)

    -- 判断消息内容 msg
    if type(msg) ~= "string" or msg == "" then
        log.error("util_notify.send", "发送通知失败", "msg 参数错误", type(msg))
        return true
    end

    -- 判断通知渠道 channel
    if channel and util_notify_channel[channel] == nil then
        log.error("util_notify.send", "发送通知失败", "未知通知渠道", channel)
        return true
    end

    -- 发送通知
    local code, headers, body = util_notify_channel[channel](msg)
    if code == nil then
        log.info("util_notify.send", "发送通知失败, 无需重发", "code:", code, "body:", body)
        return true
    end
    if code >= 200 and code < 500 and code ~= 408 and code ~= 409 and code ~= 425 and code ~= 429 then
        log.info("util_notify.send", "发送通知成功", "code:", code, "body:", body)
        return true
    end
    log.error("util_notify.send", "发送通知失败, 等待重发", "code:", code, "body:", body)
    return false
end

--- 添加到消息队列
-- @param msg 消息内容
-- @param channels 通知渠道
-- @param id 消息唯一标识
function util_notify.add(msg, channels, id)
    msg_count = msg_count + 1

    if id == nil or id == "" then
        id = "msg-t" .. os.time() .. "c" .. msg_count .. "r" .. math.random(9999)
    end

    if type(msg) == "table" then
        msg = table.concat(msg, "\n")
    end

    channels = channels or config.NOTIFY_TYPE
    if type(channels) ~= "table" then
        channels = { channels }
    end

    for _, channel in ipairs(channels) do
        table.insert(msg_queue, { id = id, channel = channel, msg = msg, retry = 0 })
    end
    sys.publish("NEW_MSG")
    log.debug("util_notify.add", "添加到消息队列, 当前队列长度:", #msg_queue, "消息内容:", msg:gsub("\r", "\\r"):gsub("\n", "\\n"))
end

--- 轮询消息队列, 发送成功则从队列中删除, 发送失败则等待下次
local function poll()
    -- 打印网络状态
    if mobile.status() ~= 1 then
        log.warn("util_notify.poll", "mobile.status", mobile_status, util_mobile.status())
    end

    -- 消息队列非空
    if next(msg_queue) == nil then
        sys.waitUntil("NEW_MSG", 1000 * 10)
        return
    end

    local item = msg_queue[1]
    table.remove(msg_queue, 1)
    local msg = item.msg
    log.info("util_notify.poll", "轮询消息队列中", "总长度: " .. #msg_queue, "当前ID: " .. item.id, "当前重发次数: " .. item.retry, "连续失败次数: " .. error_count)

    -- 通知内容添加设备信息
    if config.NOTIFY_APPEND_MORE_INFO and not string.find(msg, "开机时长:") then
        msg = msg .. util_mobile.appendDeviceInfo()
    end
    -- 通知内容添加重发次数
    if error_count > 0 then
        msg = msg .. "\n重发次数: " .. error_count
    end

    -- 超过最大重发次数
    if item.retry > (config.NOTIFY_RETRY_MAX or 20) then
        log.warn("util_notify.poll", "超过最大重发次数, 放弃重发", item.msg)
        return
    end

    -- 开始发送
    local result = send(msg, item.channel)

    -- 发送成功
    if result then
        error_count = 0
        -- 检查 fskv 中如果存在则删除
        if fskv.get(item.id) then
            fskv.del(item.id)
        end
        return
    end

    -- 发送失败
    error_count = error_count + 1
    item.retry = item.retry + 1
    table.insert(msg_queue, item)
    log.info("util_notify.poll", "等待下次重发", "当前重发次数", item.retry, "连续失败次数", error_count)
    sys.waitUntil("IP_READY", 1000 * 5)

    -- 每连续失败 2 次, 开关飞行模式
    if error_count % 2 == 0 then
        -- 开关飞行模式
        log.warn("util_notify.poll", "连续失败次数过多, 开关飞行模式")
        mobile.flymode(0, true)
        mobile.flymode(0, false)
        sys.wait(1000)
    end

    -- 每条消息第 1 次重发失败后, 保存到 fskv, 断电开机可恢复重发
    if item.retry == 1 then
        if not (string.find(item.msg, "#SMS") or string.find(item.msg, "#CALL")) then
            return
        end
        log.info("util_notify.poll", "当前第 1 次重发失败, 保存到 fskv", item.id)
        if fskv.get(item.id) then
            log.info("util_notify.poll", "fskv 已存在, 跳过写入", item.id)
            return
        end
        local kv_set_result = fskv.set(item.id, item.msg)
        log.info("util_notify.poll", "fskv.set", kv_set_result, "used,total,count:", fskv.status())
    end
end

sys.taskInit(function()
    while true do
        poll()
        sys.wait(100)
    end
end)

sys.taskInit(function()
    sys.waitUntil("IP_READY")
    sys.wait(10000)

    local iter = fskv.iter()
    while iter do
        local k = fskv.next(iter)
        if not k then
            break
        end
        local v = fskv.get(k)
        if not (v and v ~= "" and string.find(k, "msg-")) then
            break
        end
        log.info("util_notify", "检查到 fskv 中有历史消息", k, v:gsub("\r", "\\r"):gsub("\n", "\\n"))
        util_notify.add(v, nil, k)
    end
end)

return util_notify
