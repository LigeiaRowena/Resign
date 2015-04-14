//
//  FileHandler.h
//  Resign
//
//  Created by Francesca Corsini on 12/04/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "YAProvisioningProfile.h"

typedef void(^SuccessBlock)(id);
typedef void(^ErrorBlock)(NSString*);
typedef void(^LogBlock)(NSString*);

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

static NSString *kIconNormal = @"iconNormal";
static NSString *kIconRetina = @"iconRetina";


@interface FileHandler : NSObject <NSFileManagerDelegate>
{
    // blocks
	SuccessBlock successBlock;
	ErrorBlock errorBlock;
    LogBlock logBlock;
    
    // date formatter
    NSDateFormatter *formatter;
    
    // global file manager
    NSFileManager *manager;
}

// array of provisioning profiles available
@property (nonatomic, strong) NSMutableArray *provisioningArray;

// array of certificates available
@property (nonatomic, strong) NSMutableArray *certificatesArray;

// source ipa path
@property (nonatomic, strong) NSString *sourcePath;

// temp working directory
@property (nonatomic, strong) NSString *workingPath;

// path of the unzipped ipa (inside the workingPath)
@property (nonatomic, strong) NSString *appPath;

// destination ipa path
@property (nonatomic, strong) NSString *destinationPath;

+ (instancetype)sharedInstance;

+ (NSString*)getDocumentFolderPath;
- (BOOL)removeWorkingDirectory;

- (void)getDefaultBundleIDWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

- (void)getDefaultProductNameWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

- (void)getDefaultIconFilesWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

- (BOOL)searchForZipUtility;
- (void)unzipIpaFromSource:(NSString*)ipaFileName log:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success;
- (void)showIpaInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;
- (void)showProvisioningInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;
- (void)showCertificatesInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

- (void)getProvisioningProfiles;
- (NSString*)getProvisioningInfoAtIndex:(NSInteger)index;

- (void)getCertificatesSuccess:(SuccessBlock)success error:(ErrorBlock)error;

@end
