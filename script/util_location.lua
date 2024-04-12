local util_location = {}

PRODUCT_KEY = "v32xEAKsGTIEQxtqgwCldp5aPlcnPs3K"
local lbsLoc = require("lbsLoc")

local cache = { lbs_data = { lat = 0, lng = 0 } }

--- 格式化经纬度 (保留小数点后 6 位, 去除末尾的 0)
-- @param value 经纬度
-- @return 格式化后的经纬度
local function formatCoord(value)
    local str = string.format("%.6f", tonumber(value) or 0)
    str = str:gsub("%.?0+$", "")
    return tonumber(str)
end

--- 生成地图链接
-- @param lat 纬度
-- @param lng 经度
-- @return 地图链接 or ""
local function getMapLink(lat, lng)
    lat, lng = lat or 0, lng or 0
    local map_link = ""
    if lat ~= 0 and lng ~= 0 then map_link = "http://apis.map.qq.com/uri/v1/marker?coord_type=1&marker=title:+;coord:" .. lat .. "," .. lng end
    log.debug("util_location.getMapLink", map_link)
    return map_link
end

--- lbsLoc.request 回调
local function getLocCb(result, lat, lng, addr, time, locType)
    log.info("util_location.getLocCb", "result,lat,lng,time,locType:", result, lat, lng, time and time:toHex(), locType)
    -- 获取经纬度成功, 坐标系WGS84
    if result == 0 and lat and lng then
        cache.lbs_data = { lat, lng }
    end
end

--- 刷新基站信息
-- @param timeout 超时时间(单位: 秒)
local function refreshCellInfo(timeout)
    log.info("util_location.refreshCellInfo", "start")
    if cache.is_req_cell_info_running then
        log.info("util_location.refreshCellInfo", "running, wait...")
    else
        cache.is_req_cell_info_running = true
        mobile.reqCellInfo(timeout or 20) -- 单位: 秒
    end
    sys.waitUntil("CELL_INFO_UPDATE")
    cache.is_req_cell_info_running = false
    log.info("util_location.refreshCellInfo", "end")
end

--- 刷新基站定位信息
-- @param timeout 超时时间(单位: 毫秒)
function util_location.refresh(timeout)
    timeout = type(timeout) == "number" and timeout or nil

    sys.taskInit(function()
        refreshCellInfo()
        lbsLoc.request(getLocCb, nil, timeout)
    end)
end

--- 获取位置信息
-- @return lat
-- @return lng
-- @return map_link
function util_location.get()
    local lat, lng = unpack(cache.lbs_data)
    lat, lng = formatCoord(lat), formatCoord(lng)
    return lat, lng, getMapLink(lat, lng)
end

sys.taskInit(refreshCellInfo)

sys.subscribe("CELL_INFO_UPDATE", function() log.debug("EVENT.CELL_INFO_UPDATE") end)

return util_location
