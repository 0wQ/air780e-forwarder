local util_netled = {}

local netled_default_duration = 200
local netled_default_interval = 3000

local netled_duration = netled_default_duration
local netled_interval = netled_default_interval

local netled_inited = false

-- 开机时呼吸灯效果
sys.taskInit(function()
    local nums = { 0, 1, 2, 4, 6, 12, 16, 21, 27, 34, 42, 51, 61, 72, 85, 100, 100 }
    local len = #nums
    while true do
        for i = 1, len, 1 do
            pwm.open(4, 1000, nums[i])
            result = sys.waitUntil("NET_LED_INIT", 25)
            if result then
                pwm.close(4)
                return
            end
        end
        for i = len, 1, -1 do
            pwm.open(4, 1000, nums[i])
            result = sys.waitUntil("NET_LED_INIT", 25)
            if result then
                pwm.close(4)
                return
            end
        end
    end
end)

-- 注册网络后开始闪烁
function util_netled.init()
    if netled_inited then return end
    netled_inited = true
    sys.publish("NET_LED_INIT")

    sys.taskInit(function()
        local netled = gpio.setup(27, 0, gpio.PULLUP)
        while true do
            netled(1)
            sys.waitUntil("NET_LED_UPDATE", netled_duration)
            netled(0)
            sys.waitUntil("NET_LED_UPDATE", netled_interval)
        end
    end)
end

function util_netled.blink(duration, interval, restore)
    if duration == netled_duration and interval == netled_interval then return end
    netled_duration = duration or netled_default_duration
    netled_interval = interval or netled_default_interval
    log.debug("EVENT.NET_LED_UPDATE", duration, interval, restore)
    sys.publish("NET_LED_UPDATE")
    if restore then sys.timerStart(util_netled.blink, restore) end
end

return util_netled
