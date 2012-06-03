//
//  FreqTable.c
//  NXT Band
//
//  Copyright Matt Rajca 2011. All rights reserved.
//

#include "FreqTable.h"

#define FREQS 29

// idx 0: C below the middle-C

static const uint16_t freq_table[] = {
	131,
	139,
	147,
	156,
	165,
	175,
	185,
	196,
	208,
	220,
	233,
	247,
	262,
	277,
	294,
	311,
	330,
	349,
	370,
	392,
	415,
	440,
	466,
	494,
	523,
	554,
	587,
	622,
	659
};

int idx_for_note_freq (uint16_t freq) {
	for (int n = 0; n < FREQS; n++) {
		if (freq == freq_table[n])
			return n;
	}
	
	return -1;
}

int freq_for_note (uint8_t note) {
	if (note >= FREQS)
		return 0;
	
	return freq_table[note];
}
