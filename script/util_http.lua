local util_http = {}

-- 用于生成 http 请求的 id
local http_count = 0
-- 记录正在运行的 http 请求数量
local http_running_count = 0

local luat_http_code_desc = {
    [0] = "HTTP_OK",
    [-1] = "HTTP_ERROR_STATE",
    [-2] = "HTTP_ERROR_HEADER",
    [-3] = "HTTP_ERROR_BODY",
    [-4] = "HTTP_ERROR_CONNECT",
    [-5] = "HTTP_ERROR_CLOSE",
    [-6] = "HTTP_ERROR_RX",
    [-7] = "HTTP_ERROR_DOWNLOAD",
    [-8] = "HTTP_ERROR_TIMEOUT",
    [-9] = "HTTP_ERROR_FOTA",
}

--- 对 http.request 的封装
-- @param timeout 超时时间(单位: 毫秒)
-- @param method 请求方法
-- @param url 请求地址
-- @param headers 请求头
-- @param body 请求体
function util_http.fetch(timeout, method, url, headers, body)
    collectgarbage("collect")

    timeout = timeout or 1000 * 20
    local opts = { timeout = timeout }

    http_count = http_count + 1
    http_running_count = http_running_count + 1

    local id = "http_" .. http_count
    local res_code, res_headers, res_body = -99, {}, ""

    util_netled.blink(50, 50)

    log.debug("util_http.fetch", "开始请求", "id:", id)
    res_code, res_headers, res_body = http.request(method, url, headers, body, opts).wait()
    log.debug("util_http.fetch", "请求结束", "id:", id, "code:", res_code, "desc:", luat_http_code_desc[res_code])

    http_running_count = http_running_count - 1
    if http_running_count == 0 then
        util_netled.blink()
    end

    collectgarbage("collect")

    return res_code, res_headers, res_body
end

return util_http
