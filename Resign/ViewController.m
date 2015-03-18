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

static NSString *kKeyPrefsBundleIDChange            = @"keyBundleIDChange";
static NSString *kKeyBundleIDPlistApp               = @"CFBundleIdentifier";
static NSString *kKeyBundleIDPlistiTunesArtwork     = @"softwareVersionBundleId";
static NSString *kKeyInfoPlistApplicationProperties = @"ApplicationProperties";
static NSString *kKeyInfoPlistApplicationPath       = @"ApplicationPath";
static NSString *kPayloadDirName                    = @"Payload";
static NSString *kProductsDirName                   = @"Products";
static NSString *kInfoPlistFilename                 = @"Info.plist";
static NSString *kiTunesMetadataFileName            = @"iTunesMetadata";

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
        [message appendFormat:@"Bundle display name: %@\n", infoPlistDict[@"CFBundleDisplayName"]];
        [message appendFormat:@"Bundle name: %@\n", infoPlistDict[@"CFBundleName"]];
        [message appendFormat:@"Bundle identifier: %@\n", infoPlistDict[@"CFBundleIdentifier"]];
        [message appendFormat:@"Bundle version: %@\n", infoPlistDict[@"CFBundleShortVersionString"]];
        [message appendFormat:@"Build version: %@\n", infoPlistDict[@"CFBundleVersion"]];
        [message appendFormat:@"Minimum OS version: %@\n", infoPlistDict[@"MinimumOSVersion"]];
        [self.statusField appendStringValue:message];
    }
    
    //Select the provisioning and signign-certificate of the app in the relative combobox
    NSString *provisioningPath = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
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
    
	NSArray *provisioningProfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/Library/MobileDevice/Provisioning Profiles", NSHomeDirectory()] error:nil];
	provisioningProfiles = [provisioningProfiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mobileprovision'"]];
	
	[provisioningProfiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *path = (NSString*)obj;
		if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Library/MobileDevice/Provisioning Profiles/%@", NSHomeDirectory(), path] isDirectory:NO])
		{
			YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:[NSString stringWithFormat:@"%@/Library/MobileDevice/Provisioning Profiles/%@", NSHomeDirectory(), path]];
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
