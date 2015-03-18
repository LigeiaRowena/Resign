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
    NSMutableArray *certificatesArray;
	NSDateFormatter *formatter;
    
    NSString *sourcePath;
    NSString *workingPath;
    NSString *appPath;
    
    NSTask *unzipTask;
    NSTask *certTask;
}

@property (weak) IBOutlet IRTextFieldDrag *ipaField;
@property (weak) IBOutlet NSButton *infoIpaFile;
@property (weak) IBOutlet NSComboBox *certificateComboBox;
@property (weak) IBOutlet NSButton *infoCertificate;
@property (weak) IBOutlet NSComboBox *provisioningComboBox;
@property (weak) IBOutlet NSButton *infoProvisioning;

@property (weak) IBOutlet NSButton *cleanConsoleButton;
@property (weak) IBOutlet NSButton *resetAllButton;
@property (weak) IBOutlet NSButton *resignButton;
@property (weak) IBOutlet NSScrollView *statusField;



@end
