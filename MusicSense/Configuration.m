//
//  Configuration.m
//  MusicSense
//
//  Created by Martijn de Vos on 21-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "Configuration.h"

@implementation Configuration

- (id)init
{
    if(self = [super init])
    {
        [self parseConfigFile];
    }
    return self;
}

- (void)parseConfigFile
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"musicsense" ofType:@"conf"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    _fftSamplingSize = [json[@"fft_sampling_size"] intValue];
    _fingerprintNeighbours = [json[@"fingerprint_neighbours"] intValue];
    _hashSize = [json[@"hash_size"] intValue];
    _neighbourhoodRange = [json[@"neighbourhood_range"] intValue];
    _recordingDuration = [json[@"recording_duration"] intValue];
    _useRawFolder = [json[@"use_raw_folder"] boolValue];
    _windowOverlap = [json[@"window_overlap"] intValue];
}

@end
