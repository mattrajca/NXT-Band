//
//  ImportMIDIWindowController.h
//  NXT Band
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

@class RMDFile;

@interface ImportMIDIWindowController : NSWindowController {
  @private
	NSArrayController *_tracksController;
	MusicSequence _sequence;
	MusicPlayer _player;
	SInt32 _playingTrack;
}

@property (nonatomic, strong) IBOutlet NSArrayController *tracksController;

@property (nonatomic, strong, readonly) RMDFile *file;

- (id)initWithPath:(NSString *)path;

- (IBAction)preview:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)select:(id)sender;

@end
