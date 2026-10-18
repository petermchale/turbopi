# ⚠️ The small USB microSD reader is FAULTY — do not trust it

**Reader:** generic USB microSD reader, MOAI Electronics
(USB vendor `0x14cd`, product `0x1212`, serial `121220160204`,
reports itself as "Mass Storage Device" / Manufacturer "Generic").

**Diagnosed:** 2026-09-07. Still faulty as of 2026-10-18.

---

## What's wrong

Four of its eight data lines are stuck low. **Every byte it reads comes back
bitwise-ANDed with `0x99`** (`1001 1001`) — bits 1, 2, 5 and 6 are always zero.

It does **not** fail loudly. It hands macOS plausible-looking but silently
corrupted data.

## Why that matters — the dangerous part

A good card read through this reader looks like a **dead** card. macOS sees no
valid partition table, says *"The disk you attached was not readable by this
computer"*, and offers three buttons: Eject, Ignore, **Initialize…**

**Never click Initialize.** That erases the card. The card is almost certainly
fine; the reader is lying about it. Click **Ignore**.

This is exactly what happened on 2026-09-07: a perfectly healthy TurboPi card
appeared dead, and roughly an hour was spent diagnosing the card instead of the
reader. The card went on to boot the robot without any repair at all.

## The evidence

Reading sector 0 of a known-good 32 GB TurboPi card produced only **16 distinct
byte values** out of a possible 256 — precisely the 16 values that fit the mask
`0x99`. Decoding through the mask recovers the real content exactly:

| Offset | Read as | Real value, ANDed with `0x99` | What it actually is |
|---|---|---|---|
| `0x1FE` | `11 88` | `55 AA` → `11 88` ✓ | MBR boot signature — present |
| `0x1C2` | `08` | `0C` → `08` ✓ | Partition 1 type: FAT32 LBA |
| `0x1D2` | `81` | `83` → `81` ✓ | Partition 2 type: Linux native |

And at 4 MiB (where Raspberry Pi OS puts its boot partition) the first three
bytes read `89 18 90`, which is `EB 58 90` masked — the standard FAT32 jump
instruction. The eight bytes after it decode, character for character, to the
OEM string **`mkfs.fat`**.

That is not a dying card. That is intact data arriving through broken wiring.

**The fault is hard, not intermittent.** A reseat, a different USB port, and a
clean of the card's contacts all produced a **byte-identical** dump. Genuine
dirty contacts give *varying* errors; this gives the same wrong answer every
time.

## How to re-test it in 30 seconds

Insert a card, find its device with `diskutil list` (look for the external
disk, e.g. `/dev/disk4`), then:

```bash
sudo dd if=/dev/rdisk4 bs=512 count=1 2>/dev/null | xxd | tail -2
```

Look at offset `0x1FE`, the last two bytes. A healthy reader shows `55 AA`.
This reader shows `11 88`.

## What to use instead

- A microSD-to-full-size-SD adapter plus the **MacBook Pro's built-in SDXC
  slot** (right-hand side, the port nearest the front edge). No adapter was
  available in Sept/Oct 2026 — worth buying, they come free with most cards.
- Any other USB reader.

## Suggested

Put a bit of tape on it marked **"FAULTY — reads garbage"** so it doesn't get
picked up in a hurry, which is exactly when it will do the most damage.
