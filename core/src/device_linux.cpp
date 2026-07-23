// device_linux.cpp — hidraw backend.
//
// Devices are discovered by walking /sys/class/hidraw rather than by opening
// every node in /dev, so enumeration needs no special privileges even when the
// nodes themselves are root-only.

#include "usbkvm/usbkvm.h"

#include "internal.h"

#include <fcntl.h>
#include <linux/hidraw.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <cstring>
#include <dirent.h>
#include <fstream>
#include <sstream>

namespace usbkvm {

namespace {

constexpr char kSysfsHidraw[] = "/sys/class/hidraw";

std::string readFile(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    if (!in)
        return {};

    std::ostringstream out;
    out << in.rdbuf();
    return out.str();
}

// Pulls "KEY=value" out of a sysfs uevent blob.
std::string ueventValue(const std::string& uevent, const std::string& key) {
    const std::string needle = key + "=";

    size_t pos = 0;
    while (pos < uevent.size()) {
        size_t end = uevent.find('\n', pos);
        if (end == std::string::npos)
            end = uevent.size();

        if (uevent.compare(pos, needle.size(), needle) == 0)
            return uevent.substr(pos + needle.size(), end - pos - needle.size());

        pos = end + 1;
    }
    return {};
}

// HID_ID looks like "0003:00000835:00001411" (bus:vendor:product).
bool parseHidId(const std::string& hidId, uint16_t& vendorId, uint16_t& productId) {
    unsigned bus = 0, vendor = 0, product = 0;
    if (std::sscanf(hidId.c_str(), "%x:%x:%x", &bus, &vendor, &product) != 3)
        return false;

    vendorId  = static_cast<uint16_t>(vendor);
    productId = static_cast<uint16_t>(product);
    return true;
}

std::string errnoMessage(const std::string& what) {
    return what + ": " + std::strerror(errno);
}

}  // namespace

std::vector<DeviceInfo> enumerate() {
    std::vector<DeviceInfo> found;

    DIR* dir = ::opendir(kSysfsHidraw);
    if (!dir)
        return found;

    while (const dirent* entry = ::readdir(dir)) {
        const std::string name = entry->d_name;
        if (name.rfind("hidraw", 0) != 0)
            continue;

        const std::string base = std::string(kSysfsHidraw) + "/" + name;

        const std::string uevent = readFile(base + "/device/uevent");
        if (uevent.empty())
            continue;

        uint16_t vendorId = 0, productId = 0;
        if (!parseHidId(ueventValue(uevent, "HID_ID"), vendorId, productId))
            continue;

        if (!isSupported(vendorId, productId))
            continue;

        // The same VID/PID also publishes a mouse/keyboard collection. Only the
        // interface carrying the vendor usage page accepts our commands.
        const std::string descriptor = readFile(base + "/device/report_descriptor");
        if (descriptor.empty())
            continue;

        if (!internal::descriptorHasUsagePage(
                reinterpret_cast<const uint8_t*>(descriptor.data()),
                descriptor.size(), kVendorUsagePage)) {
            continue;
        }

        DeviceInfo info;
        info.vendorId  = vendorId;
        info.productId = productId;
        info.path      = "/dev/" + name;
        info.product   = ueventValue(uevent, "HID_NAME");
        found.push_back(std::move(info));
    }

    ::closedir(dir);

    // /sys enumeration order is arbitrary; keep results stable across calls.
    std::sort(found.begin(), found.end(),
              [](const DeviceInfo& a, const DeviceInfo& b) { return a.path < b.path; });

    return found;
}

struct Device::Impl {
    int         fd = -1;
    DeviceInfo  info;
    std::string lastError;
};

Device::Device() : impl_(std::make_unique<Impl>()) {}

Device::~Device() {
    close();
}

Device::Device(Device&&) noexcept            = default;
Device& Device::operator=(Device&&) noexcept = default;

bool Device::open(const DeviceInfo& info) {
    close();

    const int fd = ::open(info.path.c_str(), O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        impl_->lastError = errnoMessage("open " + info.path);
        if (errno == EACCES) {
            impl_->lastError +=
                " (install Linux/udev/70-usbkvm.rules to grant access)";
        }
        return false;
    }

    impl_->fd   = fd;
    impl_->info = info;
    impl_->lastError.clear();
    return true;
}

bool Device::openFirst() {
    const std::vector<DeviceInfo> devices = enumerate();
    if (devices.empty()) {
        impl_->lastError = "no supported USB KVM found";
        return false;
    }
    return open(devices.front());
}

bool Device::isOpen() const {
    return impl_->fd >= 0;
}

void Device::close() {
    if (impl_->fd >= 0) {
        ::close(impl_->fd);
        impl_->fd = -1;
    }
}

bool Device::send(const Command& cmd) {
    if (!isOpen()) {
        impl_->lastError = "device is not open";
        return false;
    }

    uint8_t buffer[1 + kPayloadSize];
    buffer[0] = kReportId;
    std::memcpy(buffer + 1, cmd.payload, kPayloadSize);

    const ssize_t written = ::write(impl_->fd, buffer, sizeof(buffer));
    if (written < 0) {
        impl_->lastError = errnoMessage("write");
        return false;
    }
    if (written != static_cast<ssize_t>(sizeof(buffer))) {
        impl_->lastError = "short write to device";
        return false;
    }

    impl_->lastError.clear();
    return true;
}

int Device::read(uint8_t out[kPayloadSize], int timeoutMs) {
    if (!isOpen()) {
        impl_->lastError = "device is not open";
        return -1;
    }

    pollfd pfd{};
    pfd.fd     = impl_->fd;
    pfd.events = POLLIN;

    const int ready = ::poll(&pfd, 1, timeoutMs);
    if (ready < 0) {
        impl_->lastError = errnoMessage("poll");
        return -1;
    }
    if (ready == 0)
        return 0;

    // Input reports arrive with the report ID prefixed, same as writes.
    uint8_t buffer[1 + kPayloadSize];
    const ssize_t got = ::read(impl_->fd, buffer, sizeof(buffer));
    if (got < 0) {
        impl_->lastError = errnoMessage("read");
        return -1;
    }
    if (got < 1)
        return 0;

    const size_t payloadBytes =
        std::min<size_t>(static_cast<size_t>(got) - 1, kPayloadSize);

    std::memset(out, 0, kPayloadSize);
    std::memcpy(out, buffer + 1, payloadBytes);

    impl_->lastError.clear();
    return static_cast<int>(payloadBytes);
}

const DeviceInfo& Device::info() const {
    return impl_->info;
}

const std::string& Device::lastError() const {
    return impl_->lastError;
}

}  // namespace usbkvm
