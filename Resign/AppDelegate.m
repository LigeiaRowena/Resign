//
//  AppDelegate.m
//  Resign
//
//  Created by Francesca Corsini on 17/03/15.
//  Copyright (c) 2015 Francesca Corsini. All rights reserved.
//

#import "AppDelegate.h"
#import "FileHandler.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// add a contentView
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	[self.window.contentView addSubview:self.viewController.view];
	self.viewController.view.frame = ((NSView*)self.window.contentView).bounds;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[FileHandler sharedInstance] removeWorkingDirectory];
}

@end
