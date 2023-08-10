local lib_smtp = {}

lib_smtp.socket_debug_enable = false
lib_smtp.packet_size = 512
lib_smtp.timeout = 1000 * 30

--- 日志格式化函数
-- @param content string, 日志内容
-- @return string, 处理后的日志内容
local function logFormat(content)
    -- 隐藏 AUTH 用户信息
    content = content:gsub("AUTH PLAIN (.-)\r\n", "AUTH PLAIN ***\r\n")
    -- 替换换行符
    content = content:gsub("\r", "\\r"):gsub("\n", "\\n")
    -- 截取
    content = content:sub(1, 200) .. (#content > 200 and " ..." or "")
    return content
end

--- 转义句号函数
-- @param content string, 需要转义的内容
-- @return string, 转义后的内容
local function escapeDot(content)
    return content:gsub("(.-\r\n)", function(line)
        if line:sub(1, 1) == "." then line = "." .. line end
        return line
    end)
end

--- 接收到数据时的处理函数
-- @param netc userdata, socket.create 返回的 netc
-- @param rxbuf userdata, 接收到的数据
-- @param socket_id string, socket id
-- @param current_command string, 当前要发送的命令
local function recvHandler(netc, rxbuf, socket_id, current_command)
    local rx_str = rxbuf:toStr(0, rxbuf:used())
    log.info("lib_smtp", socket_id, "<-", logFormat(rx_str))

    -- 如果返回非 2xx 或 3xx 状态码, 则断开连接
    if not rx_str:match("^[23]%d%d") then
        log.error("lib_smtp", socket_id, "服务器返回错误状态码, 断开连接, 请检查日志")
        sys.publish(socket_id .. "_disconnect", { success = false, message = "服务器返回错误状态码", is_retry = false })
        return
    end

    if current_command == nil then
        log.info("lib_smtp", socket_id, "全部发送完成")
        sys.publish(socket_id .. "_disconnect", { success = true, message = "发送成功", is_retry = false })
        return
    end

    -- 分包发送
    local index = 1
    sys.taskInit(function()
        while index <= #current_command do
            local packet = current_command:sub(index, index + lib_smtp.packet_size - 1)
            socket.tx(netc, packet)
            log.info("lib_smtp", socket_id, "->", logFormat(packet))
            index = index + lib_smtp.packet_size
            sys.wait(100)
        end
    end)
end

local function validateParameters(smtp_config)
    -- 配置参数验证规则
    local validation_rules = {
        { field = "host", type = "string", required = true },
        { field = "port", type = "number", required = true },
        { field = "username", type = "string", required = true },
        { field = "password", type = "string", required = true },
        { field = "mail_from", type = "string", required = true },
        { field = "mail_to", type = "string", required = true },
        { field = "tls_enable", type = "boolean", required = false },
    }
    local result = true
    for _, rule in ipairs(validation_rules) do
        local value = smtp_config[rule.field]
        if rule.type == "string" and (value == nil or value == "") then
            log.error("lib_smtp", string.format("`smtp_config.%s` 应为非空字符串", rule.field))
            result = false
        elseif rule.required and type(value) ~= rule.type then
            log.error("lib_smtp", string.format("`smtp_config.%s` 应为 %s 类型", rule.field, rule.type))
            result = false
        end
    end
    return result
end

--- 发送邮件
-- @param body string 邮件正文
-- @param subject string 邮件主题
-- @param smtp_config table 配置参数
--   - smtp_config.host string SMTP 服务器地址
--   - smtp_config.username string SMTP 账号用户名
--   - smtp_config.password string SMTP 账号密码
--   - smtp_config.mail_from string 发件人邮箱地址
--   - smtp_config.mail_to string 收件人邮箱地址
--   - smtp_config.port number SMTP 服务器端口号
--   - smtp_config.tls_enable boolean 是否启用 TLS（可选，默认为 false）
-- @return result table 发送结果
--   - result.success boolean 是否发送成功
--   - result.message string 发送结果描述
--   - result.is_retry boolean 是否需要重试
function lib_smtp.send(body, subject, smtp_config)
    -- 参数验证
    if type(smtp_config) ~= "table" then
        log.error("lib_smtp", "`smtp_config` 应为 table 类型")
        return { success = false, message = "参数错误", is_retry = false }
    end
    local valid = validateParameters(smtp_config)
    if not valid then return { success = false, message = "参数错误", is_retry = false } end

    subject = type(subject) == "string" and subject or ""
    body = type(body) == "string" and escapeDot(body) or ""

    lib_smtp.send_count = (lib_smtp.send_count or 0) + 1
    local socket_id = "socket_" .. lib_smtp.send_count
    local rxbuf = zbuff.create(256)

    local commands = {
        "HELO " .. smtp_config.host .. "\r\n",
        "AUTH PLAIN " .. string.toBase64("\0" .. smtp_config.username .. "\0" .. smtp_config.password) .. "\r\n",
        "MAIL FROM: <" .. smtp_config.mail_from .. ">\r\n",
        "RCPT TO: <" .. smtp_config.mail_to .. ">\r\n",
        "DATA\r\n",
        table.concat({
            "From: " .. smtp_config.mail_from,
            "To: " .. smtp_config.mail_to,
            "Subject: " .. subject,
            "Content-Type: text/plain; charset=UTF-8",
            "",
            body,
            ".",
            "",
        }, "\r\n"),
    }
    local current_command_index = 1
    local function getNextCommand()
        local command = commands[current_command_index]
        current_command_index = current_command_index + 1
        return command
    end

    -- socket 回调
    local function netCB(netc, event, param)
        if param ~= 0 then
            sys.publish(socket_id .. "_disconnect", { success = false, message = "param~=0", is_retry = true })
            return
        end
        if event == socket.LINK then
            log.info("lib_smtp", socket_id, "LINK")
        elseif event == socket.ON_LINE then
            log.info("lib_smtp", socket_id, "ON_LINE")
        elseif event == socket.EVENT then
            socket.rx(netc, rxbuf)
            socket.wait(netc)
            if rxbuf:used() > 0 then recvHandler(netc, rxbuf, socket_id, getNextCommand()) end
            rxbuf:del()
        elseif event == socket.TX_OK then
            socket.wait(netc)
        elseif event == socket.CLOSE then
            log.info("lib_smtp", socket_id, "CLOSED")
            sys.publish(socket_id .. "_disconnect", { success = false, message = "服务器断开连接", is_retry = true })
        end
    end

    -- 初始化 socket
    local netc = socket.create(nil, netCB)
    socket.debug(netc, lib_smtp.socket_debug_enable)
    socket.config(netc, nil, nil, smtp_config.tls_enable)
    -- 连接 smtp 服务器
    local is_connect_success = socket.connect(netc, smtp_config.host, smtp_config.port)
    if not is_connect_success then
        socket.close(netc)
        return { success = false, message = "未知错误", is_retry = true }
    end
    -- 等待发送结果
    local is_send_success, send_result = sys.waitUntil(socket_id .. "_disconnect", lib_smtp.timeout)
    socket.close(netc)
    if is_send_success then
        return send_result
    else
        log.error("lib_smtp", socket_id, "发送超时")
        return { success = false, message = "发送超时", is_retry = true }
    end
end

return lib_smtp
