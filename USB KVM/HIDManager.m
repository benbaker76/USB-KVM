//
//  HIDCommand.m
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "HIDManager.h"
#import "P_HIDManager.h"
#import <objc/message.h>

@implementation HIDManager

-(BOOL)isDeviceSupported:(NSNumber *)vendorID productID:(NSNumber *)productID
{
	NSMutableArray *infoPlist = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"DeviceList"];
	
	for (NSDictionary *dictionary in infoPlist)
	{
		NSNumber *vid = [dictionary objectForKey:@"vendorID"];
		NSNumber *pid = [dictionary objectForKey:@"productID"];
		
		if ([vid intValue] == [vendorID intValue] && [pid intValue] == [productID intValue])
			return YES;
	}

	return NO;
}

@end
