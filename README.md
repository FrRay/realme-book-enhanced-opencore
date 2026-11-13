# realme Book 增强版 OpenCore EFI

[English](README.en.md) · [发行下载](https://github.com/FrRay/realme-book-enhanced-opencore/releases/tag/v0.1.0) · [适配纪要与踩坑记录](docs/build-notes.zh-CN.md)

## 〓项目说明〓

本项目收录 realme Book 增强版的 macOS Sequoia 整机适配配置。项目起于一台已有 Windows 11 的笔记本，目标是在同一块 SSD 上安装 macOS，同时保留 Windows 的启动入口和原有资料分区。参考机通过 U 盘引导 OpenCore，macOS 安装在内置 SSD 上的独立空间。遇到启动问题时，固件菜单中的 Windows Boot Manager 提供直接回退入口。

## 〓适用范围〓

| 项目 | 参考环境 |
| --- | --- |
| 机型 | realme Book 增强版 2022（CloudProXXXX），Intel Core i5-11320H |
| 显示与网络 | Intel Iris Xe、2160 × 1440 内屏、Intel Wi-Fi 6 AX201 |
| 软件 | macOS Sequoia 15.8.3（24H241，Darwin 24.6.0）、OpenCore 1.0.8 |

以下结果来自一台参考机。参考机上后续验证的改动会单独标注，发行包内容以对应版本为准。

| 模块 | 适配内容 |
| --- | --- |
| 启动 | OpenCore 菜单、macOS 安装续跑与 Windows Boot Manager 回退 |
| 核显与内屏 | WhateverXe 图形加速、内屏亮度与 PWM 调整、1080 × 720 @2× HiDPI。参考机另已验证 150% HiDPI，见[发行后实测](docs/build-notes.zh-CN.md#发行后实测)。外接显示器待验证 |
| 输入 | 内置键盘、功能键及 I²C 触控板。上游触控板驱动与参考机使用的改版存在差异 |
| 无线 | AX201 Wi-Fi 已连接；蓝牙鼠标已实测配对及关机后自动重连 |
| 音频 | 内置扬声器播放正常（AppleALC 布局 37）；内置麦克风输入电平未响应 |
| 摄像头 | Photo Booth 可显示实时预览；拍照和录像未验证 |
| 电源 | 电量和充电状态已验证。睡眠后恢复桌面仍失败，见[睡眠与唤醒实测](docs/build-notes.zh-CN.md#睡眠与唤醒实测) |

## 〓快速安装〓

`main` 收录配置模板、依赖清单和组装脚本。运行脚本前，请解压发行页单独上传的 EFI ZIP，其中包含组装所需的基础文件。

1. **准备发行包。** [发行页](https://github.com/FrRay/realme-book-enhanced-opencore/releases/tag/v0.1.0)提供 `realme-book-enhanced-opencore-v0.1.0-efi.zip` 与 `SHA256SUMS.txt`。解压前可用 `Get-FileHash -Algorithm SHA256 .\realme-book-enhanced-opencore-v0.1.0-efi.zip` 核对校验值。
2. **组装 EFI。** 在解压目录打开 PowerShell，执行下方命令。脚本从上游下载固定版本、核对 SHA-256，并生成 `EFI-ready/EFI`。默认使用 VoodooI2C 上游版，参考机的实测结果对应本机改版。
3. **填写 SMBIOS。** 使用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 为 `MacBookPro16,2` 生成独立的 `SystemSerialNumber`、`MLB`、`SystemUUID` 与 `ROM`，写入 `EFI-ready/EFI/OC/config.plist` 的 `PlatformInfo → Generic`。完成后用 [OpenCore 1.0.8](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8) 附带的 `ocvalidate` 检查配置。
4. **从 U 盘启动。** 将生成的 `EFI` 放入 FAT32 启动 U 盘根目录。在固件启动菜单中选择 U 盘，再于 OpenCore 菜单选择已安装的 macOS。首次安装时，另行准备 Apple 恢复镜像，按下方安装分支操作。
5. **安装系统内图形组件。** 在 macOS 中安装 [WhateverXe Graphics 0.4.1](https://github.com/b00t0x/WhateverXe-Graphics/releases/tag/v0.4.1) 后重启。该组件安装在 macOS 内，OpenCore 所载入的 WhateverXe Kext 与之配合。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Prepare-EFI.ps1
```

触控板出现异常时，可用 `-Touchpad Disabled -OutputDirectory EFI-keyboard-mouse` 生成临时配置，再接入外接鼠标。已有与参考机一致的个人 EFI 时，可用 `-Touchpad Personal -PersonalEfi 'E:\EFI'` 导入并校验触控板文件。`E:\EFI` 为示例路径，执行前需对应实际盘符。脚本在新目录中生成 EFI，准备完成后再手动复制至启动 U 盘。

**全新安装分支**　[OpenCore 的 Windows 安装介质指南](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/windows-install.html)提供 `macrecovery` 的 Sequoia 下载方式。`.dmg` 与 `.chunklist` 同放在 U 盘根目录的 `com.apple.recovery.boot`，在线恢复需要可用的网络连接。安装目的地为预先确认的 macOS 专用空间。首次重启后仍从 U 盘进入 OpenCore，看到内置 SSD 上的 `macOS Installer` 时继续该项，安装结束后再选 macOS 系统卷。

## 〓回退与已知限制〓

- 固件启动菜单中的 **Windows Boot Manager** 用于返回 Windows。保留 Windows EFI 与现有资料分区，另存一份可用的个人启动 U 盘配置。
- 参考机在 UEFI Secure Boot 关闭时使用此 U 盘启动。OpenCore 的 `SecureBootModel` 是另一项设置。发行配置沿用 WhateverXe Graphics 所需的 macOS SIP 设置，已启用 BitLocker 的设备在更改固件 Secure Boot 前需保留恢复密钥。[依赖与来源](docs/components.md) · [BitLocker 恢复说明](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/preboot-recovery-screen)
- 画面异常时，`-x` 可在 U 盘 OpenCore 的 `boot-args` 中临时进入安全模式。排查完成后移除该参数。更改显示驱动或缩放档位前，保留当前可用配置。

第三方组件与许可见[依赖与来源](docs/components.md)。
