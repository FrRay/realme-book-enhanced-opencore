# 依赖与来源 / Components and Sources

## 〓发行包内容 / Included Files〓

v0.1.0 发行包的 OpenCore、ACPI 与机型适配组件取自参考机发布时的启动 U 盘。`PlatformInfo → Generic` 的本机身份字段使用模板。 The v0.1.0 archive contains OpenCore, ACPI, and model-specific components from the reference USB EFI at release time. Machine-specific fields in `PlatformInfo → Generic` use template values.

| 组件 / Component | 版本与来源 / Version and Source |
| --- | --- |
| OpenCore、OpenRuntime | 1.0.8 RELEASE · [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8) |
| Lilu | 1.7.2 · [Lilu](https://github.com/acidanthera/Lilu/releases/tag/1.7.2) |
| VirtualSMC、SMCBatteryManager | 1.3.8 · [VirtualSMC](https://github.com/acidanthera/VirtualSMC/releases/tag/1.3.8) |
| AppleALC | 1.9.8 · [AppleALC](https://github.com/acidanthera/AppleALC/releases/tag/1.9.8) |
| BrightnessKeys | 1.0.3 · [BrightnessKeys](https://github.com/acidanthera/BrightnessKeys/releases/tag/1.0.3) |
| WhateverXe-Keep-PWM | 参考机本地构建，基于 0.8.0。 Local build based on 0.8.0. [WhateverXe](https://github.com/b00t0x/WhateverXe/releases/tag/0.8.0) |
| RealmeNativeHiDPI、SSDT-RealmeRecovery、SSDT-PNLF-Realme | 参考机适配组件。发行后验证的 RealmeNativeHiDPI 1.2.1 见[实测记录](build-notes.zh-CN.md#发行后实测)。 Model-specific components. See [post-release testing](build-notes.en.md#post-release-testing) for RealmeNativeHiDPI 1.2.1. |

上游版权与许可文本随仓库和发行包附在 [licenses](../licenses) 目录。 Upstream notices and license texts are supplied in [licenses](../licenses).

## 〓上游下载 / Upstream Downloads〓

`Prepare-EFI.ps1` 使用 [dependencies.json](../dependencies.json) 中的地址和 SHA-256。在手动组装时，`bundles` 列出每个归档应复制的 Kext 与目标名称，`target` 指定单文件的目标位置。 The same manifest specifies the archives, checksums, destination names, and single-file paths for manual assembly.

| 组件 / Component | 版本与来源 / Version and Source |
| --- | --- |
| HfsPlus.efi | [OcBinaryData 固定版本 / pinned revision](https://github.com/acidanthera/OcBinaryData/blob/c2a98980d30e39a571a2843ab26aa8d2b9188094/Drivers/HfsPlus.efi) |
| AMFIPass | 1.4.1 Mod · [WhateverXe Graphics 附件 / extras](https://github.com/b00t0x/WhateverXe-Graphics/blob/v0.4.1/extras/AMFIPass-v1.4.1-Mod-RELEASE.zip) |
| VoodooPS2Controller | 2.3.7 · [VoodooPS2](https://github.com/acidanthera/VoodooPS2/releases/tag/2.3.7) |
| AirportItlwm | 2.4.0-alpha（7204c69）Sequoia · [laobamac/itlwm](https://github.com/laobamac/itlwm/releases/tag/v2.4.0-alpha) |
| IntelBluetoothFirmware、IntelBTPatcher | 2.5.3 · [lshbluesky/IntelBluetoothFirmware](https://github.com/lshbluesky/IntelBluetoothFirmware/releases/tag/v2.5.3) |
| BlueToolFixup | 2.7.2 · [BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM/releases/tag/2.7.2) |
| VoodooI2C、VoodooI2CHID | 上游 2.9.1 为默认下载选项。 Upstream 2.9.1 is the default download. [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C/releases/tag/v2.9.1) |

本地改版触控板驱动缺少可匹配的源码记录，原文件保存在个人 EFI。`Personal` 模式仅从现有个人副本导入匹配哈希的文件。`Upstream` 模式使用同版本上游发行件，触控板表现可能不同。 The modified touchpad drivers lack matching source records and remain in the personal EFI. `Personal` imports only files matching the reference hashes. `Upstream` uses the upstream release and may behave differently. [VoodooI2C project license](https://github.com/VoodooI2C/VoodooI2C) · [GNU GPL FAQ](https://www.gnu.org/licenses/gpl-faq.html#DistributeExtendedBinary)

## 〓系统内图形组件 / In-system Graphics Package〓

[WhateverXe Graphics 0.4.1](https://github.com/b00t0x/WhateverXe-Graphics/releases/tag/v0.4.1) 由上游单独提供，安装至 macOS。其参考 SHA-256 为 `7f7ce3b924ad421cff0c4f30534598858474b8c9539c4b889a461bc1d5fed02c`。配套设置为 AMFIPass 1.4.1 Mod 与 `csr-active-config=03080000`（`0x803`）。 The Graphics package is installed in macOS and uses the matching AMFIPass Mod and SIP configuration. [WhateverXe Graphics documentation](https://github.com/b00t0x/WhateverXe-Graphics)
