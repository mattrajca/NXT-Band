//
//  InputManager.m
//  NXT Band
//
//  Copyright Matt Rajca 2012. All rights reserved.
//

#import "InputManager.h"

#import <AudioToolbox/AudioToolbox.h>
#import <CoreMIDI/CoreMIDI.h>

NSString *const InputManagerNoteOnNotification = @"InputManagerNoteOnNotification";
NSString *const InputManagerNoteOffNotification = @"InputManagerNoteOffNotification";

NSString *const NoteValueKey = @"NoteValueKey";

@implementation InputManager {
	AUGraph _graph;
	AudioUnit _synthUnit;
	
	MIDIClientRef _client;
	MIDIPortRef _inputPort;
}

void InputProc (const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon);

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
		
		if (![self checkForMIDISources]) {
			NSLog(@"Could not check for MIDI sources");
		}
	}
	return self;
}

- (void)dealloc {
	if (_graph) {
		AUGraphStop(_graph);
		DisposeAUGraph(_graph);
	}
	
	if (_inputPort)
		MIDIPortDispose(_inputPort);
	
	if (_client)
		MIDIClientDispose(_client);
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

- (BOOL)checkForMIDISources {
	ItemCount sources = MIDIGetNumberOfSources();
	
	if (!sources) {
		NSLog(@"No MIDI sources found");
		return YES;
	}
	
	OSStatus result;
	MIDIEndpointRef endpoint = MIDIGetSource(0);
	
	//FIXME: set a notifyProc?
	require_noerr (result = MIDIClientCreate(CFSTR("InputManager"), NULL, NULL, &_client), home);
	
	require_noerr (result = MIDIInputPortCreate(_client, CFSTR("input"), InputProc, (__bridge void *) self, &_inputPort), home);
	
	require_noerr (result = MIDIPortConnectSource(_inputPort, endpoint, (__bridge void *) self), home);
	
	return YES;
	
home:
	return NO;
}

void InputProc (const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
	@autoreleasepool {
		InputManager *self = (__bridge InputManager *) readProcRefCon;
		
		for (int n = 0; n < pktlist->numPackets; n++) {
			MIDIPacket packet = pktlist->packet[n];
			
			if (packet.data[0] == 0x90) {
				Byte velocity = packet.data[2];
				
				if (velocity == 0) {
					[self simulateNoteOff:packet.data[1]];
				}
				else {
					[self simulateNoteOn:packet.data[1]];
				}
			}
		}
	}
}

- (void)simulateNoteOn:(int)value {
	MusicDeviceMIDIEvent(_synthUnit, 0x90, value, 127, 0);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:value] forKey:NoteValueKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:InputManagerNoteOnNotification
														object:nil
													  userInfo:info];
}

- (void)simulateNoteOff:(int)value {
	MusicDeviceMIDIEvent(_synthUnit, 0x80, value, 0, 0);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:value] forKey:NoteValueKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:InputManagerNoteOffNotification
														object:nil
													  userInfo:info];
}

@end
