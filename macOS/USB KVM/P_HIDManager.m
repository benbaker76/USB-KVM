//
//  P_HIDManager.m
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "P_HIDManager.h"

@implementation P_HIDManager

-(id)init
{
	return [self init:1 usage:2];
}

-(id)init:(uint32_t)usagePage usage:(uint32_t)usage
{
	self = [super init];
	
	if (self)
	{
		m_usagePage = usagePage;
		m_usage = usage;
		
		m_deviceArray = [[NSMutableArray alloc] initWithCapacity:2];
		m_newDeviceRefQueue = [[NSMutableArray alloc] initWithCapacity:2];
		m_removedDeviceRefQueue = [[NSMutableArray alloc] initWithCapacity:2];
	}
	
	return self;
}

-(void)dealloc
{
	[self freeDevice];
	[super dealloc];
}

-(BOOL)isDeviceSupported:(NSNumber *)vendorID productID:(NSNumber *)productID
{
	return 0;
}

-(id)getKeyValueByDeviceRef:(io_object_t)hidDevice forKey:(id)key
{
	id retValue = nil;
	CFMutableDictionaryRef properties = nil;
	NSMutableDictionary *propertiesDictionary = nil;
	
	int i = 12;
	
	do
	{
		retValue = 0;
		
		if (IORegistryEntryCreateCFProperties(hidDevice, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess)
		{
			propertiesDictionary = (__bridge NSMutableDictionary *)properties;
			
			id value = [propertiesDictionary objectForKey:key];
			
			if (value)
				retValue = [[value copy] autorelease];
		}
		
		if (propertiesDictionary)
			[propertiesDictionary release];
		
		if (retValue)
			break;
		
		usleep(1000000);
		
		--i;
	}
	while (i);
	
	return retValue;
}

-(void)freeDevice
{
	for (int i = 0; i < [m_deviceArray count]; i++)
	{
		NSNumber *address = [m_deviceArray objectAtIndex:i];
		
		if (address)
			IOObjectRelease([address unsignedIntValue]);
	}
	
	if (m_notifyPort)
		IONotificationPortDestroy(m_notifyPort);
	
	IOObjectRelease(m_addedIter);
	
	[m_deviceArray release];
	[m_newDeviceRefQueue release];
	[m_removedDeviceRefQueue release];
}

-(BOOL)isExist:(io_object_t)hidDevice
{
	if (m_deviceArray)
	{
		for (int i = 0; i < [m_deviceArray count]; i++)
		{
			NSNumber *address = [m_deviceArray objectAtIndex:i];
			
			if (address && [address unsignedIntValue] == hidDevice)
				return YES;
		}
	}
	
	return NO;
}

-(int)insertDeviceRef:(io_object_t)hidDevice
{
	kern_return_t result = kIOReturnError;
	
	if (![self isExist:hidDevice])
	{
		[m_deviceArray addObject:[NSNumber numberWithUnsignedInt:hidDevice]];
		DeviceRemoved *deviceRemoved = (DeviceRemoved *)NSAllocateMemoryPages(sizeof(DeviceRemoved));
		deviceRemoved->hidManager = self;
		deviceRemoved->hidDevice = hidDevice;
		IOServiceAddInterestNotification(m_notifyPort, hidDevice, kIOGeneralInterest, rawDeviceRemoved, deviceRemoved, &deviceRemoved->removedIter);
		
		result = kIOReturnSuccess;
	}
	
	return result;
}

-(void)removeDeviceRef:(io_object_t)hidDevice
{
	for (int i = 0; i < [m_deviceArray count]; i++)
	{
		NSNumber *address = [m_deviceArray objectAtIndex:i];
		
		if (address && [address unsignedIntValue] == hidDevice)
		{
			[m_deviceArray removeObjectAtIndex:i];
			
			return;
		}
	}
}

-(void)insertNewDeviceRef2Queue:(io_object_t)hidDevice
{
	[m_newDeviceRefQueue addObject:[NSNumber numberWithUnsignedInt:hidDevice]];
}

-(void)insertRemovedDeviceRef2Queue:(io_object_t)hidDevice
{
	[m_removedDeviceRefQueue addObject:[NSNumber numberWithUnsignedInt:hidDevice]];
}

-(void)sendMessageToCaller:(uint8_t)message
{
	NSMutableArray *deviceArray = nil;
	
	if (m_deviceNotification.selector)
	{
		if (message == 0)
		{
			deviceArray = [[m_newDeviceRefQueue copy] autorelease];
			[m_newDeviceRefQueue removeAllObjects];
		}
		else
		{
			if (message != 1)
				return;
			
			deviceArray = [[m_removedDeviceRefQueue copy] autorelease];
			[m_removedDeviceRefQueue removeAllObjects];
		}
		
		objc_msgSend(m_deviceNotification.target, m_deviceNotification.selector, m_deviceNotification.object, deviceArray, message);
	}
}

-(id)registerDeviceNotification:(SEL)selector toTarget:(id)target withObject:(id)object
{
	kern_return_t result;
	CFMutableDictionaryRef hidMatchDictionary;
	NSMutableArray *newDeviceRefQueue = nil;
	SInt32 productID;
	SInt32 vendorID;
	
	hidMatchDictionary = IOServiceMatching(kIOHIDDeviceKey);
	
	if (hidMatchDictionary)
	{
		CFRetain(hidMatchDictionary);
		
		m_notifyPort = IONotificationPortCreate(kIOMasterPortDefault);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(m_notifyPort), kCFRunLoopDefaultMode);
		
		if (m_usagePage)
			CFDictionarySetValue(hidMatchDictionary, CFSTR(kIOHIDDeviceUsagePageKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &m_usagePage));
		
		if (m_usage)
			CFDictionarySetValue(hidMatchDictionary, CFSTR(kIOHIDDeviceUsageKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &m_usage));
		
		vendorID = 0x0835;
		productID = 0x1411;
		CFDictionarySetValue(hidMatchDictionary, CFSTR(kIOHIDVendorIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &vendorID));
		CFDictionarySetValue(hidMatchDictionary, CFSTR(kIOHIDProductIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &productID));
		IOServiceAddMatchingNotification(m_notifyPort, kIOFirstMatchNotification, hidMatchDictionary, rawDeviceAdded, self, &m_addedIter);
		rawDeviceAdded(self, m_addedIter);
		
		vendorID = 0x2101;
		productID = 0x1406;
		CFDictionarySetValue(hidMatchDictionary, CFSTR(kIOHIDVendorIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &vendorID));
		CFDictionarySetValue(hidMatchDictionary, CFSTR(kIOHIDProductIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &productID));
		IOServiceAddMatchingNotification(m_notifyPort, kIOFirstMatchNotification, hidMatchDictionary, rawDeviceAdded, self, &m_addedIter);
		rawDeviceAdded(self, m_addedIter);
		
		newDeviceRefQueue = [[m_newDeviceRefQueue copy] autorelease];
		
		[m_newDeviceRefQueue removeAllObjects];
		m_deviceNotification.selector = selector;
		m_deviceNotification.target = target;
		m_deviceNotification.object = object;
	}
	
	hidMatchDictionary = NULL;
	
	return newDeviceRefQueue;
}

void rawDeviceAdded(void *refcon, io_iterator_t iterator)
{
	P_HIDManager *hidManager = (__bridge P_HIDManager *)refcon;
	io_object_t hidDevice = 0;
	
	while ((hidDevice = IOIteratorNext(iterator)))
	{
		NSNumber *vendorID = [hidManager getKeyValueByDeviceRef:hidDevice forKey:@"VendorID"];
		NSNumber *productID = [hidManager getKeyValueByDeviceRef:hidDevice forKey:@"ProductID"];
		
		if ([hidManager isDeviceSupported:vendorID productID:productID] && ![hidManager insertDeviceRef:hidDevice])
			[hidManager insertNewDeviceRef2Queue:hidDevice];
	}
	
	[hidManager sendMessageToCaller:0];
}

void rawDeviceRemoved(void *refcon, io_service_t service, uint32_t messageType, void *messageArgument)
{
	DeviceRemoved *deviceRemoved = (__bridge DeviceRemoved *)refcon;
	P_HIDManager *hidManager = deviceRemoved->hidManager;
	
	if (messageType == kIOMessageServiceIsTerminated)
	{
		[hidManager removeDeviceRef:deviceRemoved->hidDevice];
		[hidManager insertRemovedDeviceRef2Queue:deviceRemoved->hidDevice];
		
		IOObjectRelease(deviceRemoved->hidDevice);
		IOObjectRelease(deviceRemoved->removedIter);
		NSDeallocateMemoryPages(deviceRemoved, sizeof(DeviceRemoved));
		
		[hidManager sendMessageToCaller:1];
	}
}

@end
