# Air700E / Air780E / Air780EG 短信转发

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
- [x] 开机通知
- [x] POW 按键长按短按操作
- [x] 低功耗模式 (使用 IoT Power 测量, 开发板待机 30min 平均电流 2.5mA)
- [x] 使用消息队列, 经测试同时发送几百条通知, 不会卡死
- [x] 通知发送失败, 自动重发
- [x] 支持主从模式，一主对多从，从机通过串口转发消息，主机接受消息后转发到通知服务

## :hammer: Usage

> 可以参考 [lageev](https://github.com/lageev/air780e-forwarder) 写的教程 https://kdocs.cn/l/coe1ozIlSX70

### 1. 按注释修改 `script/config.lua` 配置文件

### 2. 烧录脚本

> 固件下载 https://gitee.com/openLuat/LuatOS/releases 选择带有 EC618 或 Air780 关键字的固件
>
> `core` 目录下文件名中带有 `RNDIS` 的, 支持 RNDIS 网卡功能, 如果 SIM 卡流量不多请勿选择

根据 [air780e.cn](http://air780e.cn) 官方指引下载 LuaTools 并写入 `script` 目录下文件
