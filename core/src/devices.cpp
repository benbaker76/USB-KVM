// devices.cpp — supported-hardware table and report-descriptor helpers.

#include "usbkvm/usbkvm.h"

#include "internal.h"

namespace usbkvm {

namespace {

// ActionStar Enterprise vendor IDs. The same silicon ships under both.
constexpr uint16_t kVendorActionStarA = 0x0835;
constexpr uint16_t kVendorActionStarB = 0x2101;

constexpr uint16_t kProducts[] = {0x1403, 0x1404, 0x1406, 0x1407, 0x1411};

}  // namespace

bool isSupported(uint16_t vendorId, uint16_t productId) {
    if (vendorId != kVendorActionStarA && vendorId != kVendorActionStarB)
        return false;

    for (uint16_t product : kProducts) {
        if (product == productId)
            return true;
    }
    return false;
}

namespace internal {

bool descriptorHasUsagePage(const uint8_t* data, size_t size, uint16_t page) {
    size_t i = 0;

    while (i < size) {
        const uint8_t prefix = data[i];

        // Long item: 0b1111'1110. Length lives in the following byte.
        if (prefix == 0xFE) {
            if (i + 2 >= size)
                return false;
            const size_t dataSize = data[i + 1];
            i += 3 + dataSize;
            continue;
        }

        // Short item: bSize in bits 0-1, bType in 2-3, bTag in 4-7. A bSize of
        // 3 encodes four bytes, not three.
        size_t dataSize = prefix & 0x03;
        if (dataSize == 3)
            dataSize = 4;

        if (i + 1 + dataSize > size)
            return false;

        // Global (bType 1), Usage Page (bTag 0) => prefix & 0xFC == 0x04.
        if ((prefix & 0xFC) == 0x04) {
            uint32_t value = 0;
            for (size_t b = 0; b < dataSize; ++b)
                value |= static_cast<uint32_t>(data[i + 1 + b]) << (8 * b);

            if (value == page)
                return true;
        }

        i += 1 + dataSize;
    }

    return false;
}

}  // namespace internal
}  // namespace usbkvm
