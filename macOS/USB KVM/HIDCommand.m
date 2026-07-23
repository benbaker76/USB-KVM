//
//  HIDCommand.m
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "HIDCommand.h"
#import "P_HIDCommand.h"
#import <objc/message.h>

@implementation HIDCommand

-(id)initWithDeviceRef:(io_object_t)deviceRef
{
	self = [super initWithDeviceRef:deviceRef];
	
	if(self)
	{
	}
	
	return self;
}

-(char)start:(SEL)selector toTarget:(id)target withObject:(id)object
{
	char retValue = [super start];
	m_keyNotification.selector = selector;
	m_keyNotification.target = target;
	m_keyNotification.object = object;
	RecElement *recElement = (RecElement *)[[m_recDevice.queueElements objectAtIndex:0] unsignedLongLongValue];
	HRESULT result = [self hidGetElementValue:recElement];
	m_reportIn[0] = result;
	recElement = (RecElement *)[[m_recDevice.queueElements objectAtIndex:1] unsignedLongLongValue];
	result = [self hidGetElementValue:recElement];
	m_reportIn[1] = result;
	m_reportIn[2] = result >> 8;
	
	if ([target respondsToSelector:m_keyNotification.selector])
		objc_msgSend(m_keyNotification.target, m_keyNotification.selector, m_keyNotification.object, m_reportIn);
	
	return retValue;
}

-(void)stop
{
	[super stop];
}


-(void)queueEventCallback
{
	int i;
	AbsoluteTime timestamp;
	char value[4] = {};
	IOHIDElementCookie cookie = 0;
	
	RecElement *recElement = (RecElement *)[[m_recDevice.queueElements objectAtIndex:0] unsignedLongLongValue];
	
	if (recElement)
	{
		for (i = 0; ; i = 1)
		{
			if ([self hidGetElementValueAndCookie:value cookie:&cookie timestamp:&timestamp] != kIOReturnSuccess)
				break;
			
			m_reportIn[cookie - recElement->cookie] = value[0];
			
			if (recElement->cookie < cookie)
			{
				m_reportIn[cookie - recElement->cookie + 1] = value[1];
				m_reportIn[cookie - recElement->cookie + 2] = value[2];
			}
		}
		
		if (i && [m_keyNotification.target respondsToSelector:m_keyNotification.selector])
			objc_msgSend(m_keyNotification.target, m_keyNotification.selector, m_keyNotification.object, m_reportIn);
	}
}

-(int)sendCommand:(char *)command
{
	return [self hidSetElementValue:command];
}

@end
