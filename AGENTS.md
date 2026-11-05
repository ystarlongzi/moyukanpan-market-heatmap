<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

## 在摸鱼盯盘仓库中维护

- 本目录是独立 Next.js 应用。`src/app` 管理页面与行情 API，`src/components/heatmap` 管理 Canvas 图表与交互，`src/lib` 管理取数和本地快照。
- 保留上游 Tailwind CSS 和全局样式约定。新增组件专属样式随组件维护。
- 沿用上游 pnpm 锁文件、ESLint flat config 和 TypeScript strict 配置。运行 `pnpm lint`、`pnpm typecheck`、`pnpm test` 和 `pnpm build` 验证。
- 源码取自上游 MIT 版本，项目内保留原始许可证。参考 README 记录的版本，方便核对上游更新。
- 上游云图主组件与行情模块保留原有边界和实现。独立维护新的功能时按职责拆分，方便和上游版本核对。

## 提交约定

- Git 提交信息的标题和正文统一使用中文，不使用 `feat:`、`fix:` 等英文前缀。
- 用户要求整理提交历史时，合并调试过程中的零碎提交，保留有效代码修改，并使用清晰的中文说明。
