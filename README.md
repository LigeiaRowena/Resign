This is a OSX utility app to get all the infos about an IPA file and to resign it.

Main features:

- Minimum OS: OS 10.9
- ARC
- Language used: Objective-C
- Only resign and get information about IPA file for iPads

#INSTALLATION

You can open the xcode project and build it or open directly the app.

#GETTING INFO FROM IPA FILES

Just open the ipa file by tapping the button "Open the ipa file" or dragging it in the relative field. 
Then you have information about:
- provisioning profile  
- signign certificate 
- bundle id
- display name
- short version and build version
- normal icon (76x76 pixels) and retina icon (152x152 pixels)

At the bottom you have also a console textview, you can clean it by tapping the "Clean" button.
If you tap on the "?" icons near some feature, the console prints the relative informations.

#RESIGN IPA FILES

Once you opened an ipa file, the console prints this message to tell that the app is ready to resign the ipa file:

`---READY---`

Now you can decide to resign the ipa file changing some feature of it by tapping the "Resign" button:
- provisioning profile: tap on the combobox in order to change it
- signign cettificate: tap on the combobox in order to change it
- bundle id: deselect the ratio button "Default Bundle ID" in order change it
- display name: deselect the ratio button "Default display name" in order change it
- short version and build version: deselect the ratio buttons "Default IPA short version" and "Default IPA build version" in order change them
- normal icon (76x76 pixels) and retina icon (152x152 pixels): deselect the ratio button "Default icons" in order change them and then just tap on the icons to open other icons, please select a normal icon of 76x76 pixels and a retina icon of 152x152 pixels

When the resign finished successfully, the console prints the message:

`---RESIGN DONE---`

Then you can:
- resign the same source ipa file loaded before by simply changing other features and tapping the "Resign" button another time
- tap the "Reset all" button in order to delete all the infos about the last ipa file loaded, and load another ipa file to resign it

If you loaded an ipa file, if you change some features of it then you can always tap the "Use default values" button in order to reset all the above features to the default ones.
You can decide the destination ipa path where to save the resigned ipa file, the default one is Desktop.

#HELPER CLASSES

- NSScrollView+MultiLine
- 
Category of NSScrollView to access directly to the textview of the scrollview.
You have two utility methods:

To append a string to the existing string value of the textview of the scrollview.

`- (void)appendStringValue:(NSString*)string;`

To set the string to the existing string value of the textview of the scrollview.

`- (void)setStringValue:(NSString*)string;`

- FileHandler
- 
Class that handles all the IPA operations. It's a singleton so you can call it by:

`+ (instancetype)sharedInstance;`

You have a lot of public properties you can access:

```
// array of provisioning profiles available
@property (nonatomic, strong) NSMutableArray *provisioningArray;

// index of the provisioning profile selected in the combo for the resign
@property (nonatomic) int provisioningIndex;

// original index of the provisioning profile from the original IPA file
@property (nonatomic) int originalProvisioningIndex;

// YES: the provisioning was edited
// NO: the provisioning is the default one of the original IPA file
@property (nonatomic) BOOL editProvisioning;

// YES: the icons were edited
// NO: the icons are the default ones of the original IPA file
@property (nonatomic) BOOL editIcons;

// path of the edited normal icon (76x76 pixel)
@property (nonatomic, strong) NSString *iconPath;

// path of the edited retina icon (152x152 pixel)
@property (nonatomic, strong) NSString *iconRetinaPath;

// bundle id selected for the resign
@property (nonatomic, strong) NSString *bundleId;

// display name selected for the resign
@property (nonatomic, strong) NSString *displayName;

// short version selected for the resign
@property (nonatomic, strong) NSString *shortVersion;

// build version selected for the resign
@property (nonatomic, strong) NSString *buildVersion;

// array of certificates available
@property (nonatomic, strong) NSMutableArray *certificatesArray;

// index of the certificate selected in the combo for the resign
@property (nonatomic) int certificateIndex;

// source ipa path
@property (nonatomic, strong) NSString *sourcePath;

// temp working directory
@property (nonatomic, strong) NSString *workingPath;

// path of the unzipped ipa (inside the workingPath)
@property (nonatomic, strong) NSString *appPath;

// destination ipa path
@property (nonatomic, strong) NSString *destinationPath;
```

You have also a lot of public methods you can use:

```
// array of provisioning profiles available
// init
+ (instancetype)sharedInstance;

// utility
- (void)clearAll;
+ (NSString*)getDocumentFolderPath;
- (BOOL)removeWorkingDirectory;
- (BOOL)removeCodeSignatureDirectory;

// bundle id
- (void)getDefaultBundleIDWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// short version
- (void)getDefaultShortVersionWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// build version
- (void)getDefaultBuildVersionWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// product name
- (void)getDefaultProductNameWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// icons
- (void)getDefaultIconFilesWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// zip/unzip
- (BOOL)searchForZipUtility;
- (void)unzipIpaFromSource:(NSString*)ipaFileName log:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success;

// app info
- (void)showIpaInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;
- (void)showProvisioningInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;
- (void)showCertificatesInfoWithSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// provisioning profiles
- (void)getProvisioningProfiles;
- (NSString*)getProvisioningInfoAtIndex:(NSInteger)index;

// signign certificates
- (void)getCertificatesSuccess:(SuccessBlock)success error:(ErrorBlock)error;

// resign
- (void)resignWithBundleId:(NSString*)bundleId displayName:(NSString*)displayName shortVersion:(NSString*)shortVersion buildVersion:(NSString*)buildVersion log:(LogBlock)log error:(ErrorBlock)error success:(SuccessBlock)success;

```

Screens:

![alt text](https://github.com/LigeiaRowena/Resign/blob/master/screen.png "Screen")
