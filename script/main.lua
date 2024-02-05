PROJECT = "air780e_forwarder"
VERSION = "1.0.0"

log.setLevel("DEBUG")
log.info("main", PROJECT, VERSION)
log.info("main", "开机原因", pm.lastReson())

sys = require "sys"
sysplus = require "sysplus"

-- 添加硬狗防止程序卡死
wdt.init(9000)
sys.timerLoopStart(wdt.feed, 3000)

-- 设置电平输出 3.3V
-- pm.ioVol(pm.IOVOL_ALL_GPIO, 3300)

-- 设置 DNS
socket.setDNS(nil, 1, "119.29.29.29")
socket.setDNS(nil, 2, "223.5.5.5")

-- 设置 SIM 自动恢复(单位: 毫秒), 搜索小区信息间隔(单位: 毫秒), 最大搜索时间(单位: 秒)
mobile.setAuto(1000 * 10)

-- 开启 IPv6
mobile.ipv6(true)

-- POWERKEY
local button_last_press_time, button_last_release_time = 0, 0
gpio.setup(35, function()
    local current_time = mcu.ticks()
    -- 按下
    if gpio.get(35) == 0 then
        button_last_press_time = current_time -- 记录最后一次按下时间
        return
    end
    -- 释放
    if button_last_press_time == 0 then -- 开机前已经按下, 开机后释放
        return
    end
    if current_time - button_last_release_time < 250 then -- 防止连按
        return
    end
    local duration = current_time - button_last_press_time -- 按键持续时间
    button_last_release_time = current_time -- 记录最后一次释放时间
    if duration > 2000 then
        log.debug("EVENT.POWERKEY_LONG_PRESS", duration)
        sys.publish("POWERKEY_LONG_PRESS", duration)
    elseif duration > 50 then
        log.debug("EVENT.POWERKEY_SHORT_PRESS", duration)
        sys.publish("POWERKEY_SHORT_PRESS", duration)
    end
end, gpio.PULLUP)

-- 加载模块
config = require "config"
util_http = require "util_http"
util_netled = require "util_netled"
util_mobile = require "util_mobile"
util_location = require "util_location"
util_notify = require "util_notify"

-- 由于 NOTIFY_TYPE 支持多个配置, 需按照包含来判断
local containsValue = function(t, value)
    if t == value then return true end
    if type(t) ~= "table" then return false end
    for k, v in pairs(t) do if v == value then return true end end
    return false
end

if containsValue(config.NOTIFY_TYPE, "serial") then
    -- 串口配置
    uart.setup(1, 115200, 8, 1, uart.NONE)
    -- 串口接收回调
    uart.on(1, "receive", function(id, len)
        local data = uart.read(id, len)
        log.info("uart read:", id, len, data)
        if config.ROLE == "MASTER" then
            -- 主机, 通过队列发送数据
            util_notify.add(data)
        else
            -- 从机, 通过串口发送数据
            uart.write(1, data)
        end
    end)
end

-- 短信接收回调
sms.setNewSmsCb(function(sender_number, sms_content, m)
    local time = string.format("%d/%02d/%02d %02d:%02d:%02d", m.year + 2000, m.mon, m.day, m.hour, m.min, m.sec)
    log.info("smsCallback", time, sender_number, sms_content)

    -- 短信控制
    local is_sms_ctrl = false
    local receiver_number, sms_content_to_be_sent = sms_content:match("^SMS,(+?%d+),(.+)$")
    receiver_number, sms_content_to_be_sent = receiver_number or "", sms_content_to_be_sent or ""
    if sms_content_to_be_sent ~= "" and receiver_number ~= "" and #receiver_number >= 5 and #receiver_number <= 20 then
        sms.send(receiver_number, sms_content_to_be_sent)
        is_sms_ctrl = true
    end

    -- 发送通知
    util_notify.add({ sms_content, "", "发件号码: " .. sender_number, "发件时间: " .. time, "#SMS" .. (is_sms_ctrl and " #CTRL" or "") })
end)

sys.taskInit(function()
    -- 等待网络环境准备就绪
    sys.waitUntil("IP_READY", 20000)

    util_netled.init()

    -- 开机通知
    if config.BOOT_NOTIFY then sys.timerStart(util_notify.add, 1000 * 5, "#BOOT") end

    -- 定时查询流量
    if config.QUERY_TRAFFIC_INTERVAL and config.QUERY_TRAFFIC_INTERVAL >= 1000 * 60 then
        sys.timerLoopStart(util_mobile.queryTraffic, config.QUERY_TRAFFIC_INTERVAL)
    end

    -- 定时基站定位
    if config.LOCATION_INTERVAL and config.LOCATION_INTERVAL >= 1000 * 30 then
        util_location.refresh(nil, true)
        sys.timerLoopStart(util_location.refresh, config.LOCATION_INTERVAL)
    end

    -- 电源键短按发送测试通知
    sys.subscribe("POWERKEY_SHORT_PRESS", function() util_notify.add("#ALIVE") end)
    -- 电源键长按查询流量
    sys.subscribe("POWERKEY_LONG_PRESS", util_mobile.queryTraffic)

    -- 开启低功耗模式
    if config.LOW_POWER_MODE then
        sys.wait(1000 * 15)
        log.warn("main", "即将关闭 usb 电源, 如需查看日志请在配置中关闭低功耗模式")
        sys.wait(1000 * 5)
        gpio.setup(23, nil)
        gpio.close(33)
        pm.power(pm.USB, false) -- 关闭 USB
        pm.power(pm.GPS, false)
        pm.power(pm.GPS_ANT, false)
        pm.power(pm.DAC_EN, false)
        pm.force(pm.LIGHT) -- 进入休眠
    end
end)

-- 通话相关
local is_calling = false

sys.subscribe("CC_IND", function(status)
    if cc == nil then return end

    if status == "INCOMINGCALL" then
        -- 来电事件, 期间会重复触发
        if is_calling then return end
        is_calling = true

        log.info("cc_status", "INCOMINGCALL", "来电事件", cc.lastNum())

        -- 发送通知
        util_notify.add({ "来电号码: " .. cc.lastNum(), "来电时间: " .. os.date("%Y-%m-%d %H:%M:%S"), "#CALL #CALL_IN" })
        return
    end

    if status == "DISCONNECTED" then
        -- 挂断事件
        is_calling = false
        log.info("cc_status", "DISCONNECTED", "挂断事件", cc.lastNum())

        -- 发送通知
        util_notify.add({ "来电号码: " .. cc.lastNum(), "挂断时间: " .. os.date("%Y-%m-%d %H:%M:%S"), "#CALL #CALL_DISCONNECTED" })
        return
    end

    log.info("cc_status", status)
end)

sys.run()
