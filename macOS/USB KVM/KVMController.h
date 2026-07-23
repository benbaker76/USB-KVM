//
//  KVMController.h
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HIDCommand.h"
#import "P_HIDManager.h"

@interface KVMController : NSObject <NSApplicationDelegate>
{
	HIDCommand *m_hidCommand;
	P_HIDManager *m_hidManager;
}

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (assign) IBOutlet NSMenu *statusMenu;
@property(assign) IBOutlet NSMenuItem *launchAtLoginMenuItem;

-(IBAction)doSwitch:(id)sender;
-(IBAction)showMenu:(id)sender;
- (IBAction)toggleLaunchAtLogin:(id)sender;

@end

