# Windows AI EDA Workflow

一套在 Windows 10/11 上可复现的 AI 辅助电子设计流程：

`SPICE 仿真 -> KiCad 10 原理图/PCB -> ERC/DRC -> Gerber -> 嘉立创报价/生产`

它保存流程、脚本、Codex Skill 和一个已验证示例，不复制第三方软件或厂商宏模型。

## 已验证基线

| 工具 | 本机已验证版本 |
|---|---|
| KiCad | 10.0.5 x64 |
| mixelpixx KiCAD-MCP-Server | 2.6.0，commit `0dc3ee8` |
| ngspice | 本机 42+ Windows x64/KLU；新装推荐官方稳定版 46 |
| LTspice | 26.0.2.1 |
| 嘉立创 EDA 专业版 | 3.2.175 |
| easyeda-agent | 已验证 0.21.2；上游最新 0.21.4；CLI、连接器、Skill 必须同版 |
| Node.js | 24.13.1（MCP 至少建议 Node 20） |

## 新电脑最快复现

```powershell
git clone https://github.com/sutony1/windows-ai-eda-workflow.git
cd windows-ai-eda-workflow
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\skills\windows-ai-eda-workflow\scripts\Test-AiEdaEnvironment.ps1
```

然后按 [Windows 安装说明](docs/windows-setup.md) 安装工具并重启 Codex。

旧版压缩包迁移说明中的原句也继续适用：**解压到其他机器的 `%USERPROFILE%\.codex\skills\` 后，按新文档安装 ngspice 与 KiCad MCP、重启 Codex 即可。** 使用 GitHub 时，推荐运行本仓库的 `install.ps1`，这样旧 Skill 会先被移入可恢复的备份目录。

可以直接把下面这段交给另一台电脑上的 Codex：

```text
请克隆 https://github.com/sutony1/windows-ai-eda-workflow，阅读 README，安装其中三个 Codex Skills，
运行环境检查，并按验证基线配置 KiCad 10、mixelpixx KiCad MCP、ngspice、LTspice、
嘉立创 EDA 专业版和 easyeda-agent。不要替我提交任何生产订单。
```

安装后也可以说：

```text
使用 $windows-ai-eda-workflow 检查这台电脑并恢复 SPICE -> KiCad 10 -> 嘉立创工作流。
```

## 仓库内容

- `skills/windows-ai-eda-workflow/`：跨工具安装、诊断、交付和迁移 Skill。
- `skills/kicad-ct-rms-pcb/`：5 V、0–300 mVrms、50 Hz CT RMS-to-DC 专项 Skill。
- `skills/kicad-ct-simulation/`：此前 KiCad 9/ngspice 阶段的历史 Skill，保留版本陷阱与旧机迁移经验。
- `examples/ct-rms-to-dc/`：KiCad 10 工程、仿真、示波器自动测试和已验证 Gerber。
- `tools/easyeda-conversion-forensics/`：本项目曾用于诊断/修复转换结果的源码；不是标准生产路径。
- `docs/`：安装、设计、EasyEDA/嘉立创和迁移说明。

## 重要边界

KiCad 工程是设计源；EasyEDA 导入件只用于可视化或二次重建。转换后的原理图如果网表为空、元件丢失或 DRC 大量报 `F.Fab` 文字冲突，不能当作正式电气源。裸板下单优先上传由 KiCad 生成并检查过的 Gerber ZIP。

本项目不会自动提交嘉立创订单，不包含 Analog Devices 的 LTC1967 宏模型，也不代替市电安全、绝缘、爬电距离和认证设计。

## 许可证

本仓库自有文档、脚本和示例采用 MIT License。第三方工具、库和厂商模型按各自许可证使用，详见 [THIRD_PARTY.md](THIRD_PARTY.md)。
