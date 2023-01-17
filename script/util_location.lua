local lbsLoc = require "lbsLoc"

local util_location = {}

local last_lat, last_lng = 0, 0
local last_time = 0

-- 获取坐标
function util_location.getCoord(callback, type, wifi, timeout)
    local is_callback = callback ~= nil
    if callback == nil then
        callback = function()
        end
    end

    sys.taskInit(
        function()
            local current_time = os.time()
            if not is_callback then
                if current_time - last_time < 30 then
                    log.info("util_location.getCoord", "距离上次定位时间太短", current_time - last_time)
                    return
                end
                sys.wait(2000)
            end
            last_time = current_time
            lbsLoc.request(
                function(result, lat, lng, addr, time, locType)
                    log.info("util_location.getCoord", result, lat, lng, locType)
                    if result == 0 and lat and lng then
                        last_lat, last_lng = lat, lng
                        return callback(lat, lng)
                    end
                    return callback(last_lat, last_lng)
                end,
                nil,
                timeout,
                "v32xEAKsGTIEQxtqgwCldp5aPlcnPs3K",
                nil,
                nil,
                nil,
                wifi
            )
        end
    )

    return last_lat, last_lng
end

return util_location
