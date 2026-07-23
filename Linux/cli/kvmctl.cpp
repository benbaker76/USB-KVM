// kvmctl — command-line control for ActionStar USB KVM switches.
//
// Also the bridge used by the GNOME Shell extension, which cannot link C++
// directly. Machine-readable output is available via --json.

#include "usbkvm/usbkvm.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

namespace {

int usage() {
    std::fprintf(stderr,
        "usage: kvmctl [--json] <command>\n"
        "\n"
        "commands:\n"
        "  list             list attached KVM switches\n"
        "  status           report whether a switch is present\n"
        "  switch           switch video + USB + audio to the next port\n"
        "  kvm              switch video + USB only\n"
        "  audio            switch audio only\n"
        "  opt              send the OPT switch command\n"
        "  pc3              select PC 3\n"
        "  pc4              select PC 4\n"
        "  echo             send the status ping and print any reply\n"
        "  raw B0 B1 B2 B3  send four raw payload bytes (hex)\n");
    return 2;
}

// Escapes the few characters that can legally appear in a HID product string.
std::string jsonEscape(const std::string& text) {
    std::string out;
    for (char c : text) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[7];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out += c;
                }
        }
    }
    return out;
}

void printDeviceJson(const usbkvm::DeviceInfo& info) {
    std::printf(
        "{\"vendorId\":\"%04x\",\"productId\":\"%04x\",\"path\":\"%s\",\"product\":\"%s\"}",
        info.vendorId, info.productId,
        jsonEscape(info.path).c_str(), jsonEscape(info.product).c_str());
}

int doList(bool json) {
    const std::vector<usbkvm::DeviceInfo> devices = usbkvm::enumerate();

    if (json) {
        std::printf("[");
        for (size_t i = 0; i < devices.size(); ++i) {
            if (i)
                std::printf(",");
            printDeviceJson(devices[i]);
        }
        std::printf("]\n");
    } else if (devices.empty()) {
        std::printf("no supported USB KVM found\n");
    } else {
        for (const usbkvm::DeviceInfo& info : devices) {
            std::printf("%s  %04x:%04x  %s\n", info.path.c_str(), info.vendorId,
                        info.productId, info.product.c_str());
        }
    }

    return devices.empty() ? 1 : 0;
}

int doStatus(bool json) {
    const std::vector<usbkvm::DeviceInfo> devices = usbkvm::enumerate();
    const bool present = !devices.empty();

    // Presence alone does not mean we can talk to it; on Linux the node may
    // exist but be unreadable without the udev rule installed.
    bool accessible = false;
    std::string error;
    if (present) {
        usbkvm::Device device;
        accessible = device.open(devices.front());
        if (!accessible)
            error = device.lastError();
    }

    if (json) {
        std::printf("{\"present\":%s,\"accessible\":%s,\"error\":\"%s\",\"device\":",
                    present ? "true" : "false", accessible ? "true" : "false",
                    jsonEscape(error).c_str());
        if (present)
            printDeviceJson(devices.front());
        else
            std::printf("null");
        std::printf("}\n");
    } else if (!present) {
        std::printf("no supported USB KVM found\n");
    } else if (accessible) {
        std::printf("ready: %s (%04x:%04x)\n", devices.front().path.c_str(),
                    devices.front().vendorId, devices.front().productId);
    } else {
        std::printf("found but not accessible: %s\n", error.c_str());
    }

    return (present && accessible) ? 0 : 1;
}

int sendCommand(const usbkvm::Command& cmd, bool json, bool waitForReply) {
    usbkvm::Device device;
    if (!device.openFirst()) {
        if (json)
            std::printf("{\"ok\":false,\"error\":\"%s\"}\n",
                        jsonEscape(device.lastError()).c_str());
        else
            std::fprintf(stderr, "kvmctl: %s\n", device.lastError().c_str());
        return 1;
    }

    if (!device.send(cmd)) {
        if (json)
            std::printf("{\"ok\":false,\"error\":\"%s\"}\n",
                        jsonEscape(device.lastError()).c_str());
        else
            std::fprintf(stderr, "kvmctl: %s\n", device.lastError().c_str());
        return 1;
    }

    std::string reply;
    if (waitForReply) {
        uint8_t in[usbkvm::kPayloadSize] = {};
        if (device.read(in, 500) > 0) {
            char buf[32];
            std::snprintf(buf, sizeof(buf), "%02x %02x %02x %02x", in[0], in[1], in[2], in[3]);
            reply = buf;
        }
    }

    if (json) {
        std::printf("{\"ok\":true,\"sent\":\"%02x %02x %02x %02x\",\"reply\":",
                    cmd.payload[0], cmd.payload[1], cmd.payload[2], cmd.payload[3]);
        if (reply.empty())
            std::printf("null}\n");
        else
            std::printf("\"%s\"}\n", reply.c_str());
    } else {
        std::printf("sent %02x %02x %02x %02x\n", cmd.payload[0], cmd.payload[1],
                    cmd.payload[2], cmd.payload[3]);
        if (waitForReply) {
            if (reply.empty())
                std::printf("no reply\n");
            else
                std::printf("reply %s\n", reply.c_str());
        }
    }

    return 0;
}

}  // namespace

int main(int argc, char** argv) {
    bool json = false;
    int  arg  = 1;

    if (arg < argc && std::strcmp(argv[arg], "--json") == 0) {
        json = true;
        ++arg;
    }

    if (arg >= argc)
        return usage();

    const std::string command = argv[arg++];

    if (command == "list")   return doList(json);
    if (command == "status") return doStatus(json);

    if (command == "switch")
        return sendCommand(usbkvm::Command::switchAll(), json, false);
    if (command == "kvm")
        return sendCommand(usbkvm::Command::kvmSwitch(), json, false);
    if (command == "audio")
        return sendCommand(usbkvm::Command::select(usbkvm::Target::Audio), json, false);
    if (command == "opt")
        return sendCommand(usbkvm::Command::optSwitch(), json, false);
    if (command == "pc3")
        return sendCommand(usbkvm::Command::select(usbkvm::Target::Pc3), json, false);
    if (command == "pc4")
        return sendCommand(usbkvm::Command::select(usbkvm::Target::Pc4), json, false);
    if (command == "echo")
        return sendCommand(usbkvm::Command::echo(), json, true);

    if (command == "raw") {
        if (argc - arg != 4) {
            std::fprintf(stderr, "kvmctl: raw needs exactly 4 hex bytes\n");
            return 2;
        }

        usbkvm::Command cmd{};
        for (int i = 0; i < 4; ++i) {
            char*              end   = nullptr;
            const unsigned long value = std::strtoul(argv[arg + i], &end, 16);
            if (end == argv[arg + i] || *end != '\0' || value > 0xFF) {
                std::fprintf(stderr, "kvmctl: bad hex byte '%s'\n", argv[arg + i]);
                return 2;
            }
            cmd.payload[i] = static_cast<uint8_t>(value);
        }
        return sendCommand(cmd, json, true);
    }

    return usage();
}
