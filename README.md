# Air700E / Air780E / Air780EP / Air780EPV 短信转发 来电通知

## :sparkles: Feature

- [x] 多种通知方式
    - [x] [Telegram](https://github.com/0wQ/telegram-notify)
    - [x] [PushDeer](https://www.pushdeer.com/)
    - [x] [Bark](https://github.com/Finb/Bark)
    - [x] [钉钉群机器人 DingTalk](https://open.dingtalk.com/document/robots/custom-robot-access)
    - [x] [飞书群机器人 Feishu](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN)
    - [x] [企业微信群机器人 WeCom](https://developer.work.weixin.qq.com/document/path/91770)
    - [x] [Pushover](https://pushover.net/api)
    - [x] [邮件 next-smtp-proxy](https://github.com/0wQ/next-smtp-proxy)
    - [x] [Gotify](https://gotify.net)
    - [x] [Inotify](https://github.com/xpnas/Inotify) / [合宙官方的推送服务](https://push.luatos.org)
    - [x] 邮件 (SMTP协议)
- [x] 通过短信控制设备
    - [x] 发短信, 格式: `SMS,10010,余额查询`
- [x] 定时基站定位
- [x] 定时查询流量
- [x] 定时上报存活
- [x] 开机通知
- [x] POW 按键长按短按操作
- [x] 使用消息队列, 测试添加几百条通知, 不会卡死
- [x] 通知发送失败, 自动重发, 断电后再次开机可以恢复重发
- [x] 支持主从模式，一主对多从，从机通过串口转发消息，主机接受消息后转发到通知服务

## :hammer: Usage

https://mizore.notion.site/Air780E-e750efe0d6cc40c3baa276eeb811d534

