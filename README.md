# turbopi

Coding projects built with my kids around a **HiWonder TurboPi** — a
Raspberry Pi 4B on a mecanum-wheel chassis, with a camera, an ultrasonic
sensor and RGB LEDs.

This repo holds two kinds of thing: the work of getting the robot running and
keeping it running, and the projects we build on top of it.

---

## [`robot-setup/`](robot-setup/) — getting the robot working

How to connect to the robot, how it is configured, and what to do when it
stops responding. Start with [`robot-setup/README.md`](robot-setup/README.md).

Worth reading even if nothing is broken:

- **[Connecting](robot-setup/README.md#connecting)** — two routes in, over a
  cable or over the robot's own Wi-Fi hotspot
- **[If the robot seems dead](robot-setup/README.md#if-the-robot-seems-dead)**
  — read the LEDs, and charge the battery before suspecting anything else
- **[FAULTY-CARD-READER.md](robot-setup/FAULTY-CARD-READER.md)** — a broken
  USB card reader that makes healthy SD cards look dead, and prompts macOS to
  offer to erase them

Two write-ups there may be useful to other TurboPi owners: a typo in the
upstream setup instructions that silently does nothing (so the step has
probably never been applied by anyone), and the bit-level signature of a
card reader with stuck data lines.

## [`projects/`](projects/) — things we build

One directory per project. See [`projects/README.md`](projects/README.md).

---

## Getting started

```bash
git clone https://github.com/petermchale/turbopi.git
cd turbopi
cp local-config.example.sh local-config.sh   # then fill in your robot's values
```

`local-config.sh` holds machine-specific values — your robot's MAC address and
the name of its Wi-Fi hotspot. It is gitignored, so it never leaves your
machine. The scripts find it by walking up from wherever they are run.

## A note on the code here

Much of this is notes rather than software: what broke, what the evidence
actually said, and which theory turned out to be right. Two separate failures
cost days largely because the obvious explanation was wrong both times — once
it was a documentation typo, once a flat battery that looked like a dead
board. The reasoning is written down because the conclusions are easy to
forget and expensive to rederive.
