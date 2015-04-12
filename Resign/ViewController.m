//
//  ViewController.m
//  Resign
//
//  Created by Francesca Corsini on 17/03/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import "ViewController.h"
#import "YAProvisioningProfile.h"
#import "NSScrollView+MultiLine.h"

static NSString *kKeyBundleIDChange = @"keyBundleIDChange";
static NSString *kCFBundleIdentifier = @"CFBundleIdentifier";
static NSString *kCFBundleDisplayName = @"CFBundleDisplayName";
static NSString *kCFBundleName = @"CFBundleName";
static NSString *kCFBundleShortVersionString = @"CFBundleShortVersionString";
static NSString *kCFBundleVersion = @"CFBundleVersion";
static NSString *kCFBundleIcons = @"CFBundleIcons";
static NSString *kCFBundlePrimaryIcon = @"CFBundlePrimaryIcon";
static NSString *kCFBundleIconFiles = @"CFBundleIconFiles";
static NSString *kCFBundleIconsipad = @"CFBundleIcons~ipad";



static NSString *kMinimumOSVersion = @"MinimumOSVersion";
static NSString *kSoftwareVersionBundleId = @"softwareVersionBundleId";
static NSString *kApplicationProperties = @"ApplicationProperties";
static NSString *kApplicationPath = @"ApplicationPath";
static NSString *kPayloadDirName = @"Payload";
static NSString *kProductsDirName = @"Products";
static NSString *kInfoPlistFilename = @"Info.plist";
static NSString *kMobileprovisionDirName = @"Library/MobileDevice/Provisioning Profiles";
static NSString *kMobileprovisionFilename = @"embedded.mobileprovision";
static NSString *kiTunesMetadataFileName = @"iTunesMetadata";

@interface ViewController ()
@end

@implementation ViewController


- (void)loadView
{
	[super loadView];
	
	// Init
	formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"dd-MM-yyyy";
	provisioningArray = @[].mutableCopy;
    certificatesArray = @[].mutableCopy;

	
	// Search for zip utilities
	[self searchForZipUtility];
	
	// Search for Provisioning Profiles
	[self getProvisioning];
    
    // Search for Signign Certificates
    [self getCertificates];
	
	// Show the default destination ipa path
	[self resetDestinationIpaPath];
}

#pragma mark - ZIP Methods

- (void)searchForZipUtility
{
	// Look for zip utility
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"]) {
		[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the zip utility present at /usr/bin/zip"];
		exit(0);
	}
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"]) {
		[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the unzip utility present at /usr/bin/unzip"];
		exit(0);
	}
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"]) {
		[self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the codesign utility present at /usr/bin/codesign"];
		exit(0);
	}
}

- (void)unzipIpa
{
    [self disableControls];
    
    sourcePath = [self.ipaField stringValue];
    
    // The user choosed a valid IPA file
    if ([[[sourcePath pathExtension] lowercaseString] isEqualToString:@"ipa"])
    {
        // Creation of the temp working directory (deleting the old one)
        workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"resign"];
        [self.statusField appendStringValue:[NSString stringWithFormat:@"Setting up working directory in %@",workingPath]];
        [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:workingPath withIntermediateDirectories:TRUE attributes:nil error:nil];
        
        // Create the unzip task: unzip the IPA file in the temp working directory
        [self.statusField appendStringValue:[NSString stringWithFormat:@"Unzipping ipa file in %@", workingPath]];
        unzipTask = [[NSTask alloc] init];
        [unzipTask setLaunchPath:@"/usr/bin/unzip"];
        [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", sourcePath, @"-d", workingPath, nil]];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
        [unzipTask launch];
    }
    
    // The user didn't choose a valid IPA file
    else
    {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"You must choose a valid *.ipa file"];
        [self enableControls];
        [self.statusField appendStringValue:@"Please try again"];
    }
}

- (void)checkUnzip:(NSTimer *)timer
{
    // Check if the unzip task finished: if yes invalidate the timer and do some operations
    if ([unzipTask isRunning] == 0)
    {
        [timer invalidate];
        int terminationStatus = unzipTask.terminationStatus;
        unzipTask = nil;
        
        // The unzip task succeed
        if (terminationStatus == 0 && [[NSFileManager defaultManager] fileExistsAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName]])
        {
            [self setAppPath];
            [self enableControls];
            [self.statusField appendStringValue:[NSString stringWithFormat:@"Succeed to unzip ipa file in %@", [workingPath stringByAppendingPathComponent:kPayloadDirName]]];
            [self showIpaInfo];
        }
        
        // The unzip task failed
        else
        {
            [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Unzip failed"];
            [self enableControls];
            [self.statusField appendStringValue:@"Unzip failed. Please try again"];
        }
    }
}

- (void)setAppPath
{
    NSString *payloadPath = [workingPath stringByAppendingPathComponent:kPayloadDirName];
    NSArray *payloadContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:payloadPath error:nil];
    
    [payloadContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *file = (NSString*)obj;
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"])
        {
            appPath = [[workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            *stop = YES;
        }
    }];
}

- (void)showIpaInfo
{
    // Show the info of the ipa from the Info.plist file
    [self.statusField appendStringValue:[NSString stringWithFormat:@"Retrieving %@", kInfoPlistFilename]];
    NSMutableString *message = @"".mutableCopy;
    NSString* infoPlistPath = [appPath stringByAppendingPathComponent:kInfoPlistFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
    {
        NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        [message appendFormat:@"Bundle display name: %@\n", infoPlistDict[kCFBundleDisplayName]];
        [message appendFormat:@"Bundle name: %@\n", infoPlistDict[kCFBundleName]];
        [message appendFormat:@"Bundle identifier: %@\n", infoPlistDict[kCFBundleIdentifier]];
        [message appendFormat:@"Bundle version: %@\n", infoPlistDict[kCFBundleShortVersionString]];
        [message appendFormat:@"Build version: %@\n", infoPlistDict[kCFBundleVersion]];
        [message appendFormat:@"Minimum OS version: %@\n", infoPlistDict[kMinimumOSVersion]];
        [self.statusField appendStringValue:message];
    }
    
    //Select the provisioning and signign-certificate of the app in the relative combobox
    NSString *provisioningPath = [appPath stringByAppendingPathComponent:kMobileprovisionFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
    {
        YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:provisioningPath];
        NSInteger indexProvisioning = [self getProvisioningIndexFromApp:profile];
        if (indexProvisioning >= 0)
            [self.provisioningComboBox selectItemAtIndex:indexProvisioning];
        else
        {
            NSMutableString *message = @"".mutableCopy;
            [message appendFormat:@"Profile name: %@\n", profile.name];
            [message appendFormat:@"Bundle identifier: %@\n", profile.bundleIdentifier];
            [message appendFormat:@"Expiration Date: %@\n", profile.expirationDate ? [formatter stringFromDate:profile.expirationDate] : @"Unknown"];
            [message appendFormat:@"Team Name: %@\n", profile.teamName ? profile.teamName : @""];
            [message appendFormat:@"App ID Name: %@\n", profile.appIdName];
            [message appendFormat:@"Team Identifier: %@\n", profile.teamIdentifier];
            [self showAlertOfKind:NSInformationalAlertStyle WithTitle:@"The Provisioning of the app isn't in your local list:" AndMessage:message];
        }
        
        NSString *teamName = profile.teamName;
        NSInteger indexCert = [self getCertificateIndexFromApp:teamName];
        if (indexCert >= 0)
            [self.certificateComboBox selectItemAtIndex:indexCert];
        else
        {
            [self showAlertOfKind:NSInformationalAlertStyle WithTitle:@"The Signign Certificate  of the app isn't in your keychain:" AndMessage:teamName];
        }
    }
    
    //Show the Bundle ID of the app in the relative field
    [self resetDefaultBundleID];
	
	//Show the Product Name of the app in the relative field
	[self resetDefaultProductName];
}

#pragma mark - Signign Certificate Methods

- (void)showCertificateInfoAtIndex:(NSInteger)index
{
    if ([certificatesArray count] > 0 && index >= 0)
    {
        NSString *certificate = certificatesArray[index];
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
    
    certTask = [[NSTask alloc] init];
    [certTask setLaunchPath:@"/usr/bin/security"];
    [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCerts:) userInfo:nil repeats:TRUE];
    NSPipe *pipe = [NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    [certTask launch];
    [NSThread detachNewThreadSelector:@selector(watchGetCerts:) toTarget:self withObject:handle];
}

- (void)checkCerts:(NSTimer *)timer
{
    // Check if the cert task finished: if yes invalidate the timer and do some operations
    if ([certTask isRunning] == 0)
    {
        [timer invalidate];
        certTask = nil;
        
        // The task found some cert identities
        if ([certificatesArray count] > 0)
        {
            [self.statusField appendStringValue:@"Signing Certificate IDs extracted"];
            [self enableControls];
            [self.certificateComboBox reloadData];
        }
        // The task didn't find any cert identities
        else
        {
            [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"There aren't Signign Certificates"];
            [self enableControls];
            [self.statusField appendStringValue:@"There aren't Signign Certificates"];
        }
    }
}

- (void)watchGetCerts:(NSFileHandle*)streamHandle
{
    // Check if there are Identities Cert in KeyChain and saves them in certComboBoxItems to show in certComboBox
    @autoreleasepool
    {
        NSString *securityResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        if (securityResult == nil || securityResult.length < 1)
            return;
        NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
        NSMutableArray *tempGetCertsResult = [NSMutableArray arrayWithCapacity:20];
        for (int i = 0; i <= [rawResult count] - 2; i+=2)
        {
            NSLog(@"i:%d", i+1);
            if (rawResult.count - 1 < i + 1) {
                // Invalid array, don't add an object to that position
            } else {
                // Valid object
                [tempGetCertsResult addObject:[rawResult objectAtIndex:i+1]];
            }
        }
        certificatesArray = [NSMutableArray arrayWithArray:tempGetCertsResult];
    }
}

- (NSInteger)getCertificateIndexFromApp:(NSString*)cert
{
    __block NSInteger index = -1;
    [certificatesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *c = (NSString*)obj;
        NSRange range = [c rangeOfString:cert];
        if (range.location != NSNotFound)
        {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}


#pragma mark - Provisioning Methods

- (void)getProvisioning
{
    [self disableControls];
    [self.statusField appendStringValue:@"Getting Provisoning Profiles..."];
    
	NSArray *provisioningProfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), kMobileprovisionDirName] error:nil];
	provisioningProfiles = [provisioningProfiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mobileprovision'"]];
	
	[provisioningProfiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *path = (NSString*)obj;
		if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), kMobileprovisionDirName, path] isDirectory:NO])
		{
			YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:[NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), kMobileprovisionDirName, path]];
			[provisioningArray addObject:profile];
		}
	}];
	
	provisioningArray = [[provisioningArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [((YAProvisioningProfile *)obj1).name compare:((YAProvisioningProfile *)obj2).name];
	}] mutableCopy];
	
	if ([provisioningArray count] > 0)
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
	if ([provisioningArray count] > 0 && index >= 0)
	{
		YAProvisioningProfile *profile = provisioningArray[index];
		NSMutableString *message = @"".mutableCopy;
		[message appendFormat:@"Profile name: %@\n", profile.name];
		[message appendFormat:@"Bundle identifier: %@\n", profile.bundleIdentifier];
		[message appendFormat:@"Expiration Date: %@\n", profile.expirationDate ? [formatter stringFromDate:profile.expirationDate] : @"Unknown"];
		[message appendFormat:@"Team Name: %@\n", profile.teamName ? profile.teamName : @""];
		[message appendFormat:@"App ID Name: %@\n", profile.appIdName];
		[message appendFormat:@"Team Identifier: %@\n", profile.teamIdentifier];
        [self.statusField appendStringValue:message];
	}
	else
	{
        [self.statusField appendStringValue:@"No Provisioning profile selected"];
	}
}

- (NSInteger)getProvisioningIndexFromApp:(YAProvisioningProfile*)profile
{
    __block NSInteger index = -1;
    [provisioningArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        YAProvisioningProfile *p = (YAProvisioningProfile*)obj;
        if ([p.name isEqualToString:profile.name] && [p.bundleIdentifier isEqualToString:profile.bundleIdentifier] && [p.creationDate isEqualToDate:profile.creationDate] && [p.teamName isEqualToString:profile.teamName] && [p.appIdName isEqualToString:profile.appIdName] && [p.teamIdentifier isEqualToString:profile.teamIdentifier])
        {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}


#pragma mark - Bundle ID Methods

- (void)resetDefaultBundleID
{
    NSString* infoPlistPath = [appPath stringByAppendingPathComponent:kInfoPlistFilename];
    
    // Succeed to find the Info.plist
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
    {
        NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        NSString *bundleID = infoPlistDict[kCFBundleIdentifier];
        [self.bundleIDButton setState:NSOnState];
        [self.bundleIDField setEditable:NO];
        [self.bundleIDField setSelectable:YES];
        [self.bundleIDField setStringValue:bundleID];
    }
    
    // Failed to find the Info.plist
    else
    {
        [self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:@"You didn't select any IPA file, or the IPA file you selected is corrupted."];
        [self.bundleIDButton setState:NSOffState];
        [self.bundleIDField setEditable:YES];
        [self.bundleIDField setSelectable:YES];
    }
}

#pragma mark - Product Name Methods

- (void)resetDefaultProductName
{
	NSString* infoPlistPath = [appPath stringByAppendingPathComponent:kInfoPlistFilename];
	
	// Succeed to find the Info.plist
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
	{
		NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
		NSString *displayName = infoPlistDict[kCFBundleDisplayName];
		[self.displayNameButton setState:NSOnState];
		[self.displayNameField setEditable:NO];
		[self.displayNameField setSelectable:YES];
		[self.displayNameField setStringValue:displayName];
	}
	
	// Failed to find the Info.plist
	else
	{
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:@"You didn't select any IPA file, or the IPA file you selected is corrupted."];
		[self.displayNameButton setState:NSOffState];
		[self.displayNameField setEditable:YES];
		[self.displayNameField setSelectable:YES];
	}
}

#pragma mark - Destination IPA Path Methods

- (void)resetDestinationIpaPath
{
	NSString *documentFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

	[self.destinationIpaPathButton setState:NSOnState];
	[self.destinationIpaPath setEditable:NO];
	[self.destinationIpaPath setSelectable:YES];
	[self.destinationIpaPath setStringValue:documentFolderPath];
	destinationPath = documentFolderPath;
}


#pragma mark - Icons Methods

- (void)resetDefaultIcons
{
	[self.iconButton setEnabled:NO];
	[self.retinaIconButton setEnabled:NO];

	// Succeed to find the default icon files
	AppIconSuccess success = [self getDefaultIconFiles];
	if (success == RetinaAppIconFounded)
	{
		[self.defaultIconsButton setState:NSOnState];
		[self.iconButton setEnabled:YES];
		[self.retinaIconButton setEnabled:YES];
	}
	// Failed to find the default product name
	else
	{
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:@"You didn't select any IPA file, or the IPA file you selected is corrupted."];
		[self.defaultIconsButton setState:NSOffState];
		[self.iconButton setEnabled:NO];
		[self.retinaIconButton setEnabled:NO];
	}
}

- (AppIconSuccess)getDefaultIconFiles
{
	AppIconSuccess success = NoSuccess;
	NSString* infoPlistPath = [appPath stringByAppendingPathComponent:kInfoPlistFilename];
	
	// Succeed to find the Info.plist
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
	{
		NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
		NSArray *icons = infoPlistDict[kCFBundleIcons][kCFBundlePrimaryIcon][kCFBundleIconFiles];
		NSArray *iconsAssets = infoPlistDict[kCFBundleIconsipad][kCFBundlePrimaryIcon][kCFBundleIconFiles];
		
		// array of bundle icons founded in the plist file
		if (icons != nil && [icons count] > 0)
		{
			for (NSString *fileName in icons)
			{
				NSRange range = [fileName rangeOfString:@".png"options:NSCaseInsensitiveSearch];
				if (range.location != NSNotFound)
				{
					NSString *iconName = [appPath stringByAppendingPathComponent:fileName];
					NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:iconName];
					if (NSEqualSizes(iconImage.size, CGSizeMake(76, 76)) && iconImage != nil)
					{
						self.iconButton.fileName = iconName;
						[self.iconButton setImage:iconImage];
						[self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 76x76 pixels is: %@", iconName]];
						success = success+1;
					}
					else if (NSEqualSizes(iconImage.size, CGSizeMake(152, 152)) && iconImage != nil)
					{
						self.retinaIconButton.fileName = iconName;
						[self.retinaIconButton setImage:iconImage];
						[self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 152 pixels is: %@", iconName]];
						success = success+1;
					}
				}
			}
		}
		
		// array of assets icons founded in the plist file
		else if (iconsAssets != nil && [iconsAssets count] > 0)
		{
			NSString *appIcon = iconsAssets[0];//AppIcon76x76
			NSString *iconName = [[appPath stringByAppendingPathComponent:appIcon] stringByAppendingString:@"~ipad.png"];
			NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:iconName];
			NSString *retinaIconName = [[appPath stringByAppendingPathComponent:appIcon] stringByAppendingString:@"@2x~ipad.png"];
			NSImage *retinaIconImage = [[NSImage alloc] initWithContentsOfFile:retinaIconName];
			if (iconImage != nil)
			{
				self.iconButton.fileName = iconName;
				[self.iconButton setImage:iconImage];
				[self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 76x76 pixels is: %@", iconName]];
				success = success+1;
			}
			if (retinaIconImage != nil)
			{
				self.retinaIconButton.fileName = retinaIconName;
				[self.retinaIconButton setImage:retinaIconImage];
				[self.statusField appendStringValue:[NSString stringWithFormat:@"The default icon file of 152 pixels is: %@", retinaIconName]];
				success = success+1;
			}
		}
	}
	
	// Failed to find the Info.plist
	else
	{
		[self showAlertOfKind:NSWarningAlertStyle WithTitle:@"Warning" AndMessage:@"You didn't select any IPA file, or the IPA file you selected is corrupted."];
		[self.defaultIconsButton setState:NSOffState];
		[self.iconButton setEnabled:YES];
		[self.retinaIconButton setEnabled:YES];
		success = NoSuccess;
	}
	
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
	destinationPath = self.destinationIpaPath.stringValue;
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
	[self openNewIconFile:@76 button:sender];
}

- (IBAction)changeRetinaIcon:(id)sender
{
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
		count = [provisioningArray count];
    
    else if ([aComboBox isEqual:self.certificateComboBox])
        count = [certificatesArray count];
	
	return count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	id item = nil;
	
	if ([aComboBox isEqual:self.provisioningComboBox])
	{
		YAProvisioningProfile *profile = provisioningArray[index];
		item = profile.name;
	}
    
    else if ([aComboBox isEqual:self.certificateComboBox])
    {
        item = certificatesArray[index];
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
