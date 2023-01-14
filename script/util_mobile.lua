local util_mobile = {mcc = 99, mnc = 99, band = 99}

-- 查询流量代码
local trafficCode = {
    CU = {"10010", "1071"},
    CM = {"10086", "cxll"},
    CT = {"10001", "108"}
}

-- 获取运营商
function util_mobile.getOper(is_zh)
    if util_mobile.mcc ~= 460 then
        return ""
    end

    if util_mobile.mnc == 1 then
        return is_zh and "中国联通" or "CU"
    end

    if util_mobile.mnc == 0 then
        return is_zh and "中国移动" or "CM"
    end

    if util_mobile.mnc == 11 then
        return is_zh and "中国电信" or "CT"
    end

    if util_mobile.mnc == 15 then
        return is_zh and "中国广电" or "CB"
    end

    return ""
end

-- 发送查询流量短信
function util_mobile.queryTraffic()
    local oper = util_mobile.getOper()
    if oper and trafficCode[oper] then
        sms.send(trafficCode[oper][1], trafficCode[oper][2])
    else
        log.warn("queryTraffic", "查询流量代码未配置")
    end
end

sys.subscribe(
    "CELL_INFO_UPDATE",
    function()
        local info = mobile.getCellInfo()[1] or {}
        util_mobile.mcc, util_mobile.mnc, util_mobile.band = info.mcc, info.mnc, info.band
        log.info("cell", "mcc:", util_mobile.mcc, "mnc:", util_mobile.mnc, "band:", util_mobile.band)
    end
)

return util_mobile
