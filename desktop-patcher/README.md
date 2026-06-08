# AnythingLLM Desktop 一键修复补丁

修复 AnythingLLM 桌面版的已知 Bug，让软件更稳定。

## 三步搞定

1. **下载** — 从 [Releases](https://github.com/heihei999/anythingllm-reliable/releases) 下载补丁包，解压到任意文件夹
2. **双击** `patcher.bat`
3. **完成** — 重新打开 AnythingLLM

整个过程约 10-30 秒，不需要任何额外操作。

## 前置条件

- **AnythingLLM 桌面版** — 从 https://anythingllm.com 下载安装
- **Node.js** — 从 https://nodejs.org/ 下载 LTS 版本，安装后**重启电脑**

没装 Node.js？双击补丁会提示你去下载，不会报一堆看不懂的英文。

## 数据安全

补丁**只修改程序文件**，你的聊天记录、文档、设置都保存在另一个目录，完全不受影响。

## 怎么恢复原版

在 AnythingLLM 安装目录的 `resources` 文件夹下，找到 `app.asar.bak`，改名为 `app.asar` 即可。

## 常见问题

**"npx 不是内部或外部命令"** → Node.js 没装好，重新安装后重启电脑

**"app.asar not found"** → AnythingLLM 没装在默认路径，或没安装桌面版

**"拒绝访问"** → 先关闭 AnythingLLM（托盘区右键退出），还不行就右键 patcher.bat → 以管理员身份运行
