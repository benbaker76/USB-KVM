#!/usr/bin/env bash
#
# Builds and installs the Linux side: the kvmctl helper, the udev rule that
# grants access to the switch, and the GNOME Shell extension.
#
#   ./install.sh              build + install everything
#   ./install.sh --user       skip the udev rule (no sudo; assumes it is present)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UUID="usbkvm@benbaker76.github.io"
EXT_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"
BIN_DIR="${HOME}/.local/bin"

INSTALL_UDEV=1
if [[ "${1:-}" == "--user" ]]; then
    INSTALL_UDEV=0
fi

# The release tarball ships a prebuilt kvmctl beside this script and carries no
# sources; a git checkout has CMakeLists.txt instead. Support both.
if [[ -x "${HERE}/kvmctl" ]]; then
    echo "==> Using prebuilt kvmctl"
    KVMCTL="${HERE}/kvmctl"
elif [[ -f "${HERE}/CMakeLists.txt" ]]; then
    echo "==> Building kvmctl"
    cmake -S "${HERE}" -B "${HERE}/build" -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "${HERE}/build" -j"$(nproc)" >/dev/null
    KVMCTL="${HERE}/build/kvmctl"
else
    echo "error: found neither a prebuilt kvmctl nor CMakeLists.txt in ${HERE}" >&2
    exit 1
fi

echo "==> Installing kvmctl to ${BIN_DIR}"
mkdir -p "${BIN_DIR}"
install -m 0755 "${KVMCTL}" "${BIN_DIR}/kvmctl"

if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    echo "    note: ${BIN_DIR} is not on PATH."
    echo "    The extension also looks in /usr/local/bin and /usr/bin."
fi

if [[ "${INSTALL_UDEV}" == "1" ]]; then
    echo "==> Installing udev rule (needs sudo)"
    # Must sort before 73-seat-late.rules, which is where TAG=="uaccess" is
    # matched and the ACL actually applied.
    # udev/ in a checkout, alongside the script in the release tarball.
    RULES="${HERE}/udev/70-usbkvm.rules"
    [[ -f "${RULES}" ]] || RULES="${HERE}/70-usbkvm.rules"

    sudo install -m 0644 "${RULES}" /etc/udev/rules.d/70-usbkvm.rules
    sudo rm -f /etc/udev/rules.d/99-usbkvm.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger --action=add --subsystem-match=hidraw
fi

echo "==> Installing GNOME extension to ${EXT_DIR}"
mkdir -p "${EXT_DIR}"
cp -r "${HERE}/gnome-extension/." "${EXT_DIR}/"

echo
echo "Checking for a switch:"
"${BIN_DIR}/kvmctl" status || true

echo
echo "Done. Enable the extension with:"
echo "    gnome-extensions enable ${UUID}"
echo
echo "On Wayland you must log out and back in before the Shell will see a"
echo "newly installed extension; on Xorg, Alt+F2 then 'r' is enough."
