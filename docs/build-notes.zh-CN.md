# 「realme Book 增强版 OpenCore EFI」适配纪要

[返回项目首页](../README.md) · [English](build-notes.en.md)

## 〓项目由来〓

参考机原有 Windows 11 与 C、D 数据卷，内部仅有一块 SSD。安装前先查看磁盘布局和设备加密状态，再由机主从现有空间划出约 80 GB。64 GB KIOXIA U 盘承担安装与 OpenCore 引导。保留独立的 Windows Boot Manager，使 macOS 调试期间仍可直接回到原系统。

## 〓关键踩坑〓

| 阶段 | 实际遇到的现象 | 处理思路 |
| --- | --- | --- |
| 准备启动盘 | 固件菜单起初只显示 Windows Boot Manager。插入 U 盘后，存在 U 盘与存在可启动的 EFI 是两个检查点。 | 检查 FAT32 分区和 `EFI/BOOT/BOOTx64.efi`。使用固件的一次性启动菜单选择 USB。 |
| 加载恢复环境 | OpenCore 可以启动，选中外置恢复镜像后却显示苹果禁止符号。 | 核对恢复镜像版本、OpenCore 机型与引导设置。该符号提示所选版本或构建的兼容性问题，照片本身不足以定位到单一设置。[Apple 对禁止符号的说明](https://support.apple.com/en-us/101666) |
| 续跑安装 | 首次安装显示约 29 分钟，重启回到 Windows，随后又出现找不到内置安装项的问题。 | 先通过固件菜单重新进入 U 盘 OpenCore。核对内置 SSD 的扫描范围，再选择内置 `macOS Installer` 续装。安装项消失后改选 macOS 系统卷。[OpenCore 安装阶段说明](https://dortania.github.io/OpenCore-Install-Guide/installation/installation-process.html) |
| 获得基础桌面 | 内屏能显示原生分辨率，但系统报告仅 11 MB 显存，画面与动画表现受限。 | 分开记录基本显示与硬件加速。保持一份能进入桌面的 USB 配置，再核对 WhateverXe、系统内 Graphics 安装包及对应系统构建。 |
| 核显调试 | 尝试过启动重启、背光亮但黑屏，以及日志中出现 Xe 加速器启动后未显示桌面。 | 核对低 DVMT 适配、eDP 内屏及驱动组合。内核 panic、GPU 初始化和进入图形界面时的黑屏分别根据日志与实机表现判断。 |
| 构建修改版 | 早期编译停在 Lilu 的 `hde64.h`。编译器读到的是一行相对路径。 | 该现象与归档或复制过程将符号链接变成普通文件一致。源码构建需保留链接结构，普通安装使用固定的发行件。 |
| 内屏与功能键 | 亮度、PWM 范围与系统缩放需要分别处理。追加试验缩放档位后出现黑屏。 | 核对 PNLF、PWM、BrightnessKeys 和显示模式，回到此前可用的组合。OpenCore 快捷键未进入安全模式时，在 U 盘配置里临时加入 `-x`，排查后移除。 |
| 触控板、无线与音频 | 可启动桌面之后，内置设备仍需逐项适配。触控板涉及中断和超时；Wi-Fi 与蓝牙需各自的驱动组合。 | 使用 I²C 驱动及触控板插件，锁定 AX201 Wi-Fi 与 Intel 蓝牙发行件，采用 AppleALC 布局 37，加入电池管理组件。改版触控板和上游版的区别见[依赖与来源](components.md)。 |
| 发布 | 同一 U 盘积累了阶段备份、诊断与实验版本。 | 以生效 EFI 为底稿，清除本机 SMBIOS 标识，按启用的组件编制发行包，保留 Windows 回退路径和依赖校验值。 |

## 发行后实测

- **150% HiDPI。** 参考机使用本地 `RealmeNativeHiDPI.kext` 1.2.1 正常进入桌面，macOS 报告「看起来像 1440 × 960」并以 2880 × 1920 渲染，内屏物理分辨率为 2160 × 1440。这是发行后的实测结果，`v0.1.0` 发行包未包含此版本。
- **125% HiDPI 故障。** 多档试验版在选中「看起来像 1728 × 1152」后黑屏，随后普通启动也进不了桌面。安全模式仍可进入。恢复时备份了 EFI 和显示偏好，换回已验证的 1.1.0，移除保存的失败显示档位，再确认普通启动。仅替换驱动可能留下失败档位。调整前请保留可启动 EFI，并准备从 Windows 或安全模式恢复。
- **内置设备。** 扬声器可播放，Photo Booth 有实时预览，内置麦克风电平未响应。蓝牙用 VXE R1 S 验证了配对及鼠标关机后自动重连。参考机的 Goodix 触控板使用改版 VoodooI2C/VoodooI2CHID，慢划卡顿和跳动已在参考机上解决。当前文件与 `Personal` 模式的 15 项哈希一致，上游默认模式的表现需单独验证。
- **防止误点系统更新。** 参考机关闭了自动检查、下载和安装，另外通过本地描述文件停用「系统设置 → 通用 → 软件更新」按钮。描述文件使用 `com.apple.systempreferences` 的 `DisabledSystemSettings`，目标为 `com.apple.Software-Update-Settings.extension`，无需常驻脚本。移除该描述文件可恢复界面入口。终端或独立安装器仍可手动更新。[Apple 描述文件规范](https://github.com/apple/device-management/blob/release/mdm/profiles/com.apple.systempreferences.yaml)

## 睡眠与唤醒实测

参考机在 Sequoia 15.8.3（24H241）上从苹果菜单进入睡眠后，无法恢复桌面，需要强制关机。进入 macOS 后拔掉 OpenCore 启动 U 盘也能复现。关闭休眠写盘、待机、Power Nap、睡眠网络保活和近距离唤醒后，仍出现 `Sleep Wake failure in EFI`（`0x1F`）。

本地试验通过 ACPI 补丁向 macOS 暴露固件的 `PEPD` 电源设备，并加载 S0ixStandby 0.4.0。macOS 报告 `IOPMDeepIdleSupported = Yes`，桌面上的电源策略查询返回类型 7（Deep Idle）。这个查询只反映当时的策略。暂停 S0ixStandby 的固件电源调用后，仍需要强制关机。那一轮日志记录了息屏和显示驱动开始恢复，但没有留下完整的整机睡眠及唤醒记录。

相近的 Tiger Lake-H35 / Iris Xe `9A49` 机型有内屏唤醒成功的报告，接入已开启的 HDMI 显示器后仍会卡死。本机已核对上游讨论中的 eDP 补丁所检查的驱动函数位置和关键字节，实际加载与唤醒仍待验证。这里记录的是发行后试验，`v0.1.0` 没有包含这些改动。 [WhateverXe #43](https://github.com/b00t0x/WhateverXe/issues/43) · [WhateverXe #59](https://github.com/b00t0x/WhateverXe/issues/59) · [S0ixStandby #3](https://github.com/labrouss/S0ixStandby/issues/3)

## 〓复现顺序〓

可重复的顺序为 U 盘引导、确认 Windows 回退、完成 macOS 安装、配套启用图形组件，随后验证内置设备。已有 macOS 的同机型可直接从[快速安装](../README.md)组装 EFI。
