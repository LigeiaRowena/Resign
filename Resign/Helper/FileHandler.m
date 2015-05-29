//
//  FileHandler.m
//  Resign
//
//  Created by Francesca Corsini on 12/04/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import "FileHandler.h"
#import "YAProvisioningProfile.h"

@implementation FileHandler

#pragma mark - Init

static FileHandler *istance;

+ (instancetype)sharedInstance
{
	@synchronized(self)
	{
		if(istance == nil)
		{
			istance = [[FileHandler alloc] init];
			return istance;
		}
	}
	return istance;
}

- (id)init
{
	self = [super init];
	if (self) {
		self.provisioningArray = @[].mutableCopy;
		self.certificatesArray = @[].mutableCopy;
		iconsDictionary = @{}.mutableCopy;
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"dd-MM-yyyy";
        manager = [NSFileManager defaultManager];
        manager.delegate = self;
		self.originalProvisioningIndex = -1;
		iconsCounter = 0;
        self.workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"resign"];
	}
	return self;
}

#pragma mark - Utility

- (void)clearAll
{
    [self removeWorkingDirectory];
    
    successBlock = nil;
    errorBlock = nil;
    logBlock = nil;
    successResignBlock = nil;
    errorResignBlock = nil;
    logResignBlock = nil;
    
    entitlementsResult = nil;
    codesigningResult = nil;
    verificationResult = nil;
    iconsDictionary = nil;
    
    self.provisioningIndex = 0;
    self.editProvisioning = NO;
    self.editIcons = NO;
    self.iconPath = nil;
    self.iconRetinaPath = nil;
    self.bundleId = nil;
    self.displayName = nil;
    self.shortVersion = nil;
    self.buildVersion = nil;
    self.certificateIndex = 0;
    self.sourcePath = nil;
    self.appPath = nil;
}

+ (NSString*)getDocumentFolderPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString*)getDesktopFolderPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
}


- (BOOL)removeWorkingDirectory
{
    // Delete the temp working directory
    
    BOOL success = FALSE;
    if (self.workingPath != nil && [manager fileExistsAtPath:self.workingPath])
    {
        NSError *error = nil;
        success = [manager removeItemAtPath:self.workingPath error:&error];
    }
    
    return success;
}

- (BOOL)removeCodeSignatureDirectory
{
    // Delete the _CodeSignature directory
    
    BOOL success = NO;
    NSString* codeSignaturePath = [self.appPath stringByAppendingPathComponent:kCodeSignatureDirectory];

    if (codeSignaturePath != nil && [manager fileExistsAtPath:codeSignaturePath])
    {
        NSError *error = nil;
        success = [manager removeItemAtPath:codeSignaturePath error:&error];
    }
    else if (![manager fileExistsAtPath:codeSignaturePath])
        success = YES;
    
    return success;
}

+ (BOOL)isEmptyString:(NSString*)string
{
    BOOL isEmpty = NO;
    if (string == nil)
        isEmpty = YES;
    
    else if ([string isEqualTo:[NSNull null]])
        isEmpty = YES;
    
    else if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
        isEmpty = YES;
    
    return isEmpty;
}


#pragma mark - NSFileManagerDelegate

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtPath:(NSString *)path
{
    NSLog(@"fileManager:shouldProceedAfterError: %@ removingItemAtPath: %@", error, path);
    return YES;
}

#pragma mark - Bundle ID

- (void)getDefaultBundleIDWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
    successBlock = [success copy];
    errorBlock = [error copy];
    NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
    
    // Succeed to find the Info.plist
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
    {
        NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        NSString *bundleID = infoPlistDict[kCFBundleIdentifier];
        if (successBlock != nil)
            successBlock(bundleID);
    }
    
    // Failed to find the Info.plist
    else
    {
        if (errorBlock != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
    }
}

#pragma mark - Short Version

- (void)getDefaultShortVersionWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
	successBlock = [success copy];
	errorBlock = [error copy];
	NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
	
	// Succeed to find the Info.plist
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
	{
		NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
		NSString *shortVersion = infoPlistDict[kCFBundleShortVersionString];
		if (successBlock != nil)
			successBlock(shortVersion);
	}
	
	// Failed to find the Info.plist
	else
	{
		if (errorBlock != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
	}
}

#pragma mark - Build Version

- (void)getDefaultBuildVersionWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
	successBlock = [success copy];
	errorBlock = [error copy];
	NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
	
	// Succeed to find the Info.plist
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
	{
		NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
		NSString *buildVersion = infoPlistDict[kCFBundleVersion];
		if (successBlock != nil)
			successBlock(buildVersion);
	}
	
	// Failed to find the Info.plist
	else
	{
		if (errorBlock != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
	}
}

#pragma mark - Product Name

- (void)getDefaultProductNameWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
    successBlock = [success copy];
    errorBlock = [error copy];
    NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
    
    // Succeed to find the Info.plist
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
    {
        NSMutableDictionary* infoPlistDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistPath];
        NSString *displayName = infoPlistDict[kCFBundleDisplayName];
        // Edit the Info.plist file and rewrite
        if (displayName == nil)
        {
            NSString *name = infoPlistDict[kCFBundleName];
            [infoPlistDict setObject:name forKey:name];
            NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:infoPlistDict format:NSPropertyListXMLFormat_v1_0 options:kCFPropertyListImmutable error:nil];
            [xmlData writeToFile:infoPlistPath atomically:YES];
            displayName = name;
        }
        if (successBlock != nil)
            successBlock(displayName);
    }
    
    // Failed to find the Info.plist
    else
    {
        if (errorBlock != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
    }
}

#pragma mark - Icons 

- (void)getDefaultIconFilesWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
    successBlock = [success copy];
    errorBlock = [error copy];
	
    NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
    
    // Succeed to find the Info.plist
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
    {
        NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        NSArray *icons = infoPlistDict[kCFBundleIcons][kCFBundlePrimaryIcon][kCFBundleIconFiles];
        NSArray *iconsAssets = infoPlistDict[kCFBundleIconsipad][kCFBundlePrimaryIcon][kCFBundleIconFiles];
		iconsDictionary = [self getIconsDictionaryFromPlist:infoPlistDict icons:icons iconsAssets:iconsAssets].mutableCopy;
		
        if ([iconsDictionary count] == 2)
        {
			self.editIcons = NO;
            if (successBlock != nil)
                successBlock(iconsDictionary);
        }
        else
        {
            if (errorBlock != nil)
                errorBlock(@"There aren't valid icons in the IPA file");
        }
    }
    
    // Failed to find the Info.plist
    else
    {
        if (errorBlock != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
    }
}

- (NSDictionary*)getIconsDictionaryFromPlist:(NSDictionary*)infoPlistDict icons:(NSArray*)icons iconsAssets:(NSArray*)iconsAssets
{
	NSMutableDictionary *iconsMap = @{}.mutableCopy;
	
	// array of bundle icons founded in the plist file
	if (icons != nil && [icons count] > 0)
	{
		for (NSString *fileName in icons)
		{
			NSRange range = [fileName rangeOfString:@".png"options:NSCaseInsensitiveSearch];
			if (range.location != NSNotFound)
			{
				NSString *iconName = [self.appPath stringByAppendingPathComponent:fileName];
				NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:iconName];
				if (NSEqualSizes(iconImage.size, CGSizeMake(76, 76)) && iconImage != nil)
				{
					[iconsMap setObject:iconName forKey:kIconNormal];
				}
				else if (NSEqualSizes(iconImage.size, CGSizeMake(152, 152)) && iconImage != nil)
				{
					[iconsMap setObject:iconName forKey:kIconRetina];
				}
			}
		}
	}
	
	// array of assets icons founded in the plist file
	else if (iconsAssets != nil && [iconsAssets count] > 0)
	{
		NSString *appIcon = iconsAssets[0];//AppIcon76x76
		NSString *iconName = [[self.appPath stringByAppendingPathComponent:appIcon] stringByAppendingString:@"~ipad.png"];
		NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:iconName];
		NSString *retinaIconName = [[self.appPath stringByAppendingPathComponent:appIcon] stringByAppendingString:@"@2x~ipad.png"];
		NSImage *retinaIconImage = [[NSImage alloc] initWithContentsOfFile:retinaIconName];
		if (NSEqualSizes(iconImage.size, CGSizeMake(76, 76)) && iconImage != nil)
		{
			[iconsMap setObject:iconName forKey:kIconNormal];
		}
		if (NSEqualSizes(retinaIconImage.size, CGSizeMake(152, 152)) && retinaIconImage != nil)
		{
			[iconsMap setObject:retinaIconName forKey:kIconRetina];
		}
	}
	
	return iconsMap;
}

- (void)editIconsWithLog:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
	logBlock = [log copy];
	errorBlock = [error copy];
	successBlock = [success copy];
	
	if (!self.editIcons)
	{
		if (successBlock)
			successBlock(@"You selected the default Icons");
		return;
	}
	
	if (logBlock)
		logBlock(@"Editing the Icon files...");
	
	
	// Delete the old icon files
	NSLog(@"Found the old icon files, deleting them...");
	NSString *targetIconPath = iconsDictionary[kIconNormal];
	NSString *targetIconRetinaPath = iconsDictionary[kIconRetina];
	[[NSFileManager defaultManager] removeItemAtPath:targetIconPath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:targetIconRetinaPath  error:nil];
	
	
	// Create the icons task
	NSTask *iconTask = [[NSTask alloc] init];
	[iconTask setLaunchPath:@"/bin/cp"];
	[iconTask setArguments:@[@"-R", self.iconPath, targetIconPath]];
	[iconTask launch];
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkIcon:) userInfo:@{@"iconTask": iconTask} repeats:TRUE];

	NSTask *iconRetinaTask = [[NSTask alloc] init];
	[iconRetinaTask setLaunchPath:@"/bin/cp"];
	[iconRetinaTask setArguments:@[@"-R", self.iconRetinaPath, targetIconRetinaPath]];
	[iconRetinaTask launch];
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkRetinaIcon:) userInfo:@{@"iconRetinaTask": iconRetinaTask} repeats:TRUE];
}

- (void)checkRetinaIcon:(NSTimer *)timer
{
	// Check if the icon task finished: if yes invalidate the timer and do some operations
	NSTask *iconRetinaTask = timer.userInfo[@"iconRetinaTask"];
	if ([iconRetinaTask isRunning] == 0)
	{
		[timer invalidate];
		int terminationStatus = iconRetinaTask.terminationStatus;
		// The task succeed and the icon was successfully created
		if (terminationStatus == 0 && [[NSFileManager defaultManager] fileExistsAtPath:iconsDictionary[kIconRetina]])
		{
			iconRetinaTask = nil;
			iconsCounter++;
			[self checkIcons];
		}
		
		// The task failed
		else
		{
			iconRetinaTask = nil;
			if (errorBlock != nil)
				errorBlock(@"Icon retina editing failed. Please try again");
		}
	}
}

- (void)checkIcon:(NSTimer *)timer
{
	// Check if the icon task finished: if yes invalidate the timer and do some operations
	NSTask *iconTask = timer.userInfo[@"iconTask"];
	if ([iconTask isRunning] == 0)
	{
		[timer invalidate];
		int terminationStatus = iconTask.terminationStatus;
		// The task succeed and the icon was successfully created
		if (terminationStatus == 0 && [[NSFileManager defaultManager] fileExistsAtPath:iconsDictionary[kIconNormal]])
		{
			iconTask = nil;
			iconsCounter++;
			[self checkIcons];
		}

		// The task failed
		else
		{
			iconTask = nil;
			if (errorBlock != nil)
				errorBlock(@"Icon editing failed. Please try again");
		}
	}
}

- (void)checkIcons
{
	if (iconsCounter == 2)
	{
		if (successBlock)
			successBlock(@"Successfully editing the Icon files");
	}
}

#pragma mark - ZIP/UNZIP

- (BOOL)searchForZipUtility
{
	BOOL succes = TRUE;
	
	// Look for zip utility
	if (![manager fileExistsAtPath:@"/usr/bin/zip"])
        succes = FALSE;

	if (![manager fileExistsAtPath:@"/usr/bin/unzip"])
		succes = FALSE;
	
	if (![manager fileExistsAtPath:@"/usr/bin/codesign"])
		  succes = FALSE;
	
	return succes;
}

- (void)unzipIpaFromSource:(NSString*)ipaFileName log:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
    logBlock = [log copy];
    errorBlock = [error copy];
    successBlock = [success copy];
    self.sourcePath = ipaFileName;
    
    // The user choosed a valid IPA file
    if ([[[self.sourcePath pathExtension] lowercaseString] isEqualToString:@"ipa"])
    {
        // Creation of the temp working directory (deleting the old one)
        if (logBlock != nil)
            logBlock([NSString stringWithFormat:@"Setting up working directory in %@",self.workingPath]);
        [manager removeItemAtPath:self.workingPath error:nil];
        [manager createDirectoryAtPath:self.workingPath withIntermediateDirectories:TRUE attributes:nil error:nil];
        
        // Create the unzip task: unzip the IPA file in the temp working directory
        if (logBlock != nil)
            logBlock([NSString stringWithFormat:@"Unzipping ipa file in %@", self.workingPath]);
        NSTask *unzipTask = [[NSTask alloc] init];
        [unzipTask setLaunchPath:@"/usr/bin/unzip"];
        [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", self.sourcePath, @"-d", self.workingPath, nil]];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:@{@"task": unzipTask} repeats:TRUE];
        [unzipTask launch];
    }
    
    // The user didn't choose a valid IPA file
    else
    {
      if (errorBlock != nil)
          errorBlock(@"You must choose a valid *.ipa file");
    }
}

- (void)checkUnzip:(NSTimer *)timer
{
    // Check if the unzip task finished: if yes invalidate the timer and do some operations
    NSTask *unzipTask = timer.userInfo[@"task"];
    if ([unzipTask isRunning] == 0)
    {
        [timer invalidate];
        int terminationStatus = unzipTask.terminationStatus;
        unzipTask = nil;
        
        // The unzip task succeed
        if (terminationStatus == 0 && [manager fileExistsAtPath:[self.workingPath stringByAppendingPathComponent:kPayloadDirName]])
        {
            [self setAppPath];
            if (successBlock != nil)
                successBlock(nil);
        }
        
        // The unzip task failed
        else
        {
            if (errorBlock != nil)
                errorBlock(@"Unzip failed. Please try again");
        }
    }
}

- (void)zipIpaWithLog:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
	logBlock = [log copy];
	errorBlock = [error copy];
	successBlock = [success copy];
	
	if (![FileHandler isEmptyString:self.appPath] && ![FileHandler isEmptyString:self.destinationPath])
	{
        // Check if the destinationPath exists
        if (![manager fileExistsAtPath:self.destinationPath])
        {
            if (errorBlock)
                errorBlock(@"Unable to unzip the file: the destination path you digited does not exist");
            return;
        }

        
		// Path of the app file to create/resign
        NSString *zippedIpaPath = [[self.destinationPath stringByAppendingPathComponent:self.displayName] stringByAppendingPathExtension:@"ipa"];
		if (logBlock)
			logBlock([NSString stringWithFormat:@"Beginning the zip of the IPA file in the path: %@", zippedIpaPath]);

		// Create the zip task
		NSTask *zipTask = [[NSTask alloc] init];
		[zipTask setLaunchPath:@"/usr/bin/zip"];
		[zipTask setCurrentDirectoryPath:self.workingPath];
		[zipTask setArguments:@[@"-qry", zippedIpaPath, @"Payload/"]];
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:@{@"task": zipTask} repeats:TRUE];
		[zipTask launch];
	}
    else
    {
        if (errorBlock)
            errorBlock(@"Unable to unzip the file: the destination path is empty or the source IPA file was corrupted");
    }
}

- (void)checkZip:(NSTimer *)timer
{
	// Check if the zip task finished: if yes invalidate the timer and do some operations
	NSTask *zipTask = timer.userInfo[@"task"];
	if ([zipTask isRunning] == 0)
	{
		[timer invalidate];
		zipTask = nil;
		if (logBlock)
			logBlock([NSString stringWithFormat:@"Zipping done. IPA file saved in the path: %@", [[self.destinationPath stringByAppendingPathComponent:self.displayName] stringByAppendingPathExtension:@"ipa"]]);
        
		if (successBlock)
			successBlock([NSString stringWithFormat:@"Resign result: %@", [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult]]);
	}
}

#pragma mark - App Info

- (void)setAppPath
{
    NSString *payloadPath = [self.workingPath stringByAppendingPathComponent:kPayloadDirName];
    NSArray *payloadContents = [manager contentsOfDirectoryAtPath:payloadPath error:nil];
    
    [payloadContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *file = (NSString*)obj;
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"])
        {
            self.appPath = [[self.workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            *stop = YES;
        }
    }];
}

- (void)showIpaInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
    errorBlock = [error copy];
    successBlock = [success copy];
    
    // Show the info of the ipa from the Info.plist file
    NSMutableString *message = @"".mutableCopy;
    NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
    if ([manager fileExistsAtPath:infoPlistPath])
    {
        NSDictionary* infoPlistDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        [message appendFormat:@"Bundle display name: %@\n", infoPlistDict[kCFBundleDisplayName]];
        [message appendFormat:@"Bundle name: %@\n", infoPlistDict[kCFBundleName]];
        [message appendFormat:@"Bundle identifier: %@\n", infoPlistDict[kCFBundleIdentifier]];
        [message appendFormat:@"Bundle version: %@\n", infoPlistDict[kCFBundleShortVersionString]];
        [message appendFormat:@"Build version: %@\n", infoPlistDict[kCFBundleVersion]];
        [message appendFormat:@"Minimum OS version: %@\n", infoPlistDict[kMinimumOSVersion]];
        
        if (successBlock != nil)
            successBlock(message);
    }
    else
    {
        [self removeWorkingDirectory];
        if (errorBlock != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
        return;
    }
}

- (void)showProvisioningInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
    errorBlock = [error copy];
    successBlock = [success copy];
    
    //Show the provisioning infos
    NSString *provisioningPath = [self.appPath stringByAppendingPathComponent:kMobileprovisionFilename];
    NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
    if ([manager fileExistsAtPath:infoPlistPath])
    {
        YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:provisioningPath];
        NSInteger indexProvisioning = [self getProvisioningIndexFromApp:profile];
        if (indexProvisioning >= 0)
        {
			self.provisioningIndex = (int)indexProvisioning;
			self.originalProvisioningIndex = (int)indexProvisioning;
			self.editProvisioning = NO;
            if (successBlock != nil)
                successBlock([NSNumber numberWithInteger:indexProvisioning]);
        }
        else
        {
            NSMutableString *message = @"".mutableCopy;
            [message appendString:@"The Provisioning of the app isn't in your local list:\n"];
            [message appendFormat:@"Profile name: %@\n", profile.name];
            [message appendFormat:@"Bundle identifier: %@\n", profile.bundleIdentifier];
            [message appendFormat:@"Expiration Date: %@\n", profile.expirationDate ? [formatter stringFromDate:profile.expirationDate] : @"Unknown"];
            [message appendFormat:@"Team Name: %@\n", profile.teamName ? profile.teamName : @""];
            [message appendFormat:@"App ID Name: %@\n", profile.appIdName];
            [message appendFormat:@"Team Identifier: %@\n", profile.teamIdentifier];
            if (errorBlock  != nil)
                errorBlock(message);
        }
    }
    else
    {
        [self removeWorkingDirectory];
        if (errorBlock  != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
    }
}

- (void)showCertificatesInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
    errorBlock = [error copy];
    successBlock = [success copy];

    //Show the signign-certificate infos
    NSString *provisioningPath = [self.appPath stringByAppendingPathComponent:kMobileprovisionFilename];
    NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
    if ([manager fileExistsAtPath:infoPlistPath])
    {
        YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:provisioningPath];
        NSString *teamName = profile.teamName;
        NSInteger indexCert = [self getCertificateIndexFromApp:teamName];
        if (indexCert >= 0)
        {
			self.certificateIndex = (int)indexCert;
            if (successBlock != nil)
                successBlock([NSNumber numberWithInteger:indexCert]);
        }

        else
        {
            if (errorBlock  != nil)
                errorBlock([NSString stringWithFormat:@"The Signign Certificate  of the app isn't in your keychain: %@", teamName]);
        }
    }
    else
    {
        [self removeWorkingDirectory];
        if (errorBlock  != nil)
            errorBlock(@"You didn't select any IPA file, or the IPA file you selected is corrupted, or the Info.plist of the IPA file is corrupted.");
    }
}

#pragma mark - Provisioning Profiles

- (void)getProvisioningProfiles
{
    [self.provisioningArray removeAllObjects];
	self.editProvisioning = NO;
	
	NSArray *provisioningProfiles = [manager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), kMobileprovisionDirName] error:nil];
	provisioningProfiles = [provisioningProfiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mobileprovision'"]];
	
	[provisioningProfiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *path = (NSString*)obj;
		if ([manager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), kMobileprovisionDirName, path] isDirectory:NO])
		{
			YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:[NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), kMobileprovisionDirName, path]];
			if ([profile.debug isEqualToString:@"NO"])
				[self.provisioningArray addObject:profile];
		}
	}];
	
	self.provisioningArray = [[self.provisioningArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [((YAProvisioningProfile *)obj1).name compare:((YAProvisioningProfile *)obj2).name];
	}] mutableCopy];
}

- (NSInteger)getProvisioningIndexFromApp:(YAProvisioningProfile*)profile
{
    __block NSInteger index = -1;
    [self.provisioningArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        YAProvisioningProfile *p = (YAProvisioningProfile*)obj;
        if ([p.name isEqualToString:profile.name] && [p.bundleIdentifier isEqualToString:profile.bundleIdentifier] && [p.creationDate isEqualToDate:profile.creationDate] && [p.teamName isEqualToString:profile.teamName] && [p.appIdName isEqualToString:profile.appIdName] && [p.teamIdentifier isEqualToString:profile.teamIdentifier])
        {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}

- (NSString*)getProvisioningInfoAtIndex:(NSInteger)index
{
    if ([self.provisioningArray count] > 0 && index >= 0)
    {
        YAProvisioningProfile *profile = self.provisioningArray[index];
        NSMutableString *message = @"".mutableCopy;
        [message appendFormat:@"Profile name: %@\n", profile.name];
        [message appendFormat:@"Bundle identifier: %@\n", profile.bundleIdentifier];
        [message appendFormat:@"Expiration Date: %@\n", profile.expirationDate ? [formatter stringFromDate:profile.expirationDate] : @"Unknown"];
        [message appendFormat:@"Team Name: %@\n", profile.teamName ? profile.teamName : @""];
        [message appendFormat:@"App ID Name: %@\n", profile.appIdName];
        [message appendFormat:@"Team Identifier: %@\n", profile.teamIdentifier];
        return message;
    }
    else
    {
        return @"No Provisioning profile selected";
    }
}

- (void)editProvisioningWithLog:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
	logBlock = [log copy];
	errorBlock = [error copy];
	successBlock = [success copy];
	
	if (!self.editProvisioning)
	{
		if (successBlock)
			successBlock(@"You selected the default Provisioning Profile");
		return;
	}
	
	if (logBlock)
		logBlock(@"Editing the Provisioning Profile...");
	
	// Payload directory
	NSString *payloadPath = [self.workingPath stringByAppendingPathComponent:kPayloadDirName];
	NSArray *payloadContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:payloadPath error:nil];
	
	// Delete the embedded.mobileprovision file
	for (NSString *file in payloadContents)
	{
		if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"])
		{
			if ([[NSFileManager defaultManager] fileExistsAtPath:[self.appPath stringByAppendingPathComponent:kMobileprovisionFilename]])
			{
				NSLog(@"Found embedded.mobileprovision, deleting it...");
				[[NSFileManager defaultManager] removeItemAtPath:[self.appPath stringByAppendingPathComponent:kMobileprovisionFilename] error:nil];
			}
			break;
		}
	}
	
	// Create the provisioning task
	NSString *targetPath = [self.appPath stringByAppendingPathComponent:kMobileprovisionFilename];
	NSString *provisioningPath = [(YAProvisioningProfile*)self.provisioningArray[self.provisioningIndex] path];
	NSTask *provisioningTask = [[NSTask alloc] init];
	[provisioningTask setLaunchPath:@"/bin/cp"];
	[provisioningTask setArguments:[NSArray arrayWithObjects:provisioningPath, targetPath, nil]];
	[provisioningTask launch];
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:@{@"task": provisioningTask} repeats:TRUE];
}

- (void)checkProvisioning:(NSTimer *)timer
{
	// Check if the provisioning task finished: if yes invalidate the timer and do some operations
	NSTask *provisioningTask = timer.userInfo[@"task"];
	if ([provisioningTask isRunning] == 0)
	{
		int terminationStatus = provisioningTask.terminationStatus;
		[timer invalidate];
		provisioningTask = nil;
		// The task succeed
		if (terminationStatus == 0)
		{
			// Detect if the provisioning was successfully created
			BOOL success = NO;
			NSString *payloadPath = [self.workingPath stringByAppendingPathComponent:kPayloadDirName];
			NSArray *payloadContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:payloadPath error:nil];
			for (NSString *file in payloadContents)
			{
				if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"])
				{
					if ([[NSFileManager defaultManager] fileExistsAtPath:[self.appPath stringByAppendingPathComponent:kMobileprovisionFilename]])
						success = YES;
					break;
				}
			}
			
			if (success)
			{
				if (successBlock != nil)
					successBlock(@"Provisioning Profile edited successfully");
			}
			else
			{
				if (errorBlock != nil)
					errorBlock(@"Provisioning Profile editing failed. Please try again");
			}
		}
		// The task failed
		else
		{
			if (errorBlock != nil)
				errorBlock(@"Provisioning Profile editing failed. Please try again");
		}
	}
}

#pragma mark - Codesign

- (void)doCodesignWithLog:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
	logBlock = [log copy];
	errorBlock = [error copy];
	successBlock = [success copy];
	
	if (logBlock)
		logBlock(@"Beginning the codesign...");
	
	// Create the codesign task
	if (self.appPath)
	{
		NSString *currentCertificate = self.certificatesArray[self.certificateIndex];
		NSString* entitlementsPath = [self.workingPath stringByAppendingPathComponent:kEntitlementsPlistFilename];
		
		NSTask *codesignTask = [[NSTask alloc] init];
		[codesignTask setLaunchPath:@"/usr/bin/codesign"];
		[codesignTask setArguments:@[@"-f", @"-s", currentCertificate, self.appPath, [NSString stringWithFormat:@"--entitlements=%@", entitlementsPath]]];
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:@{@"task": codesignTask} repeats:TRUE];
		NSPipe *pipe = [NSPipe pipe];
		[codesignTask setStandardOutput:pipe];
		[codesignTask setStandardError:pipe];
		NSFileHandle *handle = [pipe fileHandleForReading];
		[codesignTask launch];
		[NSThread detachNewThreadSelector:@selector(watchCodesigning:)
								 toTarget:self withObject:handle];
	}
}

- (void)checkCodesigning:(NSTimer *)timer
{
	// Check if the code signing task finished: if yes invalidate the timer and do some operations
	NSTask *codesignTask = timer.userInfo[@"task"];
	if ([codesignTask isRunning] == 0)
	{
		[timer invalidate];
		codesignTask = nil;
		if (logBlock)
			logBlock(@"Codesigning done");
		[self verifySignature];
	}
}

- (void)watchCodesigning:(NSFileHandle*)streamHandle
{
	@autoreleasepool {
		// Set the codesigning result string
		codesigningResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
	}
}

- (void)verifySignature
{
	if (self.appPath)
	{
		if (logBlock)
			logBlock([NSString stringWithFormat:@"Verifying codesign: %@",self.appPath]);
		
		// Create the verify task in order to verify the codesign
		NSTask *verifyTask = [[NSTask alloc] init];
		[verifyTask setLaunchPath:@"/usr/bin/codesign"];
		[verifyTask setArguments:[NSArray arrayWithObjects:@"-v", self.appPath, nil]];
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:@{@"task": verifyTask} repeats:TRUE];
		NSPipe *pipe = [NSPipe pipe];
		[verifyTask setStandardOutput:pipe];
		[verifyTask setStandardError:pipe];
		NSFileHandle *handle = [pipe fileHandleForReading];
		[verifyTask launch];
		[NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
								 toTarget:self withObject:handle];
	}
}

- (void)watchVerificationProcess:(NSFileHandle*)streamHandle
{
	@autoreleasepool {
		// Set the verification result string
		verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
	}
}

- (void)checkVerificationProcess:(NSTimer *)timer
{
	// Check if the verify task finished: if yes invalidate the timer and do some operations
	NSTask *verifyTask = timer.userInfo[@"task"];
	if ([verifyTask isRunning] == 0)
	{
		[timer invalidate];
		verifyTask = nil;
		
		// Verification of codesign succeed
		if ([verificationResult length] == 0)
		{
			if (successBlock)
				successBlock(@"Verification Codesigning done");
		}
		
		// Verification of codesign failed
		else
		{
			NSString *error = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
			if (errorBlock)
				errorBlock([NSString stringWithFormat:@"Signing failed with error: %@", error]);
		}
	}
}

#pragma mark - Signign Certificate

- (void)getCertificatesSuccess:(SuccessBlock)success error:(ErrorBlock)error
{
	successBlock = [success copy];
	errorBlock = [error copy];
    [self.certificatesArray removeAllObjects];
	
	NSTask *certTask = [[NSTask alloc] init];
	[certTask setLaunchPath:@"/usr/bin/security"];
	[certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCerts:) userInfo:@{@"task": certTask} repeats:TRUE];
	NSPipe *pipe = [NSPipe pipe];
	[certTask setStandardOutput:pipe];
	[certTask setStandardError:pipe];
	NSFileHandle *handle = [pipe fileHandleForReading];
	[certTask launch];
	[NSThread detachNewThreadSelector:@selector(watchGetCerts:) toTarget:self withObject:handle];
}

- (void)checkCerts:(NSTimer *)timer
{
	// Check if the cert task finished: if yes invalidate the timer and do some operations
	NSTask *certTask = timer.userInfo[@"task"];
	if ([certTask isRunning] == 0)
	{
		[timer invalidate];
		certTask = nil;
		
		// The task found some cert identities
		if ([self.certificatesArray count] > 0)
		{
			if (successBlock != nil)
				successBlock(nil);
		}
		// The task didn't find any cert identities
		else
		{
            if (errorBlock != nil)
                errorBlock(@"There aren't Signign Certificates");
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
		self.certificatesArray = [NSMutableArray arrayWithArray:tempGetCertsResult];
	}
}

- (NSInteger)getCertificateIndexFromApp:(NSString*)cert
{
    __block NSInteger index = -1;
    [self.certificatesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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

#pragma mark - Resign

- (void)resignWithBundleId:(NSString*)bundleId displayName:(NSString*)displayName shortVersion:(NSString*)shortVersion buildVersion:(NSString*)buildVersion log:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
	logResignBlock = [log copy];
	errorResignBlock = [error copy];
	successResignBlock = [success copy];
	
	self.bundleId = bundleId;
	self.displayName = displayName;
	self.shortVersion = shortVersion;
	self.buildVersion = buildVersion;
	codesigningResult = nil;
	verificationResult = nil;
	
	// Create the entitlements file
	[self createEntitlementsWithLog:^(NSString *log) {
		if (logResignBlock)
			logResignBlock(log);
			
	} error:^(NSString *error) {
		if (errorResignBlock)
			errorResignBlock(error);
		
	} success:^(id message) {
		if (logResignBlock)
			logResignBlock(message);
		
		// Edit the Info.plist file
		[self editInfoPlistWithLog:^(NSString *log) {
			if (logResignBlock)
				logResignBlock(log);
			
		} error:^(NSString *error) {
			if (errorResignBlock)
				errorResignBlock(error);
			
		} success:^(id message) {
			if (logResignBlock)
				logResignBlock(message);
			
			// Edit the Provisioning Profile
			[self editProvisioningWithLog:^(NSString *log) {
				if (logResignBlock)
					logResignBlock(log);
				
			} error:^(NSString *error) {
				if (errorResignBlock)
					errorResignBlock(error);
				
			} success:^(id message) {
				if (logResignBlock)
					logResignBlock(message);
				
				// Edit the icon files
				[self editIconsWithLog:^(NSString *log) {
					if (logResignBlock)
						logResignBlock(log);
					
				} error:^(NSString *error) {
					if (errorResignBlock)
						errorResignBlock(error);

				} success:^(id message) {
					if (logResignBlock)
						logResignBlock(message);
					
					// Do the codesign
					[self doCodesignWithLog:^(NSString *log) {
						if (logResignBlock)
							logResignBlock(log);
						
					} error:^(NSString *error) {
						if (errorResignBlock)
							errorResignBlock(error);
						
					} success:^(id message) {
						if (logResignBlock)
							logResignBlock(message);
						
						// Do the ZIP task
						[self zipIpaWithLog:^(NSString *log) {
							if (logResignBlock)
								logResignBlock(log);
							
						} error:^(NSString *error) {
							if (errorResignBlock)
								errorResignBlock(error);

						} success:^(id message) {
							if (successResignBlock)
								successResignBlock(message);
						}];
					}];
				}];
			}];
		}];
	}];
}

#pragma mark - Info.plist

- (void)editInfoPlistWithLog:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
	logBlock = [log copy];
	errorBlock = [error copy];
	successBlock = [success copy];
	
	if (logBlock)
		logBlock(@"Editing the Info.plist file...");
	
	NSString* infoPlistPath = [self.appPath stringByAppendingPathComponent:kInfoPlistFilename];
	
	// Succeed to find the Info.plist
	if ([[NSFileManager defaultManager] fileExistsAtPath:infoPlistPath])
	{
		// Set the value of kCFBundleDisplayName/kCFBundleIdentifier in the Info.plist file
		NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:infoPlistPath];
		[plist setObject:self.displayName forKey:kCFBundleDisplayName];
		[plist setObject:self.bundleId forKey:kCFBundleIdentifier];
		[plist setObject:self.shortVersion forKey:kCFBundleShortVersionString];
		[plist setObject:self.buildVersion forKey:kCFBundleVersion];

		// Save the Info.plist file overwriting
		NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:kCFPropertyListImmutable error:nil];
		if ([xmlData writeToFile:infoPlistPath atomically:YES])
		{
			if (successBlock != nil)
				successBlock(@"File Info.plist edited properly");
		}
		else
		{
			if (errorBlock != nil)
				errorBlock(@"Failed to re-save the Info.plist file properly. Please try again.");
		}
	}
	
	// Failed to find the Info.plist
	else
	{
		if (errorBlock != nil)
			errorBlock(@"The IPA file you selected is corrupted: the app is unable to find a proper Info.plist file");
	}
}

#pragma mark - Entitlements

- (void)createEntitlementsWithLog:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success
{
    logBlock = [log copy];
    errorBlock = [error copy];
    successBlock = [success copy];
    
    if (logBlock)
        logBlock(@"Generating entitlements..");
    
    // Check if the entitlements exists: in this case delete it
    NSString* entitlementsPath = [self.workingPath stringByAppendingPathComponent:kEntitlementsPlistFilename];
    if (entitlementsPath != nil && [manager fileExistsAtPath:entitlementsPath])
    {
        NSError *error = nil;
        if (![manager removeItemAtPath:entitlementsPath error:&error])
        {
            if (errorBlock != nil)
                errorBlock(@"Unable to delete the last Entitlements file. Please try again.");
            return;
        }
    }

    
    // The provisioning selected is valid
    YAProvisioningProfile *profile = self.provisioningArray[self.provisioningIndex];
    if (profile != nil)
    {
        NSTask *generateEntitlementsTask = [[NSTask alloc] init];
        [generateEntitlementsTask setLaunchPath:@"/usr/bin/security"];
        [generateEntitlementsTask setArguments:@[@"cms", @"-D", @"-i", profile.path]];
        [generateEntitlementsTask setCurrentDirectoryPath:self.workingPath];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkEntitlements:) userInfo:@{@"task": generateEntitlementsTask}  repeats:TRUE];
        NSPipe *pipe = [NSPipe pipe];
        [generateEntitlementsTask setStandardOutput:pipe];
        [generateEntitlementsTask setStandardError:pipe];
        NSFileHandle *handle = [pipe fileHandleForReading];
        [generateEntitlementsTask launch];
        [NSThread detachNewThreadSelector:@selector(watchEntitlements:)
                                 toTarget:self withObject:handle];

    }
    // The provisioning selected is not valid
    else
    {
        if (errorBlock != nil)
            errorBlock(@"You must choose a valid *.mobileprovision file. Please try again.");
    }
}

- (void)watchEntitlements:(NSFileHandle*)streamHandle
{
    @autoreleasepool {
        // Set the entitlements result string
        entitlementsResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    }
}

- (void)checkEntitlements:(NSTimer *)timer
{
    // Check if the generate-entitlements task finished: if yes invalidate the timer and do some operations
    NSTask *generateEntitlementsTask = timer.userInfo[@"task"];
    if ([generateEntitlementsTask isRunning] == 0)
    {
        int terminationStatus = generateEntitlementsTask.terminationStatus;
        [timer invalidate];
        generateEntitlementsTask = nil;
        // The task succeed
        if (terminationStatus == 0)
        {
			[self doEntitlements];
        }
        // The task failed
        else
        {
            if (errorBlock != nil)
                errorBlock(@"Entitlements generation failed. Please try again");
        }
    }
}

- (void)doEntitlements
{
	// Edit the Entitlements file and save in the workingPath
    NSMutableDictionary* entitlements = [entitlementsResult.propertyList mutableCopy];
    entitlements = entitlements[@"Entitlements"];
	YAProvisioningProfile *profile = self.provisioningArray[self.provisioningIndex];
	NSString *appIdentifier = [NSString stringWithFormat:@"%@.%@", profile.teamIdentifier, self.bundleId];
	[entitlements setObject:appIdentifier forKey:kAppIdentifier];
	[entitlements removeObjectForKey:kTeamIdentifier];
	[entitlements removeObjectForKey:kKeychainAccessGroups];

    NSString* entitlementsPath = [self.workingPath stringByAppendingPathComponent:kEntitlementsPlistFilename];
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:entitlements format:NSPropertyListXMLFormat_v1_0 options:kCFPropertyListImmutable error:nil];
    
    // Saving Entitlements failed
    if (![xmlData writeToFile:entitlementsPath atomically:YES])
    {
		if (errorBlock != nil)
			errorBlock(@"Entitlements generation failed. Please try again");
	}
    
    // Saving Entitlements succeed
    else
    {
		if (successBlock != nil)
			successBlock(@"Entitlements generated");
    }
}


@end
