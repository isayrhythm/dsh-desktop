# dsh-desktop

<img src="assets/icon.png" width="96" height="96" alt="icon">

把 DeepSeek Harness Web（DSH）包成独立应用窗口的启动器。双击即用，无需命令行，服务后台隐形运行，**使用本地已下载的 DSH**。

## 目录结构

| 文件 | 作用 |
|---|---|
| 启动DSH.ps1 | 唯一启动器：检查 3080 端口 → 用本地已下载的 DSH 起服务（隐藏窗口，不联网）→ 打开 Edge 应用窗口 |
| patch-icons.ps1 | 图标补丁：向 DSH 前端注入自定义图标（DSH 更新后失效，重跑即可） |
| assets/ | icon.ico（多尺寸 16~256px 图标，唯一图标源；patch-icons.ps1 会从中提取 PNG） |
| launch.log | 启动日志，排障先看它（已被 .gitignore 忽略） |

> 已移除 `停止DSH.bat` / `启动DSH.bat`：停止服务没必要做成一键脚本（见下文"停止服务"），旧的 bat 备用启动器与 ps1 重复且依赖 npx 联网，一并删除。

## 使用

1. 双击桌面 **DSH Desktop** 快捷方式（指向 启动DSH.ps1，隐藏运行）
2. 自动流程：检测 3080 端口 → 无服务则用本地已下载的 DSH 隐藏启动 `node <本地 bin.js> web --no-open`（**约 4 秒，不弹窗、不下载**）→ 打开 Edge 应用窗口（无地址栏/标签页）
3. **关掉应用窗口 ≠ 停服务**（服务继续后台运行，下次秒开）

## 停止服务

本项目设计为"关窗口不停服务"。如需彻底停止后台服务（任务管理器方式）：

- 任务管理器 → 结束占用 3080 端口的 node.exe 进程；或
- 命令行：
  ```
  netstat -ano | findstr :3080
  taskkill /f /pid <上面查到的PID>
  ```

## 新电脑部署（5 步）

1. 安装 **Node.js**（https://nodejs.org ，含 npm）
2. 拷贝本项目文件夹到目标电脑
3. **一次性手动安装 DSH**（启动器本身不会联网下载，必须先在命令行执行一次）：
   ```
   npx --yes @deepseek-ai/dsh@latest web --no-open
   ```
   等它下载完并起服务后，关掉该窗口即可（以后启动器都用这份本地包，秒开）
4. 桌面建快捷方式指向 启动DSH.ps1：
   - 目标：`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - 参数：`-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "本机路径\启动DSH.ps1"`
   - 图标：`assets\icon.ico`
5. 运行 `patch-icons.ps1` 注入窗口图标，然后**彻底退出 Edge（所有窗口）再重开**，图标才生效

## 如何更新 DSH

启动器不会自动更新。想升级时手动执行一次上面的 npx 命令（联网下载新版），完成后重跑 `patch-icons.ps1`（更新会覆盖 dist 导致图标丢失）。

## 常见问题

- **双击没反应**：看 `launch.log`。常见原因：没装 Node.js、本地没有 DSH 包（日志会提示手动安装命令）、Edge 安装在非标准路径
- **为什么启动器不自己下载 DSH**：刻意设计，避免重复下载和 npx 联网卡死。首次安装请按"新电脑部署"第 3 步手动执行一次
- **窗口图标还是 Edge 默认**：图标补丁打在每台机器自己的 npx 缓存里，新机器必须重跑 `patch-icons.ps1`；之后彻底退出 Edge 再打开
- **DSH 更新后图标丢失**：重跑 `patch-icons.ps1` 即可
- **端口 3080 被占用**：说明 DSH 已在运行，直接开浏览器访问 http://127.0.0.1:3080

## 依赖

- Node.js（含 npm/npx）— 必需（运行已下载的 DSH 包）
- Microsoft Edge — 应用窗口载体
- 本地已下载的 DSH 包 — 启动器**不会**联网下载，首次需手动安装一次
