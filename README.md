# USB KVM

Cross-platform control software for ActionStar-chip USB KVM switches, replacing
the original Delphi `USBKVM.exe`, which no longer works on modern Windows.

The protocol lives in one shared C++ core; each platform supplies only its own
UI layer.

```
core/                       libusbkvm — protocol + HID access (C++17, no dependencies)
  include/usbkvm/usbkvm.h   public API
  src/devices.cpp           supported-device table, report-descriptor parsing
  src/device_linux.cpp      hidraw backend
  src/device_windows.cpp    SetupAPI + HID backend

Windows/                    Win32 tray application, links the core directly
Linux/  cli/                kvmctl helper, links the core directly
        gnome-extension/    GNOME Shell extension, drives kvmctl
        udev/               access rule
macOS/                      Objective-C menu bar app
assets/icon.svg             full-colour app-icon master (SVG)
tools/make_icons.py         renders all raster icons from the SVG masters
.github/workflows/build.yml CI for all three platforms
```

## Supported hardware

Vendor IDs `0x2101` and `0x0835` (Action Star Enterprise), products `0x1403`,
`0x1404`, `0x1406`, `0x1407`, `0x1411`.

## Protocol

Recovered from the original Delphi binary and verified against a live `0835:1411`
report descriptor.

The switch presents two USB interfaces. Interface 0 is an ordinary keyboard/mouse
collection. **Interface 1 carries a vendor-defined collection on usage page
`0xFF01`**, and that is the only one that accepts commands — opening the wrong
interface is silent failure, so both backends filter on the usage page rather
than trusting interface order.

That collection defines a 4-byte input report and a 4-byte output report, both
under **report ID 3**. A command is the report ID followed by the 4 payload
bytes, written as one 5-byte output report:

```
 byte 0   byte 1   byte 2   byte 3   byte 4
  0x03     opcode   arg      0x00     0x00
```

| Payload       | Original UI label | Effect                              |
|---------------|-------------------|-------------------------------------|
| `5C 04 00 00` | All Switch        | next port: video + USB + audio      |
| `5C 01 00 00` | Audio Switch      | audio only                          |
| `5C 30 00 00` | PC 3              | select port 3                       |
| `5C 40 00 00` | PC 4              | select port 4                       |
| `03 00 00 00` | KVM Switch        | video + USB, leaves audio alone     |
| `02 00 00 00` | OPT Switch        | vendor option switch                |
| `00 00 00 00` | Get Echo          | status ping; does not move the switch |

`0x5C` is a prefix opcode whose argument selects the target; the other opcodes
take no argument. `Get Echo` is write-only in practice — the device sends no
reply on the interrupt IN endpoint.

**Switching re-enumerates the device.** The KVM physically hands the USB link to
the other host, so the node disappears and returns under a new name
(`/dev/hidraw9` → `/dev/hidraw10`). Nothing holds a handle open between commands;
every command enumerates, opens, writes and closes.

## Building

### Linux

```sh
cd Linux
./install.sh          # builds kvmctl, installs the udev rule and the extension
```

Then enable the extension and restart the session:

```sh
gnome-extensions enable usbkvm@benbaker76.github.io
```

On Wayland a newly installed extension is only picked up after logging out and
back in. On Xorg, <kbd>Alt</kbd>+<kbd>F2</kbd> then `r` is enough.

`kvmctl` on its own:

```sh
kvmctl list        # show attached switches
kvmctl status      # presence + whether it can be opened
kvmctl switch      # video + USB + audio to the next port
kvmctl echo        # safe ping, does not switch
kvmctl raw 5c 04 00 00
```

Add `--json` to any command for machine-readable output — this is what the
GNOME extension consumes.

#### Permissions

`/dev/hidraw*` is root-only by default. `Linux/udev/70-usbkvm.rules` grants
access to the active local user via `uaccess`, with a `plugdev` group fallback.

The `70-` prefix is load-bearing: `73-seat-late.rules` is where systemd matches
`TAG=="uaccess"` and applies the ACL, so a rule numbered above 73 sets the tag
too late to have any effect. A rule that appears correct but never grants access
is almost always this.

### Windows

Cross-compiled from Linux with mingw-w64:

```sh
sudo apt install mingw-w64
cmake -S Windows -B build-win -DCMAKE_TOOLCHAIN_FILE=$PWD/cmake/mingw-w64.cmake \
      -DCMAKE_BUILD_TYPE=Release
cmake --build build-win -j$(nproc)
```

Produces a standalone `build-win/USBKVM.exe` with the C++ runtime linked
statically — no redistributable required. The same `CMakeLists.txt` also
configures under MSVC if you would rather build on Windows.

Left-click the tray icon to switch; right-click for the full command set,
a "Start with Windows" toggle and Exit.

#### Why the original stopped working

The Delphi build opens the HID device with `GENERIC_READ | GENERIC_WRITE` and no
sharing flags. Modern Windows keeps HID devices open, so that `CreateFile` fails
outright. The rewrite opens with zero desired access for enumeration (metadata
queries still work, and it succeeds against exclusively-held devices) and
reopens with `FILE_SHARE_READ | FILE_SHARE_WRITE` for I/O. It also pads writes to
the driver's `OutputReportByteLength` and ships an application manifest, neither
of which the 2010 build did.

### macOS

```sh
xcodebuild -project "macOS/USB KVM.xcodeproj" -scheme "USB KVM" -configuration Release
```

The project still declares a 10.8 deployment target, which current Xcode
rejects. CI overrides it on the command line with
`MACOSX_DEPLOYMENT_TARGET=10.13` rather than editing the project; do the same if
you build from the terminal.

## Icons

Three checked-in SVGs are the single source of truth for every icon. All raster
assets are generated from them by `tools/make_icons.py`; the SVGs themselves are
hand-authored and the script never writes them.

| SVG master | Renders to |
|---|---|
| `assets/icon.svg` | macOS app icon (`AppIcon.appiconset/*.png`), Windows `usbkvm-app.ico` |
| `Linux/gnome-extension/icons/usbkvm-symbolic.svg` | GNOME panel + Windows tray, switch attached |
| `Linux/gnome-extension/icons/usbkvm-error-symbolic.svg` | same, no switch attached |

The two symbolic SVGs use `fill="currentColor"` so the shell can tint them per
theme; `assets/icon.svg` is full-colour. Two states everywhere: the plain
monitor when a switch is attached, a warning variant when none is.

Regenerate after editing any SVG, then rebuild:

```sh
sudo apt install librsvg2-bin     # provides rsvg-convert
python3 tools/make_icons.py
```

Notes for editing the SVGs:

- Keep `fill="currentColor"` on the symbolic pair. GNOME tints them by setting
  the colour on the panel button, so a baked-in fill would stay that colour and
  disappear against a panel of the same shade. For the Windows tray the script
  resolves it by injecting a CSS `color` — black for light taskbars, white for
  dark.
- Avoid `pt` units on `width`/`height`; leave the `viewBox` authoritative so the
  icon scales freely.
- Each of the 8 sizes in a tray/app `.ico` is rendered natively from the vector
  rather than resampled from one bitmap, so the 16px and 20px frames the tray
  shows stay crisp.

The generated `.ico` and `.png` files are checked in, so CI never needs
`rsvg-convert`.

## Continuous integration

`.github/workflows/build.yml` builds all three platforms on every push and pull
request. Pushing a tag such as `v2.0.0` additionally creates a **draft** release
with these attached:

| Artifact | Contents |
|---|---|
| `usbkvm-linux-x86_64.tar.gz` | `kvmctl`, udev rule, extension, installer |
| `usbkvm-gnome-extension.zip` | installable via `gnome-extensions install` |
| `usbkvm-windows-x64.zip` | standalone `USBKVM.exe` |
| `usbkvm-macos.zip` | universal `USB KVM.app` |

The macOS app is built unsigned — CI has no Developer ID certificate — so
Gatekeeper will quarantine it until you sign it or clear the attribute locally.

## Credits

- Reverse engineering and implementation by [benbaker76](https://github.com/benbaker76)
- Original hardware and Windows software by Action Star Enterprise
