//
//  ViewController.h
//  Resign
//
//  Created by Francesca Corsini on 17/03/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IRTextFieldDrag.h"

@interface ViewController : NSViewController <IRTextFieldDragDelegate>
{
	NSMutableArray *provisioningArray;
	NSDateFormatter *formatter;
}

@property (weak) IBOutlet IRTextFieldDrag *ipaField;
@property (weak) IBOutlet NSComboBox *provioningComboBox;

@property (weak) IBOutlet NSTextField *statusLabel;



@end
