# 摸鱼看盘 · A 股云图

独立的 Next.js 网页。色块面积表示流通市值，颜色表示所选周期的涨跌幅。页面支持按市场和行业浏览、管理自选、缩放、全屏和截图。

## 本地运行

使用 Node.js 22 或更新版本。进入本目录后执行：

```sh
pnpm install --frozen-lockfile
pnpm dev --hostname 127.0.0.1 --port 3215
```

打开 [http://127.0.0.1:3215/](http://127.0.0.1:3215/)。

## 数据和验证

行情接口位于 `src/app/api/heatmap`。服务端沿用上游取数和缓存逻辑，优先使用腾讯行情，按覆盖情况由新浪、东方财富补充。同花顺提供部分市场统计。内置快照用于冷启动和失败兜底，行情日期以页面显示为准。

```sh
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

Canvas 云图和行情实现基于 [wenyuanw/a-share-heatmap 722d8e6](https://github.com/wenyuanw/a-share-heatmap/tree/722d8e692009ef77fc195f46361b0550e6319e84)，原始版权和许可见 [LICENSE](LICENSE)。

## VPS 部署

独立服务的首次配置、GitHub Actions 变量和回退方式见 [部署说明](docs/deployment.md)。

## 同步上游

独立仓库的 `upstream` 指向 dapan.app 源码。定期拉取上游，再按需合入云图、行情和安全更新：

```sh
git fetch upstream
git diff --stat 722d8e692009ef77fc195f46361b0550e6319e84 upstream/main
```

- `src/app/api/heatmap` 和 `src/lib/market-heatmap.ts` 当前沿用上游，可以直接对比取数变化。更新内置快照时，同时检查行业分类和股票池文件是否对应。
- 合并 `src/app/layout.tsx`、`src/components/market-heatmap.tsx`、`src/components/heatmap` 或 `src/lib/i18n.ts` 的变化时，保留本地品牌、官网链接和分享样式。上游推广页和访问统计从本地版本移除。
- 合入后重跑上述检查，并验证当日云图先返回内置快照、随后切到行情直连。全量更新时修改本文的基线提交，单独合入补丁时记录其上游提交。
