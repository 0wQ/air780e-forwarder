local util_location = {}

-- 基站定位接口类型, 支持 openluat 和 cellocation
local api_type = "openluat"

local cache = {
    cell_info_raw = {},
    cell_info_formatted = "",
    lbs_data = {
        lat = 0,
        lng = 0
    }
}

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
    if lat ~= 0 and lng ~= 0 then
        map_link = "http://apis.map.qq.com/uri/v1/marker?coord_type=1&marker=title:+;coord:" .. lat .. "," .. lng
    end
    log.debug("util_location.getMapLink", map_link)
    return map_link
end

--- 格式化基站信息
-- @param cell_info_raw 基站信息
-- @return 格式化后的基站信息
local function formatCellInfo(cell_info_raw)
    if api_type == "openluat" then
        local cell_info_arr = {}
        for i, v in ipairs(cell_info_raw) do
            table.insert(cell_info_arr, {mcc = v.mcc, mnc = v.mnc, lac = v.tac, ci = v.cid, rxlevel = v.rsrp, hex = 10})
        end
        local cell_info_json = json.encode(cell_info_arr)
        log.debug("util_location.formatCellInfo", api_type .. ":", cell_info_json)
        return cell_info_json
    end

    if api_type == "cellocation" then
        local str = ""
        for i, v in ipairs(cell_info_raw) do
            str = str .. (i == 1 and "" or ";")
            str = str .. v.mcc .. "," .. v.mnc .. "," .. v.tac .. "," .. v.cid .. "," .. v.rsrp
        end
        log.debug("util_location.formatCellInfo", api_type .. ":", str)
        return str
    end
end

--- 获取基站信息
-- @return 基站信息 or ""
local function getCellInfo()
    local cell_info_formatted = formatCellInfo(mobile.getCellInfo())
    cache.cell_info_formatted = cell_info_formatted
    return cell_info_formatted
end

--- 刷新基站信息
-- @param timeout 超时时间(单位: 秒)
function util_location.refreshCellInfo(timeout)
    log.info("util_location.refreshCellInfo", "start")
    if cache.is_req_cell_info_running then
        log.info("util_location.refreshCellInfo", "running, wait...")
    else
        cache.is_req_cell_info_running = true
        mobile.reqCellInfo(timeout or 30) -- 单位: 秒
    end
    sys.waitUntil("CELL_INFO_UPDATE")
    cache.is_req_cell_info_running = false
    log.info("util_location.refreshCellInfo", "end")
end

--- 刷新基站定位信息
-- @param timeout 超时时间(单位: 秒)
-- @return 刷新成功返回 true
function util_location.refresh(timeout, is_refresh_cell_info_disabled)
    timeout = type(timeout) == "number" and timeout * 1000 or nil

    local openluat = function(cell_info_formatted)
        local lbs_api = "http://bs.openluat.com/get_gpss"
        local header = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        }
        local body = "data=" .. cell_info_formatted
        local code, headers, body = util_http.fetch(timeout, "POST", lbs_api, header, body)
        log.info("util_location.refresh", api_type .. ":", "code:", code, "body:", body)

        if code ~= 200 or body == nil or body == "" then
            return
        end

        local lbs_data = json.decode(body) or {}
        local status, lat, lng = lbs_data.status, lbs_data.lat, lbs_data.lng

        if status ~= 0 or lat == nil or lng == nil or lat == "" or lng == "" then
            return
        end

        return lat, lng
    end

    local cellocation = function(cell_info_formatted)
        local lbs_api = "http://api.cellocation.com:83/loc/?output=json&cl=" .. cell_info_formatted
        local code, headers, body = util_http.fetch(timeout, "GET", lbs_api)
        log.info("util_location.refresh", api_type .. ":", "code:", code, "body:", body)

        if code ~= 200 or body == nil or body == "" then
            return
        end

        local lbs_data = json.decode(body) or {}
        local errcode, lat, lng = lbs_data.errcode, lbs_data.lat, lbs_data.lon
        if errcode ~= 0 or lat == nil or lng == nil or lat == "0.0" or lng == "0.0" then
            return
        end

        return lat, lng
    end

    sys.taskInit(
        function()
            if not is_refresh_cell_info_disabled then
                util_location.refreshCellInfo(timeout)
            end
            local old_cell_info_formatted = cache.cell_info_formatted
            local cell_info_formatted = getCellInfo()

            if cell_info_formatted == old_cell_info_formatted then
                log.info("util_location.refresh", api_type .. ":", "cell_info 无变化, 不重新请求")
                return
            end

            local lat, lng
            if api_type == "openluat" then
                lat, lng = openluat(cell_info_formatted)
            elseif api_type == "cellocation" then
                lat, lng = cellocation(cell_info_formatted)
            end
            if lat and lng then
                cache.lbs_data = {lat, lng}
            end
        end
    )
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

sys.subscribe(
    "CELL_INFO_UPDATE",
    function()
        log.debug("EVENT.CELL_INFO_UPDATE")
    end
)

return util_location
