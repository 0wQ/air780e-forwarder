return {
    -- 通知类型, 支持配置多个
    -- NOTIFY_TYPE = {"telegram", "pushdeer", "bark", "dingtalk", "feishu", "wecom", "pushover", "inotify", "next-smtp-proxy", "gotify"},
    NOTIFY_TYPE = "pushdeer",
    --
    -- telegram 通知配置, https://github.com/0wQ/telegram-notify
    TELEGRAM_PROXY_API = "",
    TELEGRAM_TOKEN = "",
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
    DINGTALK_WEBHOOK = "",
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
    -- 开机通知 (会消耗流量)
    BOOT_NOTIFY = true,
    --
    -- 通知内容追加更多信息 (通知内容增加会导致流量消耗增加)
    NOTIFY_APPEND_MORE_INFO = true,
    --
    -- 通知最大重发次数
    NOTIFY_RETRY_MAX = 20,
    --
    -- 开启低功耗模式, USB 断开连接无法查看日志, RNDIS 网卡会断开
    LOW_POWER_MODE = false,
}
