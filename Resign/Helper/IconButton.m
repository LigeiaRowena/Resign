//
//  IconButton.m
//  Resign
//
//  Created by Francesca Corsini on 11/04/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import "IconButton.h"

@implementation IconButton

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

- (void)setImage:(NSImage *)image
{
	NSImage *img = [[NSImage alloc] initWithContentsOfFile:self.fileName];
	[super setImage:img];
}

/*
- (NSImage*)image
{
	return nil;
}
 */

@end
