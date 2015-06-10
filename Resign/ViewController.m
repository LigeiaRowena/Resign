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
#import "AppDelegate.h"

@interface ViewController ()
{
	BOOL isOriginalValues;
}
@end

@implementation ViewController


- (void)loadView
{
	[super loadView];
	
	// init flag about original values of the source ipa file
	isOriginalValues = YES;
	
	// added observers for NSTextField
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:self.bundleIDField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:self.displayNameField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:self.destinationIpaPath];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:self.shortVersionField];
    
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

- (void)controlTextDidChange:(NSNotification *)aNotification
{
}

#pragma mark - ZIP/IPA Methods

- (void)unzipIpa
{
	isOriginalValues = YES;
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
        [self showIpaInfoWithPrint:YES];
    }];
}

- (void)showIpaInfoWithPrint:(BOOL)printInfo
{
    if (printInfo)
        [self.statusField appendStringValue:[NSString stringWithFormat:@"Retrieving %@", kInfoPlistFilename]];
    
    // Show the info of the ipa from the Info.plist file
    [[FileHandler sharedInstance] showIpaInfoWithSuccess:^(id success) {
        if (printInfo)
            [self.statusField appendStringValue:[NSString stringWithFormat:@"%@\n---SOURCE IPA LOADED---", success]];

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
	
	//Show the short version of the app in the relative field
	[self resetShortVersion];
	
	//Show the build version of the app in the relative field
	[self resetBuildVersion];
	
	//Show the default icons of the app in the relative fields
	[self resetDefaultIconsWithPrint:printInfo];
}

- (void)useDefaultSettingsWithPrint:(BOOL)printInfo
{
    // Reset all the values about the IPA source file
    [self showIpaInfoWithPrint:printInfo];
}

#pragma mark - Signign Certificate Methods

- (void)showCertificateInfoAtIndex:(NSInteger)index
{
    if ([[[FileHandler sharedInstance] certificatesArray] count] > 0 && index >= 0)
    {
		[[FileHandler sharedInstance] setCertificateIndex:(int)index];
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
        [self.statusField appendStringValue:@"---READY---"];
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
	[[FileHandler sharedInstance] setProvisioningIndex:(int)index];
	if (index != [[FileHandler sharedInstance] provisioningIndex])
		[[FileHandler sharedInstance] setEditProvisioning:YES];
	
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
	NSString *desktopFolderPath = [FileHandler getDesktopFolderPath];

	[self.destinationIpaPathButton setState:NSOnState];
	[self.destinationIpaPath setEditable:NO];
	[self.destinationIpaPath setSelectable:YES];
	[self.destinationIpaPath setStringValue:desktopFolderPath];
	[FileHandler sharedInstance].destinationPath = desktopFolderPath;
}


#pragma mark - Icons Methods

- (void)resetDefaultIconsWithPrint:(BOOL)printInfo
{
	// Succeed to find the default icon files
	if ([self getDefaultIconFilesWithPrint:printInfo])
	{
        [self.defaultIconsButton setState:NSOnState];
        [self.iconButton setTappable:NO];
        [self.retinaIconButton setTappable:NO];
	}
}

- (BOOL)getDefaultIconFilesWithPrint:(BOOL)printInfo
{
    __block BOOL success = FALSE;
    
    // Succeed to find icons in the Info.plist
    [[FileHandler sharedInstance] getDefaultIconFilesWithSuccess:^(id icons) {
        self.iconButton.fileName = icons[kIconNormal];
		NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:icons[kIconNormal]];
        [self.iconButton setImage:iconImage];
        if (printInfo)
            [self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 76x76 pixels is: %@", self.iconButton.fileName]];
		
		self.retinaIconButton.fileName = icons[kIconRetina];
		NSImage *retinaIconImage = [[NSImage alloc] initWithContentsOfFile:icons[kIconRetina]];
        [self.retinaIconButton setImage:retinaIconImage];
        if (printInfo)
            [self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 152 pixels is: %@", self.retinaIconButton.fileName]];
        success = TRUE;
        
    // Failed to find the Info.plist or the icons
    } error:^(NSString *error) {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
        [self.defaultIconsButton setState:NSOffState];
        [self.iconButton setEnabled:YES];
        [self.retinaIconButton setEnabled:YES];
        [self.iconButton setTappable:YES];
        [self.retinaIconButton setTappable:YES];
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
			
			if ([iconSize isEqualToNumber:@76])
				[[FileHandler sharedInstance] setIconPath:path];
			else if ([iconSize isEqualToNumber:@152])
				[[FileHandler sharedInstance] setIconRetinaPath:path];
			[[FileHandler sharedInstance] setEditIcons:YES];
		}
		else
		{
			[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:[NSString stringWithFormat:@"You have to select an icon file of size %@x%@ pixels", iconSize, iconSize]];
		}
	}
}

#pragma mark - Short Version Methods

- (void)resetShortVersion
{
	// Succeed to find the Info.plist
	[[FileHandler sharedInstance] getDefaultShortVersionWithSuccess:^(id bundleID) {
		[self.defaultShortVersionButton setState:NSOnState];
		[self.shortVersionField setEditable:NO];
		[self.shortVersionField setSelectable:YES];
		[self.shortVersionField setStringValue:bundleID];
		
	// Failed to find the Info.plist
	} error:^(NSString *error) {
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
		[self.defaultShortVersionButton setState:NSOffState];
		[self.shortVersionField setEditable:YES];
		[self.shortVersionField setSelectable:YES];
	}];
}

#pragma mark - Build Version Methods

- (void)resetBuildVersion
{
	// Succeed to find the Info.plist
	[[FileHandler sharedInstance] getDefaultBuildVersionWithSuccess:^(id bundleID) {
		[self.defaultBuildVersionButton setState:NSOnState];
		[self.buildVersionField setEditable:NO];
		[self.buildVersionField setSelectable:YES];
		[self.buildVersionField setStringValue:bundleID];
		
		// Failed to find the Info.plist
	} error:^(NSString *error) {
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
		[self.defaultBuildVersionButton setState:NSOffState];
		[self.buildVersionField setEditable:YES];
		[self.buildVersionField setSelectable:YES];
	}];
}

#pragma mark - Actions

- (IBAction)browseIpa:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

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
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

	[self showProvisioningInfoAtIndex:self.provisioningComboBox.indexOfSelectedItem];
}

- (IBAction)showIpaInfo:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

	[self showIpaInfoWithPrint:YES];
}

- (IBAction)useDefaultSettings:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

    // Reset all the values about the IPA source file printing info in the console about it
	if (isOriginalValues)
	{
		[self useDefaultSettingsWithPrint:YES];
	}
	else
	{
		[self unzipIpa];
	}
}

- (IBAction)resign:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];
	
	isOriginalValues = NO;
    [self disableControls];

    // Delete the _CodeSignature directory
    if (![[FileHandler sharedInstance] removeCodeSignatureDirectory])
    {
        [self enableControls];
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:@"You didn't select any IPA file, or the IPA file you selected is corrupted: unable to delete the _CodeSignature directory in order to resign the IPA"];
        [self.statusField appendStringValue:@"Unable to delete the _CodeSignature directory in order to resign the IPA: please try again"];
        [self resetAll:nil];
        return;
    }
	
	// Resign
	[[FileHandler sharedInstance] resignWithBundleId:self.bundleIDField.stringValue displayName:self.displayNameField.stringValue shortVersion:self.shortVersionField.stringValue buildVersion:self.buildVersionField.stringValue log:^(NSString *log) {
		[self.statusField appendStringValue:log];
		
	} error:^(NSString *error) {
		[self enableControls];
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:error];
		[self.statusField appendStringValue:error];
        [self resetAll:nil];
		return;
		
	} success:^(id message) {
		[self enableControls];
		[self.statusField appendStringValue:message];
        [self.statusField appendStringValue:@"---RESIGN DONE---"];

		// Reset the default settings of the source IPA
        [self useDefaultSettingsWithPrint:NO];
	}];
}

- (IBAction)cleanConsole:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

    [self.statusField setStringValue:@""];
}

- (IBAction)showCertificateInfo:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

    [self showCertificateInfoAtIndex:self.certificateComboBox.indexOfSelectedItem];
}

- (IBAction)defaultBundleIDButton:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

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
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

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
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

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

- (IBAction)changeShortVersion:(id)sender
{
	[self.statusField appendStringValue:[NSString stringWithFormat:@"You typed the IPA short version: %@", self.shortVersionField.stringValue]];
}

- (IBAction)defaultShortVersion:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];
	
	// reset default Short Version
	if (self.defaultShortVersionButton.state == NSOnState)
	{
		[self resetShortVersion];
	}
	
	// customized default Short Version
	else if (self.defaultShortVersionButton.state == NSOffState)
	{
		[self.shortVersionField setEditable:YES];
		[self.shortVersionField setSelectable:YES];
	}
}

- (IBAction)changeBuildVersion:(id)sender
{
	[self.statusField appendStringValue:[NSString stringWithFormat:@"You typed the IPA build version: %@", self.buildVersionField.stringValue]];
}

- (IBAction)defaultBuildVersion:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];
	
	// reset default Build Version
	if (self.defaultBuildVersionButton.state == NSOnState)
	{
		[self resetBuildVersion];
	}
	
	// customized default Short Version
	else if (self.defaultBuildVersionButton.state == NSOffState)
	{
		[self.buildVersionField setEditable:YES];
		[self.buildVersionField setSelectable:YES];
	}
}

- (IBAction)defaultIcons:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

	// reset default icons
	if (self.defaultIconsButton.state == NSOnState)
	{
		[self resetDefaultIconsWithPrint:YES];
	}
	
	// customized icons
	else if (self.defaultIconsButton.state == NSOffState)
	{
		[self.iconButton setTappable:YES];
		[self.retinaIconButton setTappable:YES];
	}
}

- (IBAction)changeIcon:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

    IconButton *butt = (IconButton*)sender;
    
    if (butt.tappable)
        [self openNewIconFile:@76 button:sender];
}

- (IBAction)changeRetinaIcon:(id)sender
{
	// resign as first responder the other controls
	AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
	[appDelegate.window makeFirstResponder: nil];

    IconButton *butt = (IconButton*)sender;
    
    if (butt.tappable)
        [self openNewIconFile:@152 button:sender];
}

- (IBAction)resetAll:(id)sender
{
    // resign as first responder the other controls
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    [appDelegate.window makeFirstResponder: nil];
    
    [self clearAll];
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
	[self.shortVersionField setEnabled:FALSE];
	[self.defaultShortVersionButton setEnabled:FALSE];
	[self.buildVersionField setEnabled:FALSE];
	[self.defaultBuildVersionButton setEnabled:FALSE];
	[self.defaultIconsButton setEnabled:FALSE];
	[self.iconButton setEnabled:FALSE];
	[self.retinaIconButton setEnabled:FALSE];
    
    [self.defaultSettingsButton setEnabled:FALSE];
    [self.resignButton setEnabled:FALSE];
    [self.resetAllButton setEnabled:FALSE];
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
	[self.shortVersionField setEnabled:TRUE];
	[self.defaultShortVersionButton setEnabled:TRUE];
	[self.buildVersionField setEnabled:TRUE];
	[self.defaultBuildVersionButton setEnabled:TRUE];
	[self.defaultIconsButton setEnabled:TRUE];
	[self.iconButton setEnabled:TRUE];
	[self.retinaIconButton setEnabled:TRUE];
    
    [self.defaultSettingsButton setEnabled:TRUE];
    [self.resignButton setEnabled:TRUE];
    [self.resetAllButton setEnabled:TRUE];
    [self.cleanConsoleButton setEnabled:TRUE];
}

- (void)clearAll
{
	// clear all the UI
    [self.statusField setStringValue:@"---RESET ALL---"];
	[self.ipaField setStringValue:@""];
	[self.provisioningComboBox setStringValue:@""];
	[self.certificateComboBox setStringValue:@""];
	[self.bundleIDField setStringValue:@""];
	[self.bundleIDButton setState:NSOffState];
	[self.displayNameField setStringValue:@""];
	[self.displayNameButton setState:NSOffState];
	[self resetDestinationIpaPath];
	[self.shortVersionField setStringValue:@""];
	[self.defaultShortVersionButton setState:NSOffState];
	[self.buildVersionField setStringValue:@""];
	[self.defaultBuildVersionButton setState:NSOffState];
	[self.iconButton setFileName:@""];
	[self.iconButton setTappable:YES];
    [self.iconButton setImage:[NSImage imageNamed:@"Icon"]];
	[self.retinaIconButton setFileName:@""];
	[self.retinaIconButton setTappable:YES];
    [self.retinaIconButton setImage:[NSImage imageNamed:@"Icon-iPadRetina"]];

	// clear all the FileHandler properties
	[[FileHandler sharedInstance] clearAll];
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
