//
//  P_HIDCommand.h
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HID_Utilities.h"

@interface P_HIDCommand : NSObject
{
	io_object_t m_deviceRef;
	CFRunLoopRef m_hidRunLoopRef;
	RecDevice m_recDevice;
	BOOL m_addAsChild;
}

-(id)initWithDeviceRef:(io_object_t)deviceRef;
-(void)dealloc;
-(char)start;
-(void)stop;
-(NSString *)vendorID;
-(NSString *)productID;
-(NSString *)locationID;
-(NSString *)productName;
-(uint32_t)maxOutputReportSize;
-(io_object_t)deviceRef;
-(HRESULT)hidSetElementValue:(char *)value;
-(HRESULT)hidGetElementValueAndCookie:(char *)value cookie:(IOHIDElementCookie *)cookie timestamp:(AbsoluteTime *)timestamp;
-(HRESULT)hidGetElementValue:(RecElement *)recElement;
-(void)hidGetCollectionElements:(NSMutableDictionary *)dictionary recElement:(RecElement **)recElement;
-(void)hidGetElements:(id)value recElement:(RecElement **)recElement;
-(void)hidGetElementsNSArrayHandler:(id)value withObject:(RecElement **)recElement;
-(void)hidAddElement:(NSMutableDictionary *)value recElement:(RecElement **)recElement;
-(void)hidGetElementInfo:(NSDictionary *)value recElement:(RecElement *)recElement;
-(void)hidDisposeDeviceElements:(RecElement *)recElement;
-(RecElement *)getElement:(RecElement *)recElement usagePage:(uint16_t)usagePage usage:(uint16_t)usage type:(uint16_t)type elementCount:(char *)elementList;
-(void)createHIDInterfaces:(NSNumber *)value;
-(void)queueEventCallback;
-(kern_return_t) hidCreateOpenDeviceInterface:(io_service_t)service runLoopRef:(CFRunLoopRef)runLoop runLoopSourceRef:(CFRunLoopSourceRef *)runLoopSource;
-(void)hidCloseReleaseInterface;
-(int)hidQueueElement:(RecElement *)recElement;
-(int)hidDequeueElement:(RecElement *)recElement;
-(int)hidQueueOutputElement:(RecElement *)recElement;
-(int)hidDequeueOutputElement:(RecElement *)recElement;
-(void)queueElement:(RecElement *)recElement elementList:(NSMutableArray **)elementList found:(BOOL *)found;
-(void)removeElementFromQueue:(NSMutableArray **)elementList;
-(void)queueOutputElement:(RecElement *)recElement elementList:(NSMutableArray **)elementList found:(BOOL *)found;
-(void)removeOutputElementFromQueue:(NSMutableArray **)elementList;

@end
