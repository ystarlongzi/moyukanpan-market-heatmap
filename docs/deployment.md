# 云图独立部署

云图通过 GitHub Actions 构建 Next.js standalone 运行包，由 VPS 上的 `moyukanpan-heatmap.service` 提供页面和行情 API。服务使用 `127.0.0.1:3215`，Nginx 将独立域名转发到这个地址。下文的 `heatmap.moyukanpan.com` 是示例域名。

## 服务器准备

使用带 systemd、GNU 工具和 `/usr/bin/node` 的 Linux。建议与 Actions 一样安装 Node.js 22 LTS。运行包含平台依赖，当前 runner 的产物需要与之兼容的 Linux x64 glibc VPS。

1. 由 VPS 管理员创建 `heatmap`（运行服务，无登录 shell）和 `heatmap-deploy`（通过 SSH 发布）两个独立账号。
2. 创建云图目录，保留现有站点目录、服务和配置。

   ```sh
   sudo install -d -o heatmap-deploy -g heatmap-deploy -m 0755 /opt/moyukanpan-heatmap /opt/moyukanpan-heatmap/releases
   sudo install -d -o heatmap-deploy -g heatmap-deploy -m 0700 /opt/moyukanpan-heatmap/incoming
   ```

3. 将专用 SSH 公钥加入 `heatmap-deploy` 的 `~/.ssh/authorized_keys`。把 [sudoers 示例](../deploy/moyukanpan-heatmap.sudoers) 安装到 `/etc/sudoers.d/moyukanpan-heatmap`，用 `visudo -cf` 校验，权限设为 `0440`。这个账号只需要以 root 重启和停止云图 unit。
4. 安装 [systemd unit](../deploy/moyukanpan-heatmap.service) 到 `/etc/systemd/system/moyukanpan-heatmap.service`。运行 `sudo systemctl daemon-reload` 与 `sudo systemctl enable moyukanpan-heatmap.service`。第一次启动由 Actions 完成。
5. 为独立域名准备 DNS 和 TLS 证书，按 [Nginx 示例](../deploy/nginx.conf.example) 新增虚拟主机。替换域名和证书路径后执行 `sudo nginx -t`，成功后重载 Nginx。行情流接口关闭代理缓冲，浏览器可以逐批接收行情。

## GitHub Actions 配置

在 fork 的 **Settings → Environments** 新建 `production`。将部署权限限制到默认分支，在该环境配置以下值：

| 类型 | 名称 | 内容 |
| --- | --- | --- |
| Variable | `DEPLOY_HOST` | VPS 主机名或 IPv4 地址 |
| Variable | `DEPLOY_PORT` | SSH 端口，默认 `22` |
| Secret | `DEPLOY_SSH_PRIVATE_KEY` | 专用部署账号的完整未加密私钥 |
| Secret | `DEPLOY_KNOWN_HOSTS` | 已与管理员或 VPS 控制台核对的 SSH 主机公钥条目。使用非默认端口时，主机字段写成 `[主机]:端口` |

工作流位于 [deploy.yml](../.github/workflows/deploy.yml)，从默认分支手动运行 **发布 A 股云图**。它按锁文件安装依赖，执行 lint、类型检查和单测，构建并打包 Next.js 后再使用 SSH。没有配置凭据时，上传步骤会给出缺少的配置名称。

## 验证与回退

远端以文件锁串行发布。每次运行把产物解压到新的 `releases/<提交 SHA>-<运行 ID>-<尝试号>/`，原子切换 `current` 并重启专用服务。工作流确认 `/api/health` 返回这次发布的版本后才报告成功。失败时恢复上一个链接并重启，首次部署失败则停止失败服务并撤下链接。

发布后把以下命令中的示例域名替换成真实域名。健康接口验证应用进程，云图接口验证部署后的行情路径：

```sh
curl -fsS https://heatmap.moyukanpan.com/api/health
curl -fsS 'https://heatmap.moyukanpan.com/api/heatmap/treemap?market=all&period=day'
sudo systemctl status moyukanpan-heatmap.service
sudo journalctl -u moyukanpan-heatmap.service -n 80 --no-pager
```

健康检查返回的 `version` 应与本次发布日志一致。云图首次请求可能使用内置行情，随后用新请求检查是否切换到行情直连。历史版本留在 `releases/`，可供管理员按需回退。服务器空间需要定期巡检，清理前先确认 `current` 指向的版本和保留的回退版本。
