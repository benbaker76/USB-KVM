//
//  HIDCommand.h
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/hid/IOHIDBase.h>
#import "P_HIDCommand.h"

@interface HIDCommand : P_HIDCommand
{
	Notification m_keyNotification;
	char m_reportIn[4];
}

-(id)initWithDeviceRef:(io_object_t)deviceRef;
-(char)start:(SEL)selector toTarget:(id)target withObject:(id)object;
-(void)stop;
-(void)queueEventCallback;
-(int)sendCommand:(char *)command;

@end
