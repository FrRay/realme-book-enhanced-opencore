# OpenCore EFI for the realme Book Enhanced Edition — Build Notes

[Project home](../README.en.md) · [简体中文](build-notes.zh-CN.md)

## 〓Project Origin〓

The reference laptop already had Windows 11 and C and D volumes on one SSD. The partition layout and encryption status were checked first, and the owner set aside about 80 GB for macOS. A 64 GB KIOXIA drive carried the installer and OpenCore. The independent Windows Boot Manager entry provided a way back during macOS debugging.

## 〓Pitfalls and Resolutions〓

| Stage | Observation | Resolution |
| --- | --- | --- |
| USB boot | The firmware initially listed only Windows Boot Manager. A connected drive and a UEFI boot entry were separate checks. | Check the FAT32 partition and `EFI/BOOT/BOOTx64.efi`, then select the USB from the firmware's one-time boot menu. |
| Recovery | OpenCore loaded, but the external recovery image reached an Apple prohibitory symbol. | Check the recovery version, OpenCore model, and boot configuration. The symbol points to a version or build compatibility issue. A photo alone gives no single cause. [Apple's description](https://support.apple.com/en-us/101666) |
| Installation restart | The first stage showed about 29 minutes, then the machine restarted into Windows. The internal installer entry was also missing at one point. | Enter OpenCore through the USB again, check internal SSD scanning, and continue with the internal `macOS Installer` entry. The installed volume is selected when that entry disappears. [OpenCore installation stages](https://dortania.github.io/OpenCore-Install-Guide/installation/installation-process.html) |
| First desktop | The native resolution appeared with only 11 MB of reported graphics memory and limited desktop rendering. | Treat basic output and acceleration as separate milestones. Keep a bootable USB configuration and check WhateverXe, the in-system Graphics package, and the macOS build together. |
| Graphics troubleshooting | Some trials rebooted, showed a lit but black panel, or logged accelerator startup without displaying a desktop. | Check low-DVMT settings, the eDP panel path, and the driver combination. Panic logs, GPU initialization, and the transition to the graphical desktop provide different evidence. |
| Custom build | An early build failed at Lilu's `hde64.h`. Clang received a relative path as file contents. | This is consistent with an archive or copy flattening a symbolic link. A source build needs preserved links. The regular installation path uses pinned builds. |
| Panel and function keys | Brightness, PWM range, and scaling each needed changes. An extra experimental scaling mode produced a black screen. | Check PNLF, PWM, BrightnessKeys, and display modes. Return to the previous configuration. When the shortcut failed to request Safe Mode, adding `-x` to the USB configuration worked. The argument was removed after troubleshooting. |
| Touchpad, wireless, and audio | Getting to the desktop left several devices to configure. Touchpad work involved interrupts and timeouts. Wi-Fi and Bluetooth needed separate driver combinations. | Use the I²C driver and touchpad plugin, pin the AX201 Wi-Fi and Intel Bluetooth builds, set AppleALC layout 37, and include battery support. [Components and Sources](components.md) describes the upstream and local touchpad builds. |
| Release | The USB accumulated snapshots, logs, and experimental builds. | Use the active EFI as the source, replace machine-specific SMBIOS identifiers with template fields, and prepare an archive with pinned dependencies and checksums. |

## Post-release testing

- **150% HiDPI.** The reference laptop booted normally with the local `RealmeNativeHiDPI.kext` 1.2.1. macOS reported a 1440 × 960 logical desktop rendered at 2880 × 1920 on the 2160 × 1440 panel. This was tested after `v0.1.0`, which does not ship that build.
- **125% HiDPI failure.** Selecting the experimental 1728 × 1152 logical mode caused a black screen and subsequent normal boots failed to reach the desktop. Safe Mode remained available. Recovery involved backing up the EFI and display preferences, restoring the known-good 1.1.0 driver, clearing the saved failing display mode, and confirming a normal boot. Replacing the driver alone may leave the saved mode in place. Keep a bootable EFI backup and a recovery path through Windows or Safe Mode before testing display changes.
- **Built-in devices.** The speakers played audio and Photo Booth showed live video. The built-in microphone showed no input level. A VXE R1 S mouse paired over Bluetooth and reconnected after a power cycle. The modified VoodooI2C/VoodooI2CHID builds fixed stalling and jumping during slow finger movement on the reference Goodix touchpad. All 15 files match the hashes for `Personal` mode. The default upstream build needs separate testing.
- **Preventing accidental system updates.** The reference laptop has automatic checking, downloading, and installation turned off. A local profile also disables the Software Update button in System Settings → General. It uses `DisabledSystemSettings` in the `com.apple.systempreferences` payload with `com.apple.Software-Update-Settings.extension`. No background script is needed. Removing the profile restores the button. Terminal and standalone installers can still perform manual updates. [Apple profile specification](https://github.com/apple/device-management/blob/release/mdm/profiles/com.apple.systempreferences.yaml)

## 〓Reproduction Order〓

The sequence is USB boot, Windows fallback confirmation, macOS installation, graphics package setup, and validation of built-in devices. A matching laptop with macOS already installed can start at [Quick Start](../README.en.md).
