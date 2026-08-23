# dsh-desktop

把 DeepSeek Harness Web（DSH）包成独立应用窗口的启动器。双击即用，无需命令行，服务后台隐形运行。

## 目录结构

| 文件 | 作用 |
|---|---|
| 启动DSH.ps1 | 主启动器：检查 Node → 查找 Edge → 补图标 → 起服务 → 开应用窗口 |
| 停止DSH.bat | 停止 DSH 服务（只杀监听 3080 端口的进程） |
| patch-icons.ps1 | 图标补丁：向 DSH 前端注入自定义图标（DSH 更新后失效，重跑即可） |
| 启动DSH.bat | 备用启动器（浏览器方式，可见窗口） |
| assets/ | icon.ico（多尺寸 16~256px 图标，唯一图标源；patch-icons.ps1 会从中提取 PNG） |
| launch.log | 启动日志，排障先看它 |

## 使用

1. 双击桌面 **DSH Desktop** 快捷方式（指向 启动DSH.ps1，隐藏运行）
2. 自动流程：检测 3080 端口 → 无服务则隐藏启动 `npx @deepseek-ai/dsh@latest web --no-open` → 打开 Edge 应用窗口（无地址栏/标签页）
3. **关掉应用窗口 ≠ 停服务**（服务继续后台运行，下次秒开）
4. 停止服务：双击 **停止DSH.bat**（或桌面 停止DSH 快捷方式）

## 新电脑部署（5 步）

1. 安装 **Node.js**（https://nodejs.org ，含 npm）
2. 拷贝本项目文件夹到目标电脑
3. 双击 `启动DSH.ps1`（首次运行联网下载 DSH 包，约 200MB，耐心等）
4. 桌面建快捷方式指向 启动DSH.ps1：
   - 目标：`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - 参数：`-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "本机路径\启动DSH.ps1"`
   - 图标：`assets\icon.ico`
5. 运行 `patch-icons.ps1` 注入窗口图标（从 assets/icon.ico 自动提取），然后**彻底退出 Edge（所有窗口）再重开**，图标才生效

## 常见问题

- **窗口图标还是 Edge 默认**：图标补丁打在每台机器自己的 npx 缓存里，新机器必须重跑 `patch-icons.ps1`；之后彻底退出 Edge 再打开
- **DSH 更新后图标丢失**：`npx @latest` 更新会覆盖 dist，重跑 `patch-icons.ps1` 即可
- **双击没反应**：看 `launch.log`。常见原因：没装 Node.js、Edge 安装在非标准路径、被杀毒软件拦截
- **端口 3080 被占用**：说明 DSH 已在运行，直接开浏览器访问 http://127.0.0.1:3080
- **停止服务安全吗**：停止DSH.bat 只杀监听 3080 的那个进程，不影响其他程序

## 依赖

- Node.js（含 npm/npx）— 必需
- Microsoft Edge — 应用窗口载体
- 首次运行需联网（下载 DSH 包）
