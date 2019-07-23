//
//  StatusItemView.h
//  USB KVM
//
//  Created by Ben Baker on 6/19/15.
//  Copyright (c) 2015 Headsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSView
{
}

@property(assign, nonatomic) NSImageView *imageView;
@property(strong, nonatomic) NSImage *image;
@property(assign, nonatomic) id selector;
@property(assign, nonatomic) SEL mouseDownAction;
@property(assign, nonatomic) SEL rightMouseDownAction;

@end
