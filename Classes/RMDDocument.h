//
//  RMDDocument.h
//  NXT Band
//
//  Copyright Matt Rajca 2011-2012. All rights reserved.
//

#import "MRPianoRollView.h"
#import "RecordingOverlay.h"

@class RMDFile;

@interface RMDDocument : NSDocument < MRPianoRollViewDataSource >

@property (nonatomic, unsafe_unretained) IBOutlet MRPianoRollView *rollView;
@property (nonatomic, unsafe_unretained) IBOutlet RecordingOverlay *overlay;
@property (nonatomic, unsafe_unretained) IBOutlet NSTextField *infoField;

@property (nonatomic, strong) RMDFile *file;

- (IBAction)playStop:(id)sender;
- (IBAction)record:(id)sender;

- (IBAction)switchTool:(id)sender;

@end
