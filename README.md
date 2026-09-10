# SekerCallMe

让局域网里的 Codex 在完成重要工作或需要你处理问题时，通过同一个 MCP 让这台 Mac 直接开口提醒你。手机和浏览器通知只是可选项。

它组合了三个成熟组件：

- [ntfy](https://github.com/binwiederhier/ntfy)：保存并推送通知；
- [ntfy-mcp-server](https://github.com/cyanheads/ntfy-mcp-server)：给 Codex 提供通知工具；
- Caddy：给局域网 MCP 入口加访问令牌。

服务只绑定自动检测到的局域网地址，不监听其他主机网卡。默认使用 HTTP，适合你信任的家庭或工作室局域网；不要在路由器上做公网端口映射。网络里有不可信设备时，应放到 Tailscale/WireGuard 或 HTTPS 反向代理后面。

## 服务端安装

需要 macOS，以及 Docker、Docker Compose、curl、jq 和 openssl。

```bash
make init
make voice-install
```

命令会生成随机密码和令牌、启动服务、创建仅能访问一个通知主题的 ntfy 用户，并执行冒烟测试。生成的秘密保存在 `.env`，不会提交到 Git。

`make voice-install` 会安装当前 macOS 用户的 LaunchAgent。它登录后自动运行，订阅通知并用系统中文语音念出标题和正文，不需要配置手机或保持浏览器打开。

需要换声音或语速时，可在 `.env` 设置 `SEKER_VOICE` 和 `SEKER_VOICE_RATE`，然后重新运行 `make voice-install`。系统声音名称可用 `say -v '?'` 查看。

立即试听：

```bash
make voice-test
```

## 连接一台 Codex

`make init` 会生成 `runtime/codex-config.toml`。把其中内容追加到目标机器的 `~/.codex/config.toml`，然后重启该机器上的 Codex 客户端。

为了告诉 Codex 什么时候值得出声，把 `client/AGENTS.notification.md` 的内容加入目标机器的全局 `~/.codex/AGENTS.md`。默认策略会在重要或耗时任务完成、以及需要你介入的阻塞时自主提醒；普通问答和小操作保持安静。

Codex Desktop、CLI 和 IDE 在同一台主机上共享 MCP 配置；不同局域网机器仍需各配置一次。

## 可选的强制完成通知

MCP 工具由模型主动调用，因此不是绝对可靠。若每个完成回合都必须提醒，可把 `client/codex-notify.sh` 安装到每台机器，并在 `~/.codex/config.toml` 配置：

```toml
notify = ["/absolute/path/to/codex-notify.sh"]
```

脚本需要以下环境变量：`SEKER_NTFY_URL`、`SEKER_NTFY_TOPIC`、`SEKER_NTFY_USER`、`SEKER_NTFY_PASSWORD`。如果已有 `notify` 命令，不要直接覆盖，应使用一个包装脚本依次调用两者。

## 常用命令

```bash
make status
make logs
make check
make smoke
make voice-status
make voice-test
make down
```

## iPhone 注意事项

纯局域网自托管 ntfy 在 iPhone 后锁屏时可能延迟。需要即时推送时，在 `.env` 设置：

```dotenv
NTFY_UPSTREAM_BASE_URL=https://ntfy.sh
```

随后运行 `make up`。上游只接收轮询提示，不接收实际通知正文；手机仍需要能访问你的局域网 ntfy 地址。
