#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

root=/opt/moyukanpan-heatmap
unit=moyukanpan-heatmap.service
release=${1:?缺少发布版本}
release_pattern='^[0-9a-f]{40}-[0-9]+-[0-9]+$'
current="$root/current"

fail() {
  printf '云图部署失败：%s\n' "$*" >&2
  exit 1
}

[[ "$release" =~ $release_pattern ]] || fail '版本格式不正确'
[[ "$(uname -s)" == Linux && "$(id -un)" == heatmap-deploy ]] || fail '请使用 heatmap-deploy 登录 Linux 服务器'
for command in curl flock install mktemp readlink sudo tar; do
  command -v "$command" >/dev/null || fail "缺少命令 $command"
done
[[ -x /usr/bin/node && -x /usr/bin/systemctl ]] || fail '找不到 Node.js 或 systemd'
/usr/bin/node -e 'if (Number(process.versions.node.split(".")[0]) < 22) process.exit(1)' || fail '需要 Node.js 22 或更新版本'

archive="$root/incoming/$release.tar.gz"
version_dir="$root/releases/$release"
[[ -f "$archive" && ! -L "$archive" ]] || fail '缺少已上传的运行包'
exec 9>"$root/.deploy.lock"
flock -w 120 9 || fail '另一个部署尚未结束'
[[ ! -e "$version_dir" && ! -L "$version_dir" ]] || fail '版本目录已存在'

previous=''
if [[ -L "$current" ]]; then
  previous=$(readlink "$current")
  [[ "$previous" == "$root/releases/"* && "${previous##*/}" =~ $release_pattern &&
    "$previous" == "$root/releases/${previous##*/}" && -f "$previous/server.js" ]] ||
    fail 'current 未指向有效的历史版本'
elif [[ -e "$current" ]]; then
  fail 'current 不是软链接'
fi

staging=''
switch_dir=$(mktemp -d "$root/.switch.XXXXXX")
switched=0

switch_current() {
  ln -s -- "$1" "$switch_dir/current"
  mv -Tf -- "$switch_dir/current" "$current"
}

wait_healthy() {
  local expected=$1 attempt
  for ((attempt = 1; attempt <= 20; attempt++)); do
    if curl --fail --silent --noproxy '*' --max-time 2 http://127.0.0.1:3215/api/health |
      /usr/bin/node -e '
        const fs = require("node:fs");
        try {
          const body = JSON.parse(fs.readFileSync(0, "utf8"));
          if (body.service !== "moyukanpan-heatmap" || body.version !== process.argv[1]) process.exitCode = 1;
        } catch {
          process.exitCode = 1;
        }
      ' "$expected"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  set +e
  if ((status != 0 && switched)); then
    printf '新版本未通过健康检查，正在回退\n' >&2
    if [[ -n "$previous" ]]; then
      rm -f -- "$switch_dir/current"
      if ! switch_current "$previous" ||
        ! sudo -n /usr/bin/systemctl restart "$unit" ||
        ! wait_healthy "${previous##*/}"; then
        printf '回退失败，请在服务器检查 %s\n' "$unit" >&2
      fi
    else
      sudo -n /usr/bin/systemctl stop "$unit" || printf '停止首次部署的服务失败\n' >&2
      rm -f -- "$current"
    fi
  fi
  [[ -z "$staging" ]] || rm -rf -- "$staging"
  rm -rf -- "$switch_dir"
  rm -f -- "$archive"
  exit "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

staging=$(mktemp -d "$root/releases/.upload.XXXXXX")
tar --extract --gzip --file "$archive" --directory "$staging" --no-same-owner --no-same-permissions
[[ -f "$staging/server.js" && -d "$staging/.next/static" && -d "$staging/public" ]] || fail '运行包结构不完整'
printf 'HEATMAP_RELEASE=%s\n' "$release" > "$staging/release.env"
chmod 0755 "$staging"
mv -T -- "$staging" "$version_dir"
staging=''

switched=1
switch_current "$version_dir"
sudo -n /usr/bin/systemctl restart "$unit"
wait_healthy "$release" || fail '新进程未返回预期的发布版本'
switched=0
printf '云图发布完成：%s\n' "$release"
