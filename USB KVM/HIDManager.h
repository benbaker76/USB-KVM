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
#import "P_HIDManager.h"

@interface HIDManager : P_HIDManager
{
}

-(BOOL)isDeviceSupported:(NSNumber *)vendorID productID:(NSNumber *)productID;

@end
