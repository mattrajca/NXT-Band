//
//  AppDelegate.m
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "AppDelegate.h"

#import "ImportMIDIWindowController.h"
#import "InputManager.h"
#import "KeyboardWindowController.h"
#import "RMDDocument.h"

@implementation AppDelegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[InputManager sharedManager]; // so we can process MIDI sources
}

- (IBAction)importMIDI:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	NSArray *types = [NSArray arrayWithObjects:@"midi", @"mid", nil];
	
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
	
	if ([docController runModalOpenPanel:panel forTypes:types] == NSOKButton) {
		ImportMIDIWindowController *wc = [[ImportMIDIWindowController alloc] initWithPath:[[panel URL] path]];
		[wc showWindow:self];
		
		[NSApp runModalForWindow:[wc window]];
		
		if (!wc.file)
			return;
		
		RMDDocument *doc = [docController openUntitledDocumentAndDisplay:NO error:nil];
		doc.file = wc.file;
		
		[docController addDocument:doc];
		
		[doc updateChangeCount:NSChangeDone];
		[doc makeWindowControllers];
		[doc showWindows];
	}
}

- (IBAction)showKeyboard:(id)sender {
	[[KeyboardWindowController sharedKeyboard] showWindow:self];
}

@end
