return {
    -- 通知类型 telegram, pushdeer, bark, dingtalk, feishu, wecom, next-smtp-proxy
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
    -- 定时查询流量间隔, 单位毫秒, 设置为 0 关闭
    QUERY_TRAFFIC_INTERVAL = 1000 * 60 * 60 * 6,
    --
    -- 定时基站定位间隔, 单位毫秒, 设置为 0 关闭
    LOCATION_INTERVAL = 1000 * 60 * 30
}
