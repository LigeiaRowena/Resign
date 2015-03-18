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
    
    NSString *sourcePath;
    NSString *workingPath;
    
    NSTask *unzipTask;
}

@property (weak) IBOutlet IRTextFieldDrag *ipaField;
@property (weak) IBOutlet NSButton *infoIpaFile;
@property (weak) IBOutlet NSComboBox *provisioningComboBox;
@property (weak) IBOutlet NSButton *infoProvisioning;

@property (weak) IBOutlet NSTextField *statusLabel;



@end
