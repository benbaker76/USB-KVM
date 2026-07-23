// usbkvm.h — cross-platform control library for ActionStar-chip USB KVM switches.
//
// Protocol recovered from the original Delphi USBKVM.exe and verified against a
// live 0835:1411 report descriptor:
//
//   The device exposes a vendor-defined collection (usage page 0xFF01) on its
//   second USB interface, alongside the mouse collection on the first. That
//   collection carries a 4-byte input report and a 4-byte output report, both
//   under report ID 3. A command is the report ID followed by the 4 payload
//   bytes, written as a single 5-byte output report.

#ifndef USBKVM_USBKVM_H
#define USBKVM_USBKVM_H

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace usbkvm {

// Report ID prefixed to every command written to the device.
inline constexpr uint8_t kReportId = 0x03;

// Usage page of the vendor collection we must talk to. The device also exposes
// a Generic Desktop mouse collection, which must NOT be opened for commands.
inline constexpr uint16_t kVendorUsagePage = 0xFF01;

// Payload size in bytes, excluding the report ID.
inline constexpr size_t kPayloadSize = 4;

// Opcode — payload byte 0.
enum class Op : uint8_t {
    Echo   = 0x00,  // status ping; does not move the switch
    Opt    = 0x02,  // "OPT Switch"
    Kvm    = 0x03,  // "KVM Switch" (video + USB, leaves audio alone)
    Select = 0x5C,  // switch/select; target goes in payload byte 1
};

// Argument for Op::Select — payload byte 1.
enum class Target : uint8_t {
    Audio = 0x01,  // "Audio Switch"
    All   = 0x04,  // "All Switch" — video + USB + audio; what the macOS app sends
    Pc3   = 0x30,  // "PC 3"
    Pc4   = 0x40,  // "PC 4"
};

// A single 4-byte command payload.
struct Command {
    uint8_t payload[kPayloadSize];

    static Command raw(uint8_t b0, uint8_t b1 = 0, uint8_t b2 = 0, uint8_t b3 = 0) {
        return Command{{b0, b1, b2, b3}};
    }
    static Command echo()       { return raw(static_cast<uint8_t>(Op::Echo)); }
    static Command optSwitch()  { return raw(static_cast<uint8_t>(Op::Opt)); }
    static Command kvmSwitch()  { return raw(static_cast<uint8_t>(Op::Kvm)); }
    static Command select(Target t) {
        return raw(static_cast<uint8_t>(Op::Select), static_cast<uint8_t>(t));
    }
    // The canonical "switch everything to the next port" command.
    static Command switchAll()  { return select(Target::All); }
};

// One discovered vendor interface.
struct DeviceInfo {
    uint16_t    vendorId  = 0;
    uint16_t    productId = 0;
    std::string path;     // hidraw node (Linux) or device interface path (Windows)
    std::string product;  // product string, may be empty
};

// True if the VID/PID pair is a known ActionStar KVM.
bool isSupported(uint16_t vendorId, uint16_t productId);

// All supported devices currently attached, restricted to the 0xFF01 interface.
std::vector<DeviceInfo> enumerate();

// An open handle to a KVM's vendor interface.
class Device {
public:
    Device();
    ~Device();

    Device(const Device&)            = delete;
    Device& operator=(const Device&) = delete;
    Device(Device&&) noexcept;
    Device& operator=(Device&&) noexcept;

    // Opens the given interface. Returns false and sets lastError() on failure.
    bool open(const DeviceInfo& info);

    // Opens the first supported device found. False if none is attached.
    bool openFirst();

    bool isOpen() const;
    void close();

    // Writes kReportId followed by cmd.payload. False on failure.
    bool send(const Command& cmd);

    // Reads one 4-byte input report. Returns bytes read, 0 on timeout, -1 on
    // error. timeoutMs < 0 blocks indefinitely.
    int read(uint8_t out[kPayloadSize], int timeoutMs);

    const DeviceInfo& info() const;

    // Human-readable description of the most recent failure.
    const std::string& lastError() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace usbkvm

#endif  // USBKVM_USBKVM_H
