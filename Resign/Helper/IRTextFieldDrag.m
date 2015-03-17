//
//  IRTextFieldDrag.m
//  iReSign
//
//  Created by Esteban Bouza on 01/12/12.
//

#import "IRTextFieldDrag.h"

@implementation IRTextFieldDrag

- (void)awakeFromNib
{
	// Registers the pasteboard types that the receiver will accept as the destination of an image-dragging session
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

#pragma mark - NSDraggingDestination

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	// Invoked after the released image has been removed from the screen, signaling the receiver to import the pasteboard data

    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([[pboard types] containsObject:NSURLPboardType])
	{
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        if (files.count <= 0)
			return NO;

        self.stringValue = [files objectAtIndex:0];
		
		if (self.dragDelegate != nil && [self.dragDelegate respondsToSelector:@selector(performDragOperation:)])
			[self.dragDelegate performDragOperation:self.stringValue];
    }
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// Invoked when the dragged image enters destination bounds or frame; delegate returns dragging operation to perform
    
    if (!self.isEnabled)
		return NSDragOperationNone;
    
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ([[pboard types] containsObject:NSColorPboardType] || [[pboard types] containsObject:NSFilenamesPboardType])
	{
        if (sourceDragMask & NSDragOperationCopy)
		{
			if (self.dragDelegate != nil && [self.dragDelegate respondsToSelector:@selector(draggingEntered:)])
				[self.dragDelegate draggingEntered:self];
			return NSDragOperationCopy;
		}
    }
	
    return NSDragOperationNone;
}


@end
