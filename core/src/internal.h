// internal.h — helpers shared between the platform backends. Not installed.

#ifndef USBKVM_INTERNAL_H
#define USBKVM_INTERNAL_H

#include <cstddef>
#include <cstdint>

namespace usbkvm {
namespace internal {

// Walks a HID report descriptor looking for a Global "Usage Page" item equal to
// `page`. Used to tell the vendor collection (0xFF01) apart from the mouse
// collection the same device also publishes.
//
// Returns false on a malformed descriptor rather than reading out of bounds.
bool descriptorHasUsagePage(const uint8_t* data, size_t size, uint16_t page);

}  // namespace internal
}  // namespace usbkvm

#endif  // USBKVM_INTERNAL_H
