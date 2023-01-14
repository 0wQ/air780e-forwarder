local util_netled = {}

local netled = gpio.setup(27, 0, gpio.PULLUP)

local netled_default_duration = 200
local netled_default_interval = 2000

local netled_duration = netled_default_duration
local netled_interval = netled_default_interval

sys.taskInit(
    function()
        while true do
            netled(1)
            sys.wait(netled_duration)
            netled(0)
            sys.wait(netled_interval)
        end
    end
)

function util_netled.blink(duration, interval, restore)
    netled_duration = duration or netled_default_duration
    netled_interval = interval or netled_default_interval
    if restore then
        sys.timerStart(
            function()
                netled_duration = netled_default_duration
                netled_interval = netled_default_interval
            end,
            restore
        )
    end
end

return util_netled
