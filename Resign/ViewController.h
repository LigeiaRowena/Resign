//
//  ViewController.h
//  Resign
//
//  Created by Francesca Corsini on 17/03/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IRTextFieldDrag.h"
#import "IconButton.h"

@interface ViewController : NSViewController <IRTextFieldDragDelegate>

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
@property (weak) IBOutlet NSTextField *shortVersionField;
@property (weak) IBOutlet NSButton *defaultShortVersionButton;
@property (weak) IBOutlet NSTextField *buildVersionField;
@property (weak) IBOutlet NSButton *defaultBuildVersionButton;
@property (weak) IBOutlet NSButton *defaultIconsButton;
@property (weak) IBOutlet IconButton *iconButton;
@property (weak) IBOutlet IconButton *retinaIconButton;

// Console UI
@property (weak) IBOutlet NSButton *cleanConsoleButton;
@property (weak) IBOutlet NSButton *defaultSettingsButton;
@property (weak) IBOutlet NSButton *resignButton;
@property (weak) IBOutlet NSScrollView *statusField;
@property (weak) IBOutlet NSButton *resetAllButton;

@end
