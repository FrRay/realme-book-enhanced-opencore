DefinitionBlock ("", "SSDT", 2, "REALME", "RECOVERY", 0x00000001)
{
    External (\_SB.PC00.LPCB, DeviceObj)
    External (\_SB.PR00, ProcessorObj)
    External (\STAS, FieldUnitObj)

    Scope (\)
    {
        Method (_INI, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                \STAS = One
            }
        }
    }

    Scope (\_SB.PC00.LPCB)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin")) { Return (0x0F) }
                Return (Zero)
            }
        }
    }

    Scope (\_SB)
    {
        Device (USBX)
        {
            Name (_ADR, Zero)
            Method (_DSM, 4, NotSerialized)
            {
                If (!_OSI ("Darwin")) { Return (Buffer (One) { Zero }) }
                If (Arg2 == Zero) { Return (Buffer (One) { 0x03 }) }
                Return (Package (0x08)
                {
                    "kUSBSleepPowerSupply", 0x13EC,
                    "kUSBSleepPortCurrentLimit", 0x0834,
                    "kUSBWakePowerSupply", 0x13EC,
                    "kUSBWakePortCurrentLimit", 0x0834
                })
            }
        }
    }

    Scope (\_SB.PR00)
    {
        Method (_DSM, 4, NotSerialized)
        {
            If (!_OSI ("Darwin")) { Return (Buffer (One) { Zero }) }
            If (Arg2 == Zero) { Return (Buffer (One) { 0x03 }) }
            Return (Package (0x02) { "plugin-type", One })
        }
    }
}
