local util_http = {}

-- 用于生成 http 请求的 id
local http_count = 0
-- 记录正在运行的 http 请求数量
local http_running_count = 0

--- 对 http.request 的封装
-- @param timeout 超时时间(单位: 毫秒)
-- @param method 请求方法
-- @param url 请求地址
-- @param headers 请求头
-- @param body 请求体
function util_http.fetch(timeout, method, url, headers, body)
    collectgarbage("collect")

    timeout = timeout or 1000 * 25
    local opts = { timeout = timeout }

    http_count = http_count + 1
    http_running_count = http_running_count + 1

    local id = "http_" .. http_count
    local res_code, res_headers, res_body = -99, {}, ""

    util_netled.blink(50, 50)

    log.debug("util_http.fetch", "开始请求", "id:", id)
    res_code, res_headers, res_body = http.request(method, url, headers, body, opts).wait()
    log.debug("util_http.fetch", "请求结束", "id:", id, "code:", res_code)

    if res_code == -8 then log.warn("util_http.fetch", "请求超时", "id:", id) end

    http_running_count = http_running_count - 1
    if http_running_count == 0 then util_netled.blink() end

    collectgarbage("collect")

    return res_code, res_headers, res_body
end

return util_http
