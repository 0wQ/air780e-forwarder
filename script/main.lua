PROJECT = "air780e_forwarder"
VERSION = "1.0.0"

log.setLevel("DEBUG")
log.info("main", PROJECT, VERSION)

sys = require "sys"
sysplus = require "sysplus"
require "sysplus"

-- 添加硬狗防止程序卡死, 在支持的设备上启用这个功能
if wdt then
    -- 初始化 watchdog 设置为 9s
    wdt.init(9000)
    -- 3s 喂一次狗
    sys.timerLoopStart(wdt.feed, 3000)
end

-- 设置 DNS
socket.setDNS(nil, 1, "119.29.29.29")
socket.setDNS(nil, 2, "223.5.5.5")

-- 设置 SIM 自动恢复, 搜索小区信息间隔, 最大搜索时间
mobile.setAuto(1000 * 10, 1000 * 60, 1000 * 5)

-- POWERKEY
local powerkey_timer = 0
gpio.setup(
    35,
    function()
        local powerkey_state = gpio.get(35)
        if powerkey_state == 0 then
            powerkey_timer = os.time()
        else
            if powerkey_timer == 0 then
                return
            end
            local time = os.time() - powerkey_timer
            if time >= 2 then
                log.info("POWERKEY_LONG_PRESS", time)
                sys.publish("POWERKEY_LONG_PRESS")
            else
                log.info("POWERKEY_SHORT_PRESS", time)
                sys.publish("POWERKEY_SHORT_PRESS")
            end
            powerkey_timer = 0
        end
    end,
    gpio.PULLUP,
    gpio.FALLING
)

config = require "config"
util_netled = require "util_netled"
util_mobile = require "util_mobile"
util_location = require "util_location"
util_notify = require "util_notify"

-- 短信回调
sms.setNewSmsCb(
    function(num, txt, metas)
        log.info("smsCallback", num, txt, metas and json.encode(metas) or "")
        util_netled.blink(200, 200, 1000)
        util_notify.send({txt, "", "发件人号码: " .. num, "#SMS"})
    end
)

sys.taskInit(
    function()
        -- 等待网络环境准备就绪
        sys.waitUntil("IP_READY")

        util_netled.blink(200, 200, 5000)

        -- 开机基站定位
        util_location.getCoord(
            function()
                log.info("publish", "COORD_INIT_DONE")
                sys.publish("COORD_INIT_DONE")
            end
        )
        sys.waitUntil("COORD_INIT_DONE", 1000 * 20)

        -- 开机通知
        util_notify.send("#BOOT")

        -- 定时查询流量
        if config.QUERY_TRAFFIC_INTERVAL and config.QUERY_TRAFFIC_INTERVAL >= 1000 * 60 then
            sys.timerLoopStart(util_mobile.queryTraffic, config.QUERY_TRAFFIC_INTERVAL)
        end

        -- 定时基站定位
        if config.LOCATION_INTERVAL and config.LOCATION_INTERVAL >= 1000 * 10 then
            sys.timerLoopStart(util_location.getCoord, config.LOCATION_INTERVAL)
        end

        -- 电源键短按发送测试通知
        sys.subscribe(
            "POWERKEY_SHORT_PRESS",
            function()
                util_notify.send("#ALIVE")
            end
        )
        -- 电源键长按查询流量
        sys.subscribe("POWERKEY_LONG_PRESS", util_mobile.queryTraffic)
    end
)

sys.run()
