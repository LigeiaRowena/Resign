//
//  ViewController.m
//  Resign
//
//  Created by Francesca Corsini on 17/03/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import "ViewController.h"
#import "NSScrollView+MultiLine.h"
#import "FileHandler.h"

@interface ViewController ()
@end

@implementation ViewController


- (void)loadView
{
	[super loadView];
		
	// Search for zip utilities
	if (![[FileHandler sharedInstance] searchForZipUtility])
	{
		[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the zip utility present at /usr/bin/zip"];
		exit(0);
	}
	
	// Search for Provisioning Profiles
	[self getProvisioning];
    
    // Search for Signign Certificates
    [self getCertificates];
	
	// Show the default destination ipa path
	[self resetDestinationIpaPath];
}

#pragma mark - ZIP Methods

- (void)unzipIpa
{
    [self disableControls];
    [[FileHandler sharedInstance] unzipIpaFromSource:[self.ipaField stringValue] log:^(NSString *log) {
        [self.statusField appendStringValue:log];
        
    } error:^(NSString *error) {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:error];
        [self enableControls];
        [self.statusField appendStringValue:error];
        
    } success:^(NSString *success){
        [self enableControls];
        [self.statusField appendStringValue:[NSString stringWithFormat:@"Succeed to unzip ipa file in %@", [[[FileHandler sharedInstance] workingPath] stringByAppendingPathComponent:kPayloadDirName]]];
        [self showIpaInfo];
    }];
}

- (void)showIpaInfo
{
    // Show the info of the ipa from the Info.plist file
    [self.statusField appendStringValue:[NSString stringWithFormat:@"Retrieving %@", kInfoPlistFilename]];
    [[FileHandler sharedInstance] showIpaInfoWithSuccess:^(id success) {
        [self.statusField appendStringValue:success];

    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
    }];
    
    
    //Select the provisioning of the app in the relative combobox
    [[FileHandler sharedInstance] showProvisioningInfoWithSuccess:^(id success) {
        int indexProvisioning = [(NSNumber*)success intValue];
        [self.provisioningComboBox selectItemAtIndex:indexProvisioning];
        
    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
    }];
    
    
    //Select the signign-certificate of the app in the relative combobox
    [[FileHandler sharedInstance] showCertificatesInfoWithSuccess:^(id success) {
        int indexCert = [(NSNumber*)success intValue];
        [self.certificateComboBox selectItemAtIndex:indexCert];
        
    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
    }];

    
    //Show the Bundle ID of the app in the relative field
    [self resetDefaultBundleID];
	
	//Show the Product Name of the app in the relative field
	[self resetDefaultProductName];
	
	//Show the default icons of the app in the relative fields
	[self resetDefaultIcons];
}

#pragma mark - Signign Certificate Methods

- (void)showCertificateInfoAtIndex:(NSInteger)index
{
    if ([[[FileHandler sharedInstance] certificatesArray] count] > 0 && index >= 0)
    {
        NSString *certificate = [[FileHandler sharedInstance] certificatesArray][index];
        [self.statusField appendStringValue:certificate];
    }
    else
    {
        [self.statusField appendStringValue:@"No Signign Certificates selected"];
    }
}

- (void)getCertificates
{
    [self disableControls];
    [self.statusField appendStringValue:@"Getting Signign Certificates..."];
    
    [[FileHandler sharedInstance] getCertificatesSuccess:^(NSString *success){
        [self.statusField appendStringValue:@"Signing Certificate IDs extracted"];
        [self enableControls];
        [self.certificateComboBox reloadData];
        
    } error:^(NSString *error) {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:error];
        [self enableControls];
        [self.statusField appendStringValue:error];
    }];    
}


#pragma mark - Provisioning Methods

- (void)getProvisioning
{
    [self disableControls];
    [self.statusField appendStringValue:@"Getting Provisoning Profiles..."];
    
	[[FileHandler sharedInstance] getProvisioningProfiles];
	if ([[[FileHandler sharedInstance] provisioningArray] count] > 0)
	{
		[self enableControls];
		[self.provisioningComboBox reloadData];
        [self.statusField appendStringValue:@"Provisioning Profiles loaded"];
	}
	else
	{
		[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"There aren't Provisioning Profiles"];
		[self enableControls];
        [self.statusField appendStringValue:@"There aren't Provisioning Profiles"];
	}
}

- (void)showProvisioningInfoAtIndex:(NSInteger)index
{
    NSString *provisioningInfo = [[FileHandler sharedInstance] getProvisioningInfoAtIndex:index];
    [self.statusField appendStringValue:provisioningInfo];
}

#pragma mark - Bundle ID Methods

- (void)resetDefaultBundleID
{
    // Succeed to find the Info.plist
    [[FileHandler sharedInstance] getDefaultBundleIDWithSuccess:^(id bundleID) {
        [self.bundleIDButton setState:NSOnState];
        [self.bundleIDField setEditable:NO];
        [self.bundleIDField setSelectable:YES];
        [self.bundleIDField setStringValue:bundleID];
      
    // Failed to find the Info.plist
    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
        [self.bundleIDButton setState:NSOffState];
        [self.bundleIDField setEditable:YES];
        [self.bundleIDField setSelectable:YES];
    }];
}

#pragma mark - Product Name Methods

- (void)resetDefaultProductName
{
    // Succeed to find the Info.plist
    [[FileHandler sharedInstance] getDefaultProductNameWithSuccess:^(id displayName) {
        [self.displayNameButton setState:NSOnState];
        [self.displayNameField setEditable:NO];
        [self.displayNameField setSelectable:YES];
        [self.displayNameField setStringValue:displayName];
        
    // Failed to find the Info.plist
    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
        [self.displayNameButton setState:NSOffState];
        [self.displayNameField setEditable:YES];
        [self.displayNameField setSelectable:YES];
    }];
}

#pragma mark - Destination IPA Path Methods

- (void)resetDestinationIpaPath
{
	NSString *documentFolderPath = [FileHandler getDocumentFolderPath];

	[self.destinationIpaPathButton setState:NSOnState];
	[self.destinationIpaPath setEditable:NO];
	[self.destinationIpaPath setSelectable:YES];
	[self.destinationIpaPath setStringValue:documentFolderPath];
	[FileHandler sharedInstance].destinationPath = documentFolderPath;
}


#pragma mark - Icons Methods

- (void)resetDefaultIcons
{
	// Succeed to find the default icon files
	if ([self getDefaultIconFiles])
	{
        [self.defaultIconsButton setState:NSOnState];
        
        [self.iconButton setTappable:NO];
        [self.retinaIconButton setTappable:NO];
	}
	// Failed to find the default product name
	else
	{
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:@"You didn't select any IPA file, or the IPA file you selected is corrupted."];
		[self.defaultIconsButton setState:NSOffState];
        
        [self.iconButton setTappable:YES];
        [self.retinaIconButton setTappable:YES];
	}
}

- (BOOL)getDefaultIconFiles
{
    __block BOOL success = FALSE;
    
    // Succeed to find icons in the Info.plist
    [[FileHandler sharedInstance] getDefaultIconFilesWithSuccess:^(id icons) {
        NSDictionary *normalIcons = icons[kIconNormal];
        self.iconButton.fileName = [normalIcons allKeys][0];
        [self.iconButton setImage:[normalIcons allValues][0]];
        [self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 76x76 pixels is: %@", self.iconButton.fileName]];
        
        NSDictionary *retinaIcons = icons[kIconRetina];
        self.retinaIconButton.fileName = [retinaIcons allKeys][0];
        [self.retinaIconButton setImage:[retinaIcons allValues][0]];
        [self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 152 pixels is: %@", self.retinaIconButton.fileName]];
        success = TRUE;
        
    // Failed to find the Info.plist or the icons
    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
        [self.defaultIconsButton setState:NSOffState];
        [self.iconButton setEnabled:YES];
        [self.retinaIconButton setEnabled:YES];
        success = FALSE;
    }];
    
    return success;
}

- (void)openNewIconFile:(NSNumber*)iconSize button:(IconButton*)button
{
	NSOpenPanel *opanel = [NSOpenPanel openPanel];
	NSString *desktopFolderPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
	[opanel setDirectoryURL:[NSURL fileURLWithPath:desktopFolderPath]];
	[opanel setCanChooseFiles:TRUE];
	[opanel setCanChooseDirectories:FALSE];
	[opanel setAllowedFileTypes:@[@"png", @"PNG"]];
	[opanel setPrompt:@"Open"];
	[opanel setTitle:@"Open icon file"];
	[opanel setMessage:[NSString stringWithFormat:@"Please select an icon file of size %@x%@ pixels", iconSize, iconSize]];
	
	if ([opanel runModal] == NSOKButton)
	{
		NSString* path = [[opanel URL] path];
		NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
		if (NSEqualSizes(image.size, CGSizeMake(iconSize.floatValue, iconSize.floatValue)))
		{
			button.fileName = path;
			[button setImage:image];
			[self.statusField appendStringValue:[NSString stringWithFormat:@"You selected the icon file: %@ of size %@x%@ pixels", path, iconSize, iconSize]];
		}
		else
		{
			[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:[NSString stringWithFormat:@"You have to select an icon file of size %@x%@ pixels", iconSize, iconSize]];
		}
	}
}

#pragma mark - Actions

- (IBAction)browseIpa:(id)sender
{
	// Browse the IPA file
	NSOpenPanel* openDlg = [NSOpenPanel openPanel];
	[openDlg setCanChooseFiles:TRUE];
	[openDlg setCanChooseDirectories:FALSE];
	[openDlg setAllowsMultipleSelection:FALSE];
	[openDlg setAllowsOtherFileTypes:FALSE];
	[openDlg setAllowedFileTypes:@[@"ipa", @"IPA"]];
	
	if ([openDlg runModal] == NSOKButton)
	{
		NSString* fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
		[self.ipaField setStringValue:fileNameOpened];
		[self unzipIpa];
	}
}

- (IBAction)showProvisioningInfo:(id)sender
{
	[self showProvisioningInfoAtIndex:self.provisioningComboBox.indexOfSelectedItem];
}

- (IBAction)showIpaInfo:(id)sender
{
	[self showIpaInfo];
}

- (IBAction)resetAll:(id)sender
{
    
}

- (IBAction)resign:(id)sender
{
    
}

- (IBAction)cleanConsole:(id)sender
{
    [self.statusField setStringValue:@""];
}

- (IBAction)showCertificateInfo:(id)sender
{
    [self showCertificateInfoAtIndex:self.certificateComboBox.indexOfSelectedItem];
}

- (IBAction)defaultBundleIDButton:(id)sender
{
    // reset default bundle id
    if (self.bundleIDButton.state == NSOnState)
    {
        [self resetDefaultBundleID];
    }
    
    // customized bundle id
    else if (self.bundleIDButton.state == NSOffState)
    {
        [self.bundleIDField setEditable:YES];
        [self.bundleIDField setSelectable:YES];
    }
}

- (IBAction)changeBundleID:(id)sender
{
    [self.statusField appendStringValue:[NSString stringWithFormat:@"You typed the bundle ID: %@", self.bundleIDField.stringValue]];
}


- (IBAction)changeDisplayName:(id)sender
{
	[self.statusField appendStringValue:[NSString stringWithFormat:@"You typed the product name: %@", self.displayNameField.stringValue]];
}

- (IBAction)defaultDisplayNameButton:(id)sender
{
	// reset default display name
	if (self.displayNameButton.state == NSOnState)
	{
		[self resetDefaultProductName];
	}
	
	// customized display name
	else if (self.displayNameButton.state == NSOffState)
	{
		[self.displayNameField setEditable:YES];
		[self.displayNameField setSelectable:YES];
	}
}

- (IBAction)changeDestinationIpaPath:(id)sender
{
	[FileHandler sharedInstance].destinationPath = self.destinationIpaPath.stringValue;
	[self.statusField appendStringValue:[NSString stringWithFormat:@"You typed the destination ipa path: %@", self.destinationIpaPath.stringValue]];
}


- (IBAction)defaultDestinationIpaPath:(id)sender
{
	// reset default Destination Ipa Path (Documents)
	if (self.destinationIpaPathButton.state == NSOnState)
	{
		[self resetDestinationIpaPath];
	}
	
	// customized Destination Ipa Path
	else if (self.destinationIpaPathButton.state == NSOffState)
	{
		[self.destinationIpaPath setEditable:YES];
		[self.destinationIpaPath setSelectable:YES];
	}
}

- (IBAction)defaultIcons:(id)sender
{
	// reset default icons
	if (self.defaultIconsButton.state == NSOnState)
	{
		[self resetDefaultIcons];
	}
	
	// customized icons
	else if (self.defaultIconsButton.state == NSOffState)
	{
		[self.iconButton setEnabled:YES];
		[self.retinaIconButton setEnabled:YES];
	}
}

- (IBAction)changeIcon:(id)sender
{
    IconButton *butt = (IconButton*)sender;
    
    if (butt.tappable)
        [self openNewIconFile:@76 button:sender];
}

- (IBAction)changeRetinaIcon:(id)sender
{
    IconButton *butt = (IconButton*)sender;
    
    if (butt.tappable)
        [self openNewIconFile:@152 button:sender];
}

#pragma mark - IRTextFieldDragDelegate

- (void)performDragOperation:(NSString*)text
{
	[self unzipIpa];
}

#pragma mark - Alert Methods

- (void)showAlertOfKind:(NSAlertStyle)style WithTitle:(NSString *)title AndMessage:(NSString *)message
{
	// Show a critical alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:title];
	[alert setInformativeText:message];
	[alert setAlertStyle:style];
	[alert runModal];
}


#pragma mark - UI

- (void)disableControls
{
	[self.ipaField setEnabled:FALSE];
    [self.infoIpaFile setEnabled:FALSE];
	[self.provisioningComboBox setEnabled:FALSE];
	[self.infoProvisioning setEnabled:FALSE];
    [self.certificateComboBox setEnabled:FALSE];
    [self.infoCertificate setEnabled:FALSE];
    [self.bundleIDField setEnabled:FALSE];
    [self.bundleIDButton setEnabled:FALSE];
	[self.displayNameField setEnabled:FALSE];
	[self.displayNameButton setEnabled:FALSE];
	[self.destinationIpaPath setEnabled:FALSE];
	[self.destinationIpaPathButton setEnabled:FALSE];
	[self.defaultIconsButton setEnabled:FALSE];
	[self.iconButton setEnabled:FALSE];
	[self.retinaIconButton setEnabled:FALSE];
    
    [self.resetAllButton setEnabled:FALSE];
    [self.resignButton setEnabled:FALSE];
    [self.cleanConsoleButton setEnabled:FALSE];
}

- (void)enableControls
{
	[self.ipaField setEnabled:TRUE];
    [self.infoIpaFile setEnabled:TRUE];
	[self.provisioningComboBox setEnabled:TRUE];
	[self.infoProvisioning setEnabled:TRUE];
    [self.certificateComboBox setEnabled:TRUE];
    [self.infoCertificate setEnabled:TRUE];
    [self.bundleIDField setEnabled:TRUE];
    [self.bundleIDButton setEnabled:TRUE];
	[self.displayNameField setEnabled:TRUE];
	[self.displayNameButton setEnabled:TRUE];
	[self.destinationIpaPath setEnabled:TRUE];
	[self.destinationIpaPathButton setEnabled:TRUE];
	[self.defaultIconsButton setEnabled:TRUE];
	[self.iconButton setEnabled:TRUE];
	[self.retinaIconButton setEnabled:TRUE];
    
    [self.resetAllButton setEnabled:TRUE];
    [self.resignButton setEnabled:TRUE];
    [self.cleanConsoleButton setEnabled:TRUE];
}

#pragma mark - NSComboBox

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	NSInteger count = 0;
	
	if ([aComboBox isEqual:self.provisioningComboBox])
		count = [[[FileHandler sharedInstance] provisioningArray] count];
    
    else if ([aComboBox isEqual:self.certificateComboBox])
        count = [[[FileHandler sharedInstance] certificatesArray] count];
	
	return count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	id item = nil;
	
	if ([aComboBox isEqual:self.provisioningComboBox])
	{
		YAProvisioningProfile *profile = [[FileHandler sharedInstance] provisioningArray][index];
		item = profile.name;
	}
    
    else if ([aComboBox isEqual:self.certificateComboBox])
    {
        item = [[FileHandler sharedInstance] certificatesArray][index];
    }
	
	
	return item;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
	NSComboBox *comboBox = (NSComboBox *)[notification object];

	if ([comboBox isEqual:self.provisioningComboBox])
	{
		[self showProvisioningInfoAtIndex:self.provisioningComboBox.indexOfSelectedItem];
	}
    
    else if ([comboBox isEqual:self.certificateComboBox])
    {
        [self showCertificateInfoAtIndex:self.certificateComboBox.indexOfSelectedItem];
    }
}



@end
