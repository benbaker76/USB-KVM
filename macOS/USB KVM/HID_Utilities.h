//
//  HID_Utilities.h
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#ifndef HID_Utilities_h
#define HID_Utilities_h

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDBase.h>

typedef struct
{
	id target;
	SEL selector;
	id object;
} __attribute__((packed)) Notification;

typedef struct RecElement
{
	IOHIDElementType type;					// the type defined by IOHIDElementType in IOHIDKeys.h
	uint32_t usagePage;						// usage page from IOUSBHIDParser.h which defines general usage
	uint32_t usage;							// usage within above page from IOUSBHIDParser.h which defines specific usage
	IOHIDElementCookie cookie;				// unique value (within device of specific vendorID and productID) which identifies element, will NOT change
	uint32_t min;							// reported min value possible
	uint32_t max;							// reported max value possible
	uint32_t scaledMin;						// reported scaled min value possible
	uint32_t scaledMax;						// reported scaled max value possible
	uint32_t size;							// size in bits of data return from element
	Boolean relative;						// are reports relative to last report (deltas)
	Boolean wrapping;						// does element wrap around (one value higher than max is min)
	Boolean nonLinear;						// are the values reported non-linear relative to element movement
	Boolean preferredState;					// does element have a preferred state (such as a button)
	Boolean nullState;						// does element have null state
	uint32_t units;							// units value is reported in (not used very often)
	uint32_t unitExp;						// exponent for units (also not used very often)
	Str255 name;							// name of element (not used often)
	
	// runtime variables
	uint32_t minReport; 					// min returned value
	uint32_t maxReport; 					// max returned value (calibrate call)
	uint32_t userMin; 						// user set value to scale to (scale call)
	uint32_t userMax;
	
	struct RecElement *pPrevious;			// previous element (NULL at list head)
	struct RecElement *pChild;				// next child (only of collections)
	struct RecElement *pSibling;			// next sibling (for elements and collections)
} __attribute__((packed)) RecElement;

typedef struct
{
	IOHIDDeviceInterface **interface;		// interface to device, NULL = no interface
	IOHIDQueueInterface **queue;			// device queue, NULL = no queue
	CFRunLoopSourceRef queueRunLoopSource;	// device queue run loop source, NULL == no source
	IOHIDOutputTransactionInterface **outputTransaction;		// output transaction interface, NULL == no transaction
	io_object_t notification;				// notifications
	NSString *transport;					// device transport
	NSString *vendorID;						// id for device vendor, unique across all devices
	NSString *productID;					// id for particular product, unique across all of a vendors devices
	NSString *version;						// version of product
	NSString *manufacturer;					// name of manufacturer
	NSString *productName;					// name of product
	NSString *serial;						// serial number of specific product, can be assumed unique across specific product or specific vendor (not used often)
	NSString *locationID;					// long representing location in USB (or other I/O) chain which device is pluged into, can identify specific device on machine
	uint16_t usage;							// usage page from IOUSBHID Parser.h which defines general usage
	uint16_t usagePage;						// usage within above page from IOUSBHID Parser.h which defines specific usage
	uint32_t totalElements;					// number of total elements (should be total of all elements on device including collections) (calculated, not reported by device)
	uint32_t features;						// number of elements of type kIOHIDElementTypeFeature
	uint32_t inputs;						// number of elements of type kIOHIDElementTypeInput_Misc or kIOHIDElementTypeInput_Button or kIOHIDElementTypeInput_Axis or kIOHIDElementTypeInput_ScanCodes
	uint32_t outputs;						// number of elements of type kIOHIDElementTypeOutput
	uint32_t collections;					// number of elements of type kIOHIDElementTypeCollection
	uint32_t axis;							// number of axis (calculated, not reported by device)
	uint32_t buttons;						// number of buttons (calculated, not reported by device)
	uint32_t hats;							// number of hat switches (calculated, not reported by device)
	uint32_t sliders;						// number of sliders (calculated, not reported by device)
	uint32_t dials;							// number of dials (calculated, not reported by device)
	uint32_t wheels;						// number of wheels (calculated, not reported by device)
	uint32_t maxOutputReportSize;
	RecElement *pListElements; 				// head of linked list of elements
	struct RecDevice *pNext; 				// next device
	NSMutableArray *queueElements; 			// queue elements
	NSMutableArray *outputElements; 		// output elements
} __attribute__((packed)) RecDevice;

extern void HIDGetUsageName(uint16_t usagePage, uint16_t usage, char *name);

#endif /* HID_Utilities_h */
