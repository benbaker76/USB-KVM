// device_windows.cpp — Win32 HID backend.
//
// Uses SetupDi* to enumerate the HID interface class and HidP_GetCaps to pick
// the vendor collection. This is the piece the original Delphi build got wrong
// for modern Windows: it opened the device with GENERIC_READ | GENERIC_WRITE
// and no sharing, which fails on any HID device the system has already opened
// exclusively. We request no access at all for inspection, then reopen for
// writing with full sharing.

#include "usbkvm/usbkvm.h"

#include "internal.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>

#include <setupapi.h>

extern "C" {
#include <hidsdi.h>
// MinGW's hidsdi.h pulls in hidpi.h for HidP_GetCaps; the Windows SDK's does
// not, so include it explicitly or the MSVC build fails to find HIDP_CAPS.
#include <hidpi.h>
}

#include <algorithm>
#include <cstring>
#include <string>
#include <vector>

namespace usbkvm {

namespace {

std::string toUtf8(const std::wstring& text) {
    if (text.empty())
        return {};

    const int needed = ::WideCharToMultiByte(CP_UTF8, 0, text.c_str(),
                                             static_cast<int>(text.size()),
                                             nullptr, 0, nullptr, nullptr);
    if (needed <= 0)
        return {};

    std::string out(static_cast<size_t>(needed), '\0');
    ::WideCharToMultiByte(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()),
                          out.data(), needed, nullptr, nullptr);
    return out;
}

std::wstring toWide(const std::string& text) {
    if (text.empty())
        return {};

    const int needed = ::MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                                             static_cast<int>(text.size()), nullptr, 0);
    if (needed <= 0)
        return {};

    std::wstring out(static_cast<size_t>(needed), L'\0');
    ::MultiByteToWideChar(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()),
                          out.data(), needed);
    return out;
}

std::string lastErrorMessage(const std::string& what) {
    const DWORD code = ::GetLastError();

    LPWSTR buffer = nullptr;
    const DWORD length = ::FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr, code, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        reinterpret_cast<LPWSTR>(&buffer), 0, nullptr);

    std::string detail;
    if (length && buffer) {
        std::wstring text(buffer, length);
        while (!text.empty() && (text.back() == L'\r' || text.back() == L'\n'))
            text.pop_back();
        detail = toUtf8(text);
    }
    if (buffer)
        ::LocalFree(buffer);

    if (detail.empty())
        detail = "error " + std::to_string(code);

    return what + ": " + detail;
}

// Opens a HID path for inspection only. Zero desired access still permits
// HidD_* metadata queries and, critically, succeeds on devices another process
// (or the HID class driver) holds open exclusively.
HANDLE openForQuery(const std::wstring& path) {
    return ::CreateFileW(path.c_str(), 0,
                         FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                         OPEN_EXISTING, 0, nullptr);
}

HANDLE openForIo(const std::wstring& path) {
    return ::CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE,
                         FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                         OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nullptr);
}

// Reads the top-level usage page via the parsed descriptor.
bool interfaceUsagePage(HANDLE handle, uint16_t& usagePage, uint16_t& outputReportLength) {
    PHIDP_PREPARSED_DATA preparsed = nullptr;
    if (!::HidD_GetPreparsedData(handle, &preparsed))
        return false;

    HIDP_CAPS caps{};
    const NTSTATUS status = ::HidP_GetCaps(preparsed, &caps);
    ::HidD_FreePreparsedData(preparsed);

    if (status != HIDP_STATUS_SUCCESS)
        return false;

    usagePage          = caps.UsagePage;
    outputReportLength = caps.OutputReportByteLength;
    return true;
}

std::string productString(HANDLE handle) {
    wchar_t buffer[256] = {};
    if (!::HidD_GetProductString(handle, buffer, sizeof(buffer)))
        return {};
    return toUtf8(buffer);
}

}  // namespace

std::vector<DeviceInfo> enumerate() {
    std::vector<DeviceInfo> found;

    GUID hidGuid{};
    ::HidD_GetHidGuid(&hidGuid);

    HDEVINFO deviceInfoSet = ::SetupDiGetClassDevsW(
        &hidGuid, nullptr, nullptr, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (deviceInfoSet == INVALID_HANDLE_VALUE)
        return found;

    SP_DEVICE_INTERFACE_DATA interfaceData{};
    interfaceData.cbSize = sizeof(interfaceData);

    for (DWORD index = 0;
         ::SetupDiEnumDeviceInterfaces(deviceInfoSet, nullptr, &hidGuid, index,
                                       &interfaceData);
         ++index) {
        DWORD requiredSize = 0;
        ::SetupDiGetDeviceInterfaceDetailW(deviceInfoSet, &interfaceData, nullptr, 0,
                                           &requiredSize, nullptr);
        if (requiredSize == 0)
            continue;

        std::vector<uint8_t> buffer(requiredSize);
        auto* detail =
            reinterpret_cast<PSP_DEVICE_INTERFACE_DETAIL_DATA_W>(buffer.data());
        detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);

        if (!::SetupDiGetDeviceInterfaceDetailW(deviceInfoSet, &interfaceData, detail,
                                                requiredSize, nullptr, nullptr)) {
            continue;
        }

        const std::wstring path = detail->DevicePath;

        HANDLE handle = openForQuery(path);
        if (handle == INVALID_HANDLE_VALUE)
            continue;

        HIDD_ATTRIBUTES attributes{};
        attributes.Size = sizeof(attributes);

        if (::HidD_GetAttributes(handle, &attributes) &&
            isSupported(attributes.VendorID, attributes.ProductID)) {
            uint16_t usagePage = 0, outputLength = 0;
            if (interfaceUsagePage(handle, usagePage, outputLength) &&
                usagePage == kVendorUsagePage) {
                DeviceInfo info;
                info.vendorId  = attributes.VendorID;
                info.productId = attributes.ProductID;
                info.path      = toUtf8(path);
                info.product   = productString(handle);
                found.push_back(std::move(info));
            }
        }

        ::CloseHandle(handle);
    }

    ::SetupDiDestroyDeviceInfoList(deviceInfoSet);

    // Enumeration order is not guaranteed stable between calls.
    std::sort(found.begin(), found.end(),
              [](const DeviceInfo& a, const DeviceInfo& b) { return a.path < b.path; });

    return found;
}

struct Device::Impl {
    HANDLE      handle             = INVALID_HANDLE_VALUE;
    DeviceInfo  info;
    std::string lastError;
    // Windows requires writes to be exactly OutputReportByteLength bytes, which
    // includes the report ID and may be padded beyond our 5-byte command.
    size_t      outputReportLength = 1 + kPayloadSize;
    size_t      inputReportLength  = 1 + kPayloadSize;
};

Device::Device() : impl_(std::make_unique<Impl>()) {}

Device::~Device() {
    close();
}

Device::Device(Device&&) noexcept            = default;
Device& Device::operator=(Device&&) noexcept = default;

bool Device::open(const DeviceInfo& info) {
    close();

    const std::wstring path = toWide(info.path);

    HANDLE handle = openForIo(path);
    if (handle == INVALID_HANDLE_VALUE) {
        impl_->lastError = lastErrorMessage("CreateFile " + info.path);
        return false;
    }

    PHIDP_PREPARSED_DATA preparsed = nullptr;
    if (::HidD_GetPreparsedData(handle, &preparsed)) {
        HIDP_CAPS caps{};
        if (::HidP_GetCaps(preparsed, &caps) == HIDP_STATUS_SUCCESS) {
            if (caps.OutputReportByteLength > 0)
                impl_->outputReportLength = caps.OutputReportByteLength;
            if (caps.InputReportByteLength > 0)
                impl_->inputReportLength = caps.InputReportByteLength;
        }
        ::HidD_FreePreparsedData(preparsed);
    }

    impl_->handle = handle;
    impl_->info   = info;
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
    return impl_->handle != INVALID_HANDLE_VALUE;
}

void Device::close() {
    if (impl_->handle != INVALID_HANDLE_VALUE) {
        ::CloseHandle(impl_->handle);
        impl_->handle = INVALID_HANDLE_VALUE;
    }
}

bool Device::send(const Command& cmd) {
    if (!isOpen()) {
        impl_->lastError = "device is not open";
        return false;
    }

    // Zero-padded to the length the driver expects, report ID first.
    std::vector<uint8_t> buffer(std::max<size_t>(impl_->outputReportLength,
                                                 1 + kPayloadSize),
                                0);
    buffer[0] = kReportId;
    std::memcpy(buffer.data() + 1, cmd.payload, kPayloadSize);

    OVERLAPPED overlapped{};
    overlapped.hEvent = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!overlapped.hEvent) {
        impl_->lastError = lastErrorMessage("CreateEvent");
        return false;
    }

    DWORD written = 0;
    bool  ok      = ::WriteFile(impl_->handle, buffer.data(),
                                static_cast<DWORD>(buffer.size()), &written,
                                &overlapped) != FALSE;

    if (!ok && ::GetLastError() == ERROR_IO_PENDING) {
        if (::WaitForSingleObject(overlapped.hEvent, 1000) == WAIT_OBJECT_0)
            ok = ::GetOverlappedResult(impl_->handle, &overlapped, &written, FALSE) != FALSE;
        else
            ::CancelIo(impl_->handle);
    }

    if (!ok)
        impl_->lastError = lastErrorMessage("WriteFile");
    else
        impl_->lastError.clear();

    ::CloseHandle(overlapped.hEvent);
    return ok;
}

int Device::read(uint8_t out[kPayloadSize], int timeoutMs) {
    if (!isOpen()) {
        impl_->lastError = "device is not open";
        return -1;
    }

    std::vector<uint8_t> buffer(std::max<size_t>(impl_->inputReportLength,
                                                 1 + kPayloadSize),
                                0);

    OVERLAPPED overlapped{};
    overlapped.hEvent = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!overlapped.hEvent) {
        impl_->lastError = lastErrorMessage("CreateEvent");
        return -1;
    }

    int   result = -1;
    DWORD got    = 0;
    bool  ok     = ::ReadFile(impl_->handle, buffer.data(),
                              static_cast<DWORD>(buffer.size()), &got,
                              &overlapped) != FALSE;

    if (!ok && ::GetLastError() == ERROR_IO_PENDING) {
        const DWORD wait = ::WaitForSingleObject(
            overlapped.hEvent, timeoutMs < 0 ? INFINITE : static_cast<DWORD>(timeoutMs));

        if (wait == WAIT_OBJECT_0) {
            ok = ::GetOverlappedResult(impl_->handle, &overlapped, &got, FALSE) != FALSE;
        } else {
            // Timed out: abandon the read so the handle stays usable.
            ::CancelIo(impl_->handle);
            ::CloseHandle(overlapped.hEvent);
            return 0;
        }
    }

    if (!ok) {
        impl_->lastError = lastErrorMessage("ReadFile");
    } else if (got < 1) {
        result = 0;
    } else {
        const size_t payloadBytes =
            std::min<size_t>(static_cast<size_t>(got) - 1, kPayloadSize);

        std::memset(out, 0, kPayloadSize);
        std::memcpy(out, buffer.data() + 1, payloadBytes);

        impl_->lastError.clear();
        result = static_cast<int>(payloadBytes);
    }

    ::CloseHandle(overlapped.hEvent);
    return result;
}

const DeviceInfo& Device::info() const {
    return impl_->info;
}

const std::string& Device::lastError() const {
    return impl_->lastError;
}

}  // namespace usbkvm
