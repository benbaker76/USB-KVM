//
//  P_HIDManager.h
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HID_Utilities.h"

typedef struct
{
	id hidManager;
	io_object_t hidDevice;
	uint32_t removedIter;
} DeviceRemoved;

@interface P_HIDManager : NSObject
{
	NSMutableArray *m_deviceArray;
	uint32_t m_usagePage;
	uint32_t m_usage;
	struct IONotificationPort *m_notifyPort;
	uint32_t m_addedIter;
	NSMutableArray *m_newDeviceRefQueue;
	NSMutableArray *m_removedDeviceRefQueue;
	Notification m_deviceNotification;
}

-(id)init;
-(id)init:(uint32_t)usagePage usage:(uint32_t)usage;
-(void)dealloc;
-(BOOL)isDeviceSupported:(NSNumber *)vendorID productID:(NSNumber *)productID;
-(id)getKeyValueByDeviceRef:(io_object_t)hidDevice forKey:(id)key;
-(void)freeDevice;
-(BOOL)isExist:(io_object_t)hidDevice;
-(int)insertDeviceRef:(io_object_t)hidDevice;
-(void)removeDeviceRef:(io_object_t)hidDevice;
-(void)insertNewDeviceRef2Queue:(io_object_t)hidDevice;
-(void)insertRemovedDeviceRef2Queue:(io_object_t)hidDevice;
-(void)sendMessageToCaller:(uint8_t)message;
-(id)registerDeviceNotification:(SEL)selector toTarget:(id)target withObject:(id)object;
void rawDeviceAdded(void *refcon, io_iterator_t iterator);
void rawDeviceRemoved(void *refcon, io_service_t service, uint32_t messageType, void *messageArgument);

@end
