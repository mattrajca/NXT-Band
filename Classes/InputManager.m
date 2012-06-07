//
//  InputManager.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "InputManager.h"

#import <AudioToolbox/AudioToolbox.h>

NSString *const InputManagerNoteOnNotification = @"InputManagerNoteOnNotification";
NSString *const InputManagerNoteOffNotification = @"InputManagerNoteOffNotification";

NSString *const NoteValueKey = @"NoteValueKey";

@implementation InputManager {
	AUGraph _graph;
	AudioUnit _synthUnit;
}

+ (id)sharedManager {
	static InputManager *sharedManager = nil;
	
	if (!sharedManager) {
		sharedManager = [[InputManager alloc] init];
	}
	
	return sharedManager;
}

- (id)init {
	self = [super init];
	if (self) {
		if ([self setUpAudioGraph]) {
			if (![self startDLS]) {
				NSLog(@"Could not start audio graph");
			}
		}
		else {
			NSLog(@"Could not set up audio graph");
		}
	}
	return self;
}

- (void)dealloc {
	if (_graph) {
		AUGraphStop(_graph);
		DisposeAUGraph(_graph);
	}
}

- (BOOL)setUpAudioGraph {
	OSStatus result;
	
	AUNode synthNode, mixerNode, outNode;
	
	AudioComponentDescription cd;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	
	require_noerr (result = NewAUGraph(&_graph), home);
	
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_DLSSynth;
	
	require_noerr (result = AUGraphAddNode(_graph, &cd, &synthNode), home);
	
	cd.componentType = kAudioUnitType_Mixer;
	cd.componentSubType = kAudioUnitSubType_StereoMixer;
	
	require_noerr (result = AUGraphAddNode(_graph, &cd, &mixerNode), home);
	
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_DefaultOutput;
	
	require_noerr (result = AUGraphAddNode(_graph, &cd, &outNode), home);
	
	require_noerr (result = AUGraphOpen(_graph), home);
	
	require_noerr (result = AUGraphConnectNodeInput(_graph, synthNode, 0, mixerNode, 0), home);
	require_noerr (result = AUGraphConnectNodeInput(_graph, mixerNode, 0, outNode, 0), home);
	
	require_noerr (result = AUGraphNodeInfo(_graph, synthNode, 0, &_synthUnit), home);
	
	return YES;
	
home:
	return NO;
}

- (BOOL)startDLS {
	OSStatus result;
	
	require_noerr (result = AUGraphInitialize(_graph), home);
	require_noerr (result = AUGraphStart(_graph), home);
	
	return YES;
	
home:
	return NO;
}

- (void)simulateNoteOn:(int)value {
	MusicDeviceMIDIEvent(_synthUnit, 0x90, 60 + value, 127, 0);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:value] forKey:NoteValueKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:InputManagerNoteOnNotification
														object:nil
													  userInfo:info];
}

- (void)simulateNoteOff:(int)value {
	MusicDeviceMIDIEvent(_synthUnit, 0x80, 60 + value, 0, 0);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:value] forKey:NoteValueKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:InputManagerNoteOffNotification
														object:nil
													  userInfo:info];
}

@end
