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
    // datas for combobox
	NSMutableArray *provisioningArray;
    NSMutableArray *certificatesArray;
	NSDateFormatter *formatter;
	
	// source ipa path
    NSString *sourcePath;
	
	// temp working directory
    NSString *workingPath;
	
	// path of the unzipped ipa (inside the workingPath)
    NSString *appPath;
	
	// destination ipa path
	NSString *destinationPath;
    
    // tasks
    NSTask *unzipTask;
    NSTask *certTask;
}

// Resign UI
@property (weak) IBOutlet IRTextFieldDrag *ipaField;
@property (weak) IBOutlet NSButton *infoIpaFile;
@property (weak) IBOutlet NSComboBox *provisioningComboBox;
@property (weak) IBOutlet NSButton *infoProvisioning;
@property (weak) IBOutlet NSComboBox *certificateComboBox;
@property (weak) IBOutlet NSButton *infoCertificate;
@property (weak) IBOutlet NSTextField *bundleIDField;
@property (weak) IBOutlet NSButton *bundleIDButton;
@property (weak) IBOutlet NSTextField *displayNameField;
@property (weak) IBOutlet NSButton *displayNameButton;
@property (weak) IBOutlet NSTextField *destinationIpaPath;
@property (weak) IBOutlet NSButton *destinationIpaPathButton;


// Console UI
@property (weak) IBOutlet NSButton *cleanConsoleButton;
@property (weak) IBOutlet NSButton *resetAllButton;
@property (weak) IBOutlet NSButton *resignButton;
@property (weak) IBOutlet NSScrollView *statusField;



@end
