# OpenCore EFI for the realme Book Enhanced Edition

[简体中文](README.md) · [Release downloads](https://github.com/FrRay/realme-book-enhanced-opencore/releases/tag/v0.1.0) · [Build notes and pitfalls](docs/build-notes.en.md)

## 〓Project Overview〓

This project packages a macOS Sequoia configuration for the realme Book Enhanced Edition. It began with a laptop already running Windows 11. The goal was to install macOS on the same SSD while retaining the Windows boot entry and existing data partitions. OpenCore runs from a USB drive, and macOS resides in dedicated space on the internal SSD. The firmware's Windows Boot Manager entry provides a direct fallback when macOS has trouble starting.

## 〓Compatibility〓

| Item | Reference setup |
| --- | --- |
| Model | realme Book Enhanced Edition (CloudProXXXX), Intel Core i5-11320H |
| Graphics and wireless | Intel Iris Xe, 2160 × 1440 internal panel, Intel Wi-Fi 6 AX201 |
| Software | macOS Sequoia 15.8.3 (24H241, Darwin 24.6.0), OpenCore 1.0.8 |

The configuration was checked by hand on one reference unit. Results may differ on other models, macOS updates, and peripheral combinations.

| Area | Configuration |
| --- | --- |
| Boot | OpenCore picker, macOS installation stages, and Windows Boot Manager fallback |
| Graphics and panel | WhateverXe, brightness and PWM adjustments, and 1080 × 720 @2× HiDPI. External display compatibility remains undocumented |
| Input | Built-in keyboard, function keys, and I²C touchpad. The upstream touchpad build differs from the local build used on the reference unit |
| Wireless | AX201 Wi-Fi, Intel Bluetooth firmware, and BlueToolFixup |
| Audio | AppleALC with layout ID 37 |
| Power | Battery support through SMCBatteryManager. Sleep and wake compatibility remain undocumented |

## 〓Quick Start〓

1. **Release files.** The [release page](https://github.com/FrRay/realme-book-enhanced-opencore/releases/tag/v0.1.0) contains `realme-book-enhanced-opencore-v0.1.0-efi.zip` and `SHA256SUMS.txt`. The archive can be checked with `Get-FileHash -Algorithm SHA256 .\realme-book-enhanced-opencore-v0.1.0-efi.zip` before extraction.
2. **EFI assembly.** The command below runs in PowerShell from the extracted folder. It downloads pinned upstream files, checks SHA-256, and generates `EFI-ready/EFI`. The default is upstream VoodooI2C. Hands-on validation on the reference unit used the local touchpad build.
3. **SMBIOS setup.** [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) supplies distinct `SystemSerialNumber`, `MLB`, `SystemUUID`, and `ROM` values for `MacBookPro16,2`. The values belong in `PlatformInfo → Generic` in `EFI-ready/EFI/OC/config.plist`. The `ocvalidate` utility from [OpenCore 1.0.8](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8) checks the resulting configuration.
4. **USB boot.** The generated `EFI` folder goes at the root of a FAT32 boot USB. The USB is selected in the firmware boot menu, followed by the installed macOS volume in OpenCore. A fresh installation requires a separately obtained Apple recovery image.
5. **Graphics package.** [WhateverXe Graphics 0.4.1](https://github.com/b00t0x/WhateverXe-Graphics/releases/tag/v0.4.1) is installed in macOS, followed by a reboot. The package works with the WhateverXe kext loaded by OpenCore.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Prepare-EFI.ps1
```

For touchpad trouble, `-Touchpad Disabled -OutputDirectory EFI-keyboard-mouse` produces a configuration for use with an external mouse. A personal EFI matching the reference build can supply the touchpad files with `-Touchpad Personal -PersonalEfi 'E:\EFI'`. The path is an example and should match the mounted drive. Assembly takes place in a new folder. Copying the resulting EFI to USB is a separate step.

**Fresh installation**　The [OpenCore Windows media guide](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/windows-install.html) documents Sequoia downloads through `macrecovery`. The `.dmg` and `.chunklist` go in `com.apple.recovery.boot` at the USB root. Online recovery requires a working network connection. The target is the space reserved for macOS. After the first restart, boot the USB again and select the internal `macOS Installer` entry until installation finishes. The installed macOS volume is selected afterward.

## 〓Rollback and Known Limitations〓

- The firmware's **Windows Boot Manager** entry returns to Windows. The Windows EFI, existing data partitions, and a working personal USB configuration are retained for rollback.
- The reference USB boots with firmware UEFI Secure Boot disabled. OpenCore's `SecureBootModel` is a separate setting. The EFI uses the SIP configuration required by WhateverXe Graphics. Devices with BitLocker require access to the recovery key before a firmware Secure Boot change. [Components and Sources](docs/components.md) · [BitLocker recovery](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/preboot-recovery-screen)
- For a display issue, adding `-x` temporarily to OpenCore `boot-args` on the USB requests Safe Mode. The argument is removed after troubleshooting. A copy of the working configuration should be saved before graphics or scaling changes.

Third-party components and licenses are listed in [Components and Sources](docs/components.md).
