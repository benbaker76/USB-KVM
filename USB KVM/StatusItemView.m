//
//  StatusItemView.m
//  USB KVM
//
//  Created by Ben Baker on 6/19/15.
//  Copyright (c) 2015 Headsoft. All rights reserved.
//


#import "StatusItemView.h"

@implementation StatusItemView

- (instancetype) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];

	if(self)
	{
		NSImageView *imageView = [[NSImageView alloc] initWithFrame:frameRect];
		[self addSubview:imageView];
		self.imageView = imageView;
		[imageView release];
	}

	return self;
}

- (void)dealloc
{
	[_image release];
	
	[super dealloc];
}

- (void) setImage:(NSImage*)image
{
	self.imageView.image = image;
}

- (void) mouseDown:(NSEvent*)theEvent
{
	if (self.selector != nil && self.mouseDownAction != nil)
		[self.selector performSelector:self.mouseDownAction withObject:self];
}

- (void) rightMouseDown:(NSEvent*)theEvent
{
	if (self.selector != nil && self.rightMouseDownAction != nil)
		[self.selector performSelector:self.rightMouseDownAction withObject:self];
}

@end
