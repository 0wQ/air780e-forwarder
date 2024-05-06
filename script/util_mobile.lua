local util_mobile = {}

--- 验证 pin 码
-- @param pin_code string, pin 码
function util_mobile.pinVerify(pin_code)
    local sim_id = mobile.simid()

    pin_code = tostring(pin_code or "")
    if #pin_code < 4 or #pin_code > 8 then
        log.warn("util_mobile.pinVerify", "pin 码长度不正确")
        return
    end

    local cpin_is_ready = mobile.simPin(sim_id)
    if cpin_is_ready then
        log.info("util_mobile.pinVerify", "无需验证 pin 码")
        return
    end

    cpin_is_ready = mobile.simPin(sim_id, mobile.PIN_VERIFY, pin_code)
    log.info("util_mobile.pinVerify", "验证 pin 码" .. (cpin_is_ready and "成功" or "失败"))
end

-- 运营商数据
local oper_data = {
    -- 中国移动
    ["46000"] = { "CM", "中国移动", { "10086", "CXLL" } },
    ["46002"] = { "CM", "中国移动", { "10086", "CXLL" } },
    ["46007"] = { "CM", "中国移动", { "10086", "CXLL" } },
    ["46008"] = { "CM", "中国移动", { "10086", "CXLL" } },
    -- 中国联通
    ["46001"] = { "CU", "中国联通", { "10010", "2082" } },
    ["46006"] = { "CU", "中国联通", { "10010", "2082" } },
    ["46009"] = { "CU", "中国联通", { "10010", "2082" } },
    ["46010"] = { "CU", "中国联通", { "10010", "2082" } },
    -- 中国电信
    ["46003"] = { "CT", "中国电信", { "10001", "108" } },
    ["46005"] = { "CT", "中国电信", { "10001", "108" } },
    ["46011"] = { "CT", "中国电信", { "10001", "108" } },
    ["46012"] = { "CT", "中国电信", { "10001", "108" } },
    -- 中国广电
    ["46015"] = { "CB", "中国广电" },
}

--- 获取 MCC 和 MNC
-- @return MCC or -1
-- @return MNC or -1
function util_mobile.getMccMnc()
    local imsi = mobile.imsi(mobile.simid()) or ""
    return string.sub(imsi, 1, 3) or -1, string.sub(imsi, 4, 5) or -1
end

--- 获取 Band
-- @return Band or -1
function util_mobile.getBand()
    local info = mobile.getCellInfo()[1] or {}
    return info.band or -1
end

--- 获取运营商
-- @param is_zh 是否返回中文
-- @return 运营商 or ""
function util_mobile.getOper(is_zh)
    local imsi = mobile.imsi(mobile.simid()) or ""
    local mcc, mnc = string.sub(imsi, 1, 3), string.sub(imsi, 4, 5)
    local mcc_mnc = mcc .. mnc

    local oper = oper_data[mcc_mnc]
    if oper then
        return is_zh and oper[2] or oper[1]
    else
        return mcc_mnc
    end
end

--- 发送查询流量短信
function util_mobile.queryTraffic()
    local imsi = mobile.imsi(mobile.simid()) or ""
    local mcc_mnc = string.sub(imsi, 1, 5)

    local oper = oper_data[mcc_mnc]
    if oper and oper[3] then
        sms.send(oper[3][1], oper[3][2])
    else
        log.warn("util_mobile.queryTraffic", "查询流量代码未配置")
    end
end

--- 获取网络状态
-- @return 网络状态
function util_mobile.status()
    local codes = {
        [0] = "网络未注册",
        [1] = "网络已注册",
        [2] = "网络搜索中",
        [3] = "网络注册被拒绝",
        [4] = "网络状态未知",
        [5] = "网络已注册,漫游",
        [6] = "网络已注册,仅SMS",
        [7] = "网络已注册,漫游,仅SMS",
        [8] = "网络已注册,紧急服务",
        [9] = "网络已注册,非主要服务",
        [10] = "网络已注册,非主要服务,漫游",
    }
    local mobile_status = mobile.status()
    if mobile_status and mobile_status >= 0 and mobile_status <= 10 then
        return codes[mobile_status] or "未知网络状态"
    end
    return "未知网络状态"
end

--- 追加设备信息
--- @return string
function util_mobile.appendDeviceInfo()
    local msg = "\n"

    -- 本机号码
    local number = mobile.number(mobile.simid()) or config.FALLBACK_LOCAL_NUMBER
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
    msg = msg .. "\n信号: " .. mobile.rsrp() .. "dBm"

    -- 频段
    -- local band = util_mobile.getBand()
    -- if band >= 0 then
    --     msg = msg .. "\n频段: B" .. band
    -- end

    -- 电压, 读取 VBAT 供电电压, 单位为 mV
    -- adc.open(adc.CH_VBAT)
    -- local vbat = adc.get(adc.CH_VBAT)
    -- adc.close(adc.CH_VBAT)
    -- if vbat >= 0 then
    --     msg = msg .. "\n电压: " .. string.format("%.1f", vbat / 1000) .. "V"
    -- end

    -- 温度
    -- adc.open(adc.CH_CPU)
    -- local temp = adc.get(adc.CH_CPU)
    -- adc.close(adc.CH_CPU)
    -- if temp >= 0 then
    --     msg = msg .. "\n温度: " .. string.format("%.1f", temp / 1000) .. "°C"
    -- end

    -- 基站信息
    -- msg = msg .. "\nECI: " .. mobile.eci()
    -- msg = msg .. "\nTAC: " .. mobile.tac()
    -- msg = msg .. "\nENBID: " .. mobile.enbid()

    -- 流量统计
    -- local uplinkGB, uplinkB, downlinkGB, downlinkB = mobile.dataTraffic()
    -- uplinkB = uplinkGB * 1024 * 1024 * 1024 + uplinkB
    -- downlinkB = downlinkGB * 1024 * 1024 * 1024 + downlinkB
    -- local function formatBytes(bytes)
    --     if bytes < 1024 then
    --         return bytes .. "B"
    --     elseif bytes < 1024 * 1024 then
    --         return string.format("%.2fKB", bytes / 1024)
    --     elseif bytes < 1024 * 1024 * 1024 then
    --         return string.format("%.2fMB", bytes / 1024 / 1024)
    --     else
    --         return string.format("%.2fGB", bytes / 1024 / 1024 / 1024)
    --     end
    -- end
    -- msg = msg .. "\n流量: ↑" .. formatBytes(uplinkB) .. " ↓" .. formatBytes(downlinkB)

    -- 位置
    local _, _, map_link = util_location.get()
    if map_link ~= "" then
        msg = msg .. "\n位置: " .. map_link -- 这里使用 U+00a0 防止换行
    end

    return msg
end

return util_mobile
