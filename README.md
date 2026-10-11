# pl1-cap

Holds the package long-term power limit (PL1) on a ThinkPad X1 (i5-1240P, Fedora 44) at a value chosen by the GNOME power mode, instead of letting the embedded controller (EC) flap it between 42 W and 13 W while the laptop is docked on a Lenovo P40w.

| GNOME power mode | PL1 on AC |
|---|---|
| Power Saver | 11 W |
| Balanced | 21 W |
| Performance | 41 W |
| On battery | handed back to firmware (13 W written once) |

## Why

Docked, the EC rewrites the MMIO RAPL PL1 (`/sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw`) to 13 W after the package sits at ~97 °C, and holds it there until the package cools to ~60 °C. At 13 W:

- the CPU drops to 0.6-0.8 GHz, and the everyday desktop (browser + 5K display, 12-14 W) sits right at the cap;
- the GuC power balancer clamps the xe iGPU to 300 MHz (`tile0/gt0/freq0/throttle/reasons` reads `pl1`). A Teams video call then saturates the GPU and every browser window lags.

The input power is fine: the battery stays flat at 30-48 W draw. The chassis can sustain about 27-28 W all-core at 97 °C, and the first ~10 s burst is thermally bound whether the cap is 21 W or 42 W, so a cap below the sustained ceiling loses nothing in bursts and avoids the 13 W cliff.

## How it works

The EC only acts when the register holds one of its own values:

- **42 W** → derates to 13 W after sustained heat at ~97 °C;
- **13 W** → re-grants 42 W once the package is cool and idle;
- **anything else** → left alone;
- **a power-mode switch** (`platform_profile`) → the EC writes its own default for that mode: low-power 11 W, balanced 15 W, performance 42 W (docked).

`pl1-cap` reads the GNOME mode from tuned-ppd's `/etc/tuned/ppd_base_profile` once a second and rewrites the register when it differs. 42 W is the one cap the EC will fight, so it gets re-asserted within a second; `CAP_PERFORMANCE=41000000` avoids that fight with no practical loss.

## Changing the caps

The three caps live in `/etc/pl1-cap.conf`, in microwatts:

```
CAP_POWERSAVE=11000000
CAP_BALANCED=21000000
CAP_PERFORMANCE=41000000
```

The daemon re-reads this file every loop, so an edit takes effect within a second — no restart or `daemon-reload` needed.

## Ad-hoc overrides

`pl1-cap-set` sets a one-off cap that wins over the power-mode cap while it is in effect and the laptop is on AC:

```
pl1-cap-set 18         # hold 18 W until cleared
pl1-cap-set 25 600     # hold 25 W for 10 minutes, then fall back to the mode cap
pl1-cap-set clear      # drop the override now
pl1-cap-set status     # register, mode, configured caps, active override
```

The override lives in `/run/pl1-cap/override` (tmpfs), so it is gone after a reboot. `set`/`clear` need root and re-run themselves under `sudo`; `status` is read-only and does not.

Secure Boot + `lockdown=integrity` blocks `/dev/cpu/msr` and `/dev/mem`, so `throttled` and `intel-undervolt` can't help here. The powercap sysfs path stays writable as root.

## Install

```
./install.sh      # pl1-cap + pl1-cap-set to /usr/local/bin, unit to /etc/systemd/system,
                  # a default /etc/pl1-cap.conf (only if absent), then enable and start
./uninstall.sh
journalctl -u pl1-cap -f   # logs only when it corrects the register
```

## Still open

- Whether the EC re-grants 42 W from a 13 W *we* wrote (matters only when unplugging).
- Exactly what sets off the 42 → 13 W derate: 90 s with spikes to 99 °C didn't.
- Whether the power mode also changes the MSR PL1 or PL2.
- Why the dock gets a flapping policy while a direct 135 W charger gets a steady 15-17 W.

`NOTES.md` is the full investigation log, including the theories that turned out to be wrong.
