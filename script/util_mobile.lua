local util_mobile = {}

-- 运营商数据
local oper_data = {
    -- 中国移动
    ["46000"] = {"CM", "中国移动", {"10086", "CXLL"}},
    ["46002"] = {"CM", "中国移动", {"10086", "CXLL"}},
    ["46007"] = {"CM", "中国移动", {"10086", "CXLL"}},
    -- 中国联通
    ["46001"] = {"CU", "中国联通", {"10010", "2082"}},
    ["46006"] = {"CU", "中国联通", {"10010", "2082"}},
    ["46009"] = {"CU", "中国联通", {"10010", "2082"}},
    -- 中国电信
    ["46003"] = {"CT", "中国电信", {"10001", "108"}},
    ["46005"] = {"CT", "中国电信", {"10001", "108"}},
    ["46011"] = {"CT", "中国电信", {"10001", "108"}},
    -- 中国广电
    ["46015"] = {"CB", "中国广电"}
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

return util_mobile
