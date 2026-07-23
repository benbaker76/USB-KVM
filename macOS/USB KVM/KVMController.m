//
//  KVMController.m
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "KVMController.h"
#import "HID_Utilities.h"
#import "HIDManager.h"
#import "LaunchOnStartup.h"
#import "StatusItemView.h"
#import <IOKit/IOKitLib.h>

@implementation KVMController

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CGFloat width = 24.0;
	CGFloat height = [NSStatusBar systemStatusBar].thickness;
	NSRect viewFrame = NSMakeRect(0, 0, width, height);
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	StatusItemView *statusItemView = [[StatusItemView alloc] initWithFrame:viewFrame];
	[self.statusItem setView:statusItemView];
	[self.statusItem setMenu:_statusMenu];
	NSImage *image = [NSImage imageNamed:@"IconStatusBarError"];
	[((StatusItemView *)self.statusItem.view) setImage:image];
	
	[statusItemView setSelector:self];
	[statusItemView setMouseDownAction:@selector(doSwitch:)];
	[statusItemView setRightMouseDownAction:@selector(showMenu:)];
	
	// NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	// [NSApp setServicesProvider:self];

	//[self resetDefaults];
	[self setDefaults];
	[self loadSettings];
	
	m_hidManager = [[HIDManager alloc] init];
	NSMutableArray *newDeviceRefQueue = [m_hidManager registerDeviceNotification:@selector(deviceNotification:deviceRefArray:message:) toTarget:self withObject:0];
	
	//[self deviceNotification:0 deviceRefArray:newDeviceRefQueue message:0];
	[self performSelectorInBackground:@selector(deviceAddedNotification:) withObject:newDeviceRefQueue];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self saveSettings];
	
	[_statusItem release];
	[m_hidCommand stop];
	[m_hidCommand release];
	m_hidCommand = 0;
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	[self doSwitch:self];
	
	return 0;
}

-(NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	return nil;
}

- (void)resetDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dictionary = [defaults dictionaryRepresentation];
	
	for (id key in dictionary)
		[defaults removeObjectForKey:key];
	
	[defaults synchronize];
}

- (void)setDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										@NO, @"LaunchAtLogin",
										nil];
	
	[defaults registerDefaults:defaultsDictionary];
	[defaults synchronize];
}

- (void)loadSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	_launchAtLoginMenuItem.state = [defaults boolForKey:@"LaunchAtLogin"];
}

- (void)saveSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setBool:_launchAtLoginMenuItem.state forKey:@"LaunchAtLogin"];
	
	[defaults synchronize];
}

-(void)deviceAddedNotification:(NSMutableArray *)deviceRefArray
{
	id enumerator = [deviceRefArray objectEnumerator];
	
	while (true)
	{
		NSNumber *value = [enumerator nextObject];
		
		if (!value)
			break;
		
		[self deviceAdded:[value unsignedIntValue]];
	}
}

-(void)deviceRemovedNotification:(NSMutableArray *)deviceRefArray
{
	id enumerator = [deviceRefArray objectEnumerator];
	
	while (true)
	{
		NSNumber *value = [enumerator nextObject];
		
		if (!value)
			break;
		
		[self deviceRemoved:[value unsignedIntValue]];
	}
}

-(void)deviceNotification:(id)sender deviceRefArray:(NSMutableArray *)deviceRefArray message:(uint8_t)message
{
	if (message == 1)
		[self deviceRemovedNotification:deviceRefArray];
	else
		[self deviceAddedNotification:deviceRefArray];
}

-(void)hidKeyNotification:(id)sender key:(char *)key
{
}

-(void)deviceAdded:(io_object_t)deviceRef
{
	if (!m_hidCommand)
	{
		m_hidCommand = [[HIDCommand alloc] initWithDeviceRef:deviceRef];
		[m_hidCommand start:@selector(hidKeyNotification:key:) toTarget:self withObject:0];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSImage *image = [NSImage imageNamed:@"IconStatusBar"];
			[((StatusItemView *)self.statusItem.view) setImage:image];
		});
	}
}

-(void)deviceRemoved:(io_object_t)deviceRef
{
	if (m_hidCommand)
	{
		if ([m_hidCommand deviceRef] == deviceRef)
		{
			[m_hidCommand stop];
			[m_hidCommand release];
			m_hidCommand = 0;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				NSImage *image = [NSImage imageNamed:@"IconStatusBarError"];
				[((StatusItemView *)self.statusItem.view) setImage:image];
			});
		}
	}
}

-(IBAction)doSwitch:(id)sender
{
	if (!m_hidCommand)
		return;
	
	char data[4];
	
	data[0] = 0x5C;
	data[1] = 0x04;
	data[2] = 0x00;
	data[3] = 0x00;
	
	[m_hidCommand sendCommand:&data[0]];
}

-(IBAction)showMenu:(id)sender
{
	[_statusItem.menu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
}

- (IBAction)toggleLaunchAtLogin:(id)sender
{
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	
	[menuItem setState:!menuItem.state];
	
	[LaunchOnStartup addAppToStartup:menuItem.state];
}

@end
