# MT6897 / Duchamp port notes

This source tree adapts the application runtime itself. The Magisk/KernelSU
installer is deliberately unchanged.

## Hardware mapping

- CPU policy leaders remain `0`, `4`, and `7`, but limits are read from each
  policy's live `cpuinfo_min_freq` and `cpuinfo_max_freq` nodes.
- Mali remains at `13000000.mali`; its live OPP table contains 65 frequencies
  from 265 MHz through 1400 MHz.
- GED boost and upbound indices are derived from the live OPP table instead of
  using Rodin's 41-step constants.
- The Mali cooling device is located by reading every cooling device `type`.
  On the tested MT6897 kernel this resolves to `cooling_device2`. The former
  hard-coded `cooling_device3` is a charger cooler and is never selected.
- Battery Saver chooses the supported GPU OPP nearest 600 MHz (601 MHz on the
  tested kernel).
- Stock mode uses `simple_ondemand` on the 1400 MHz MT6897 table; Rodin's
  `dummy` governor remains the fallback for its 1300 MHz table.

## Charging control

The original Charging Boost switch depends on
`/sys/class/power_supply/usb/sic_mode`. That node is absent on the tested
MT6897 kernel. The app now reports the control as unavailable and skips its
background persistence without treating this as a daemon failure.

`battery/input_suspend`, `charge_control_limit`, `smart_chg`, and
`night_charging` are not substituted for `sic_mode`: they have different
semantics and mapping any of them to "Boost" would be unsafe and misleading.
Battery telemetry continues to use the standard battery and USB supplies.

## Compatible subsystems observed

- Xiaomi `ITouchFeature/default` AIDL service and Goodix non-THP report-rate
  node. Non-THP panels bypass Rodin's service-memory THP path.
- Xiaomi `IDisplayFeature/default` AIDL service
- `thermal_message/cpu_limits` and `thermal_message/sconfig`
- `/proc/powerhal_cpu_ctrl/perfserv_freq`
- UFS logical units `sda`, `sdb`, and `sdc`
- ZRAM with `lz4`, `lzo`, `lzo-rle`, and `zstd`
