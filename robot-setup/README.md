# Robot setup

Getting the HiWonder TurboPi running and keeping it running: how to connect,
how it is configured, and what to do when it stops responding. The robot's own
code lives on the robot; this folder is notes, tooling and photos.

For the projects built on top of it, see [`../projects/`](../projects/).

**Hardware:** Raspberry Pi 4B · Raspberry Pi OS Bullseye 64-bit ·
32 GB microSD · battery-powered.

---

## Connecting

Machine-specific values (your robot's MAC, the hotspot name) live in
`local-config.sh` in the repo root, which is gitignored — copy `local-config.example.sh` to it
and fill it in. The scripts in `connection-scripts/` read from it.

Two shell functions are defined in **`~/.bash_profile`** (login shell is bash,
not zsh). Both authenticate with the key `~/.ssh/turbopi_ed25519`, so **neither
ever asks for the robot's password**.

### `turbopi-ethernet` — over the cable

```bash
turbopi-ethernet              # interactive shell
turbopi-ethernet 'df -h /'    # run one command
```

Requires: the USB ethernet adapter plugged in, and macOS **Internet Sharing**
on (System Settings → General → Sharing), sharing **from Wi-Fi** to **USB
10/100/1000 LAN**. Robot is at `192.168.2.2`.

It will ask for your **Mac** password, clearly labelled. That is for an ARP
refresh, explained below — it is *not* the robot's password.

On this route the robot has internet through the Mac, so `apt` works.

### `turbopi-wifi` — over the robot's own hotspot

First join Wi-Fi **`HW-XXXXXXXX`** (your robot's own; the suffix comes from its
wlan0 MAC), factory password **`hiwonder`**. Then:

```bash
turbopi-wifi
```

Robot is at `192.168.149.1`. No ARP refresh, no password of any kind.

Trade-off: while joined to that hotspot your Mac has **no internet**, and the
robot has none either, so `apt` will not work.

### Why the ethernet route needs an ARP refresh

macOS Internet Sharing puts `192.168.2.1` on a **bridge** interface. The
bridge's forwarding entry for the robot goes stale after a minute or two idle.
Once it does, nothing on the Mac can reach `192.168.2.2` — `ssh` and `ping`
both report **"No route to host"** — until the entry is flushed.

Broadcast and multicast still get through, so DHCP and mDNS keep working. The
robot therefore looks alive but unreachable. **It is fine.** Just reconnect;
the function flushes the entry for you. A *static* ARP entry does not help.

---

## If the robot seems dead

**Charge the battery first, before suspecting anything else.**

In September 2026 the robot appeared completely dead — no ethernet link, no
hotspot, no green ACT LED — for what turned out to be a flat battery. A
brownout lights the red PWR LED but leaves the processor unable to run, so
there is no boot *and* no error blink code. Total silence from the green ACT
LED is the signature.

Reading the LEDs (Pi's own PCB, by the USB-C and microSD end — not the
expansion board's red and blue ones):

| Green ACT LED | Meaning |
|---|---|
| Irregular flicker, network fine | Normal — reading the card fine |
| Irregular flicker, but **both** `eth0` and the hotspot are down | Undervoltage — see [Power and battery](#power-and-battery) |
| 4 long then 4 short, repeating | Card unreadable |
| Nothing at all, red PWR on | Not running — suspect power/battery |

Note the second row: a *flickering* ACT does not mean the power is healthy.
It only means the processor is still running, which it does for a while after
the network hardware has already dropped out. Judge power by whether both
network routes died together, not by the LED alone.

A single photograph cannot tell "steady" from "caught mid-flicker" — watch the
LED for a continuous 30 seconds before concluding anything from it.

---

## Power and battery

**Expect roughly two hours of runtime per charge**, and keep the robot on a
fresh charge before any long session.

The robot runs on **two 18650 lithium cells in series** (7.4 V nominal) in a
removable double-bay holder. The cells it shipped with are HiWonder
`3.7V 18650 1800mAh` — about 13 Wh for the pair, against a Pi 4B drawing
4–6 W with camera, sensors and Wi-Fi. That is where the two hours comes from.
It is a property of the hardware, not a fault.

### How it dies, and why it misleads

**A flat battery does not look like a flat battery.** It looks like a network
fault. As the 5 V rail sags, the hungriest parts of the Pi fail first — the
ethernet PHY and the Wi-Fi radio — while the CPU carries on. So you see:

- `eth0` loses carrier (the Mac reports `status: inactive`, `media: none`)
- the `HW-XXXXXXXX` hotspot stops broadcasting
- the green ACT LED keeps flickering, because the processor is still running

Both network routes dead at once, with the CPU alive, is close to a textbook
undervoltage signature. It happened on 2026-10-18 and was initially
misdiagnosed as a loose cable — a loose cable cannot take the hotspot down
with it. **One cause doing both means power, not networking.**

Confirm it from the Pi, which records throttling events:

    vcgencmd get_throttled

`0x0` means clean. Bit 0 set means under-voltage right now; bit 16 means
under-voltage has occurred since boot.

### Charging

The cells come **out** of the robot and into the two-bay USB charger — there
is no in-place charging port. Red means charging, green means done, per bay.
Switch the robot off before removing cells, and note the orientation; the
holder is marked ⊕ and ⊖, and the two bays face in opposite directions
because they are wired in series.

If one bay stays red for hours while the other goes green, that cell is
degraded. Replace **both** — never run a new cell in series with a tired one.

### Buying replacements

**Specification that fits this holder:**

| | |
|---|---|
| Format | 18650, **button top**, **unprotected** |
| Voltage | **3.7 V** Li-ion (INR/NCR — *not* 3.2 V LiFePO4, which looks identical) |
| Capacity | 3000–3500 mAh. **Anything advertised above ~3600 mAh is counterfeit.** |
| Current | 8 A continuous is ample |
| Quantity | 2, same brand and batch |

The holder's positive contact is a raised dome and the negative is a spring,
so flat-tops would probably seat — but the cells it ships with are button-top,
and matching what is known to work avoids the question. Protected cells are
2–3 mm longer and may not fit at all.

Upgrading to 3500 mAh roughly doubles runtime, to about four hours.

**Buy from battery specialists, not marketplace listings** — counterfeit and
relabelled 18650s are common. [18650 Battery Store](https://www.18650batterystore.com/products/samsung-35e-button-top)
(Samsung 35E button-top, 3500 mAh, 8 A), [IMR Batteries](https://www.imrbatteries.com/lg-mj1-18650-3500mah-10a-battery)
and [Illumn](https://www.illumn.com/18650-lg-inr18650mj1-3500mah-high-discharge.html)
are all established in this niche. HiWonder sells the charger and the holder
but **not** the cells.

---

## Links

- [HiWonder: source code and system image](https://drive.google.com/drive/folders/1Y9FdmRe_h6JPQ0ggJe8bi1GDT4IsESSV)
  — take **"TurboPi RPi 4B Version System Image"**, *not* the "2501 TurboPi AI
  Large Model (RPi5)" ones, which are Raspberry Pi 5 only
- [HiWonder: tutorials](https://drive.google.com/drive/folders/1x5IXJTTF_mz3FnN-iiRB4MxgKbYnIj25)
- [rartino/turbopi](https://github.com/rartino/turbopi) — third-party notes on
  the TurboPi. Its README contains the `denyinterfaces` typo described in
  `august-2026-lockout-recovery/issue-2-comment.md`.

---

## What's in this folder

| Path | What it is |
|---|---|
| `FAULTY-CARD-READER.md` | **Read before using the small USB card reader.** It is broken and makes healthy cards look dead. |
| `connection-scripts/` | Working helper scripts (see below) |
| `august-2026-lockout-recovery/` | Crisis tooling and notes from the August 2026 lockout |
| `photos/` | Photos of the hardware, LEDs, ports |

### `connection-scripts/`

| Script | Does |
|---|---|
| `reboot-verify.sh` | Reboots the robot, waits for it, then reports disk/locale/time |
| `verify-locale.sh` | Read-only health check over SSH |
| `probe.sh` | Packet capture + probes, for when the robot seems unreachable |

All three need `sudo` on the Mac for the ARP refresh.

### `august-2026-lockout-recovery/`

From the August 2026 episode, when the robot was locked out entirely:

- `pi-repair.sh` — arms a one-shot root repair at boot via `systemd.run=` in
  `/boot/cmdline.txt`, editable from macOS because `/boot` is FAT32
- `find-pi.sh` — waits for ethernet link, then tries every way of finding the Pi
- `prepare-card.sh`, `console-fix.md`, `console-wifi-only.md` — card prep and
  console-only recovery paths
- `issue-2-comment.md` — the write-up of a README bug in `rartino/turbopi`
  (posted: issue #2, August 2026)

---

## Reflashing

If the card ever does fail, the image is in the "source code and system image"
bookmark (Google Drive, verified live October 2026).

**Take "TurboPi RPi 4B Version System Image".** *Not* the "2501 TurboPi AI
Large Model (RPi5)" images — those are Raspberry Pi 5 only and this is a 4B.

---

## State

Locale `en_US.UTF-8` · timezone `America/Denver` · root filesystem expanded to
29 GB · `pi` password changed from the default (**not recorded anywhere** —
if lost, reflashing is the only way back while the card reader is broken).
