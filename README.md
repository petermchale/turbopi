# TurboPi

HiWonder TurboPi robot car — a Raspberry Pi 4B on a mecanum-wheel chassis with
a HiWonder expansion board. This folder holds notes, recovery tooling and
photos. The robot's own code lives on the robot.

**Hardware:** Raspberry Pi 4B · Raspberry Pi OS Bullseye 64-bit ·
32 GB microSD · battery-powered.

---

## Connecting

Machine-specific values (your robot's MAC, the hotspot name) live in
`local-config.sh`, which is gitignored — copy `local-config.example.sh` to it
and fill it in. The scripts in `scripts/` read from it.

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
| Irregular flicker | Normal — reading the card fine |
| 4 long then 4 short, repeating | Card unreadable |
| Nothing at all, red PWR on | Not running — suspect power/battery |

---

## What's here

| Path | What it is |
|---|---|
| `FAULTY-CARD-READER.md` | **Read before using the small USB card reader.** It is broken and makes healthy cards look dead. |
| `scripts/` | Working helper scripts (see below) |
| `recovery/` | Crisis tooling and notes from the August 2026 lockout |
| `images/` | Photos of the hardware, LEDs, ports |
| `*.webloc` | Bookmarks: HiWonder source + system image, tutorial, the `rartino/turbopi` repo |

### `scripts/`

| Script | Does |
|---|---|
| `reboot-verify.sh` | Reboots the robot, waits for it, then reports disk/locale/time |
| `verify-locale.sh` | Read-only health check over SSH |
| `probe.sh` | Packet capture + probes, for when the robot seems unreachable |

All three need `sudo` on the Mac for the ARP refresh.

### `recovery/`

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
