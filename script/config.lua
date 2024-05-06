return {
    -- 通知类型, 支持配置多个
    -- NOTIFY_TYPE = { "custom_post", "telegram", "pushdeer", "bark", "dingtalk", "feishu", "wecom", "pushover", "inotify", "next-smtp-proxy", "gotify", "serial" },
    NOTIFY_TYPE = "custom_post",
    --
    -- 角色类型, 用于区分主从机, 仅当使用串口转发 NOTIFY_TYPE = "serial" 时才需要配置
    -- MASTER: 主机, 可主动联网; SLAVE: 从机, 不可主动联网, 通过串口发送数据
    ROLE = "MASTER",
    --
    -- custom_post 通知配置, 自定义 POST 请求, CUSTOM_POST_BODY_TABLE 中的 {msg} 会被替换为通知内容
    CUSTOM_POST_URL = "https://sctapi.ftqq.com/<SENDKEY>.send",
    CUSTOM_POST_CONTENT_TYPE = "application/json",
    CUSTOM_POST_BODY_TABLE = { ["title"] = "这里是标题", ["desp"] = "这里是内容, 会被替换掉:\n{msg}\n{msg}" },
    --
    -- telegram 通知配置, https://github.com/0wQ/telegram-notify 或者自行反代
    TELEGRAM_API = "https://api.telegram.org/bot{token}/sendMessage",
    TELEGRAM_CHAT_ID = "",
    --
    -- pushdeer 通知配置, https://www.pushdeer.com/
    PUSHDEER_API = "https://api2.pushdeer.com/message/push",
    PUSHDEER_KEY = "",
    --
    -- bark 通知配置, https://github.com/Finb/Bark
    BARK_API = "https://api.day.app",
    BARK_KEY = "",
    --
    -- dingtalk 通知配置, https://open.dingtalk.com/document/robots/custom-robot-access
    -- 如果是加签方式, 请填写 DINGTALK_SECRET, 否则留空为自定义关键词方式, https://open.dingtalk.com/document/robots/customize-robot-security-settings
    DINGTALK_WEBHOOK = "",
    DINGTALK_SECRET = "",
    --
    -- feishu 通知配置, https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN
    FEISHU_WEBHOOK = "",
    --
    -- wecom 通知配置, https://developer.work.weixin.qq.com/document/path/91770
    WECOM_WEBHOOK = "",
    --
    -- pushover 通知配置, https://pushover.net/api
    PUSHOVER_API_TOKEN = "",
    PUSHOVER_USER_KEY = "",
    --
    -- inotify 通知配置, https://github.com/xpnas/Inotify 或者使用合宙提供的 https://push.luatos.org
    INOTIFY_API = "https://push.luatos.org/XXXXXX.send",
    --
    -- next-smtp-proxy 通知配置, https://github.com/0wQ/next-smtp-proxy
    NEXT_SMTP_PROXY_API = "",
    NEXT_SMTP_PROXY_USER = "",
    NEXT_SMTP_PROXY_PASSWORD = "",
    NEXT_SMTP_PROXY_HOST = "smtp-mail.outlook.com",
    NEXT_SMTP_PROXY_PORT = 587,
    NEXT_SMTP_PROXY_FORM_NAME = "Air780E",
    NEXT_SMTP_PROXY_TO_EMAIL = "",
    NEXT_SMTP_PROXY_SUBJECT = "来自 Air780E 的通知",
    --
    -- smtp 通知配置(可能不支持加密协议)
    SMTP_HOST = "smtp.qq.com",
    SMTP_PORT = 25,
    SMTP_USERNAME = "",
    SMTP_PASSWORD = "",
    SMTP_MAIL_FROM = "",
    SMTP_MAIL_TO = "",
    SMTP_MAIL_SUBJECT = "来自 Air780E 的通知",
    SMTP_TLS_ENABLE = false,
    --
    -- gotify 通知配置, https://gotify.net/
    GOTIFY_API = "",
    GOTIFY_TITLE = "Air780E",
    GOTIFY_PRIORITY = 8,
    GOTIFY_TOKEN = "",
    --
    -- 定时查询流量间隔, 单位毫秒, 设置为 0 关闭 (建议检查 util_mobile.lua 文件中运营商号码和查询代码是否正确, 以免发错短信导致扣费, 收到查询结果短信发送通知会消耗流量)
    QUERY_TRAFFIC_INTERVAL = 0,
    --
    -- 定时基站定位间隔, 单位毫秒, 设置为 0 关闭 (定位成功后会追加到通知内容后面, 基站定位本身会消耗流量, 通知内容增加也会导致流量消耗增加)
    LOCATION_INTERVAL = 0,
    --
    -- 定时开关飞行模式间隔, 单位毫秒, 设置为 0 关闭
    FLYMODE_INTERVAL = 1000 * 60 * 60 * 12,
    --
    -- 定时同步时间间隔, 单位毫秒, 设置为 0 关闭
    SNTP_INTERVAL = 1000 * 60 * 60 * 6,
    --
    -- 定时上报间隔, 单位毫秒, 设置为 0 关闭 (定时触发消息上报)
    REPORT_INTERVAL = 0,
    --
    -- 开机通知 (会消耗流量)
    BOOT_NOTIFY = true,
    --
    -- 通知内容追加更多信息 (通知内容增加会导致流量消耗增加)
    NOTIFY_APPEND_MORE_INFO = true,
    --
    -- 通知最大重发次数
    NOTIFY_RETRY_MAX = 20,
    --
    -- 本机号码, 优先使用 mobile.number() 接口获取, 如果获取不到则使用此号码
    FALLBACK_LOCAL_NUMBER = "+8618888888888",
    --
    -- SIM 卡 pin 码
    PIN_CODE = "",
}
