//
//  Analyzer.m
//  MusicSense
//
//  Created by Martijn de Vos on 21-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "Analyzer.h"
#import <Accelerate/Accelerate.h>
#import "FFTHelper.h"
#import "Peak.h"
#import "AFNetworking.h"
#import "UIImage+BitmapData.h"

@implementation Analyzer
{
    NSData *songData;
    NSArray *peaks;
    NSArray *hashes;
    Configuration *config;
    Spectrogram *spectrogram;
    NSDictionary *result;
    int historyId;
}

- (id)initWithFileFromBundle:(NSString *)filename isInDocuments:(BOOL)inDocuments andWithConfiguration:(Configuration *)configg
{
    if(self = [super init])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains
        (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *songPath = [NSString stringWithFormat:@"%@/%@.wav", documentsDirectory, filename];
        if(!inDocuments)
        {
            songPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"wav"];
        }
        
        NSURL *songUrl = [NSURL fileURLWithPath:songPath];
        songData = [[NSFileManager defaultManager] contentsAtPath:songUrl.path];
        config = configg;
        
        [self analyzeSong];
    }
    return self;
}

- (void)analyzeSong
{
    unsigned long shouldRead = (songData.length) / 2;
    NSMutableArray *samplesArray = [NSMutableArray new];
    for(int i = 22; i < shouldRead; i++)
    {
        [samplesArray addObject:@(((SInt16 *)songData.bytes)[i])];
    }
    
    // consider the window overlap
    int numOverlappedSamples = (int)(samplesArray.count * config.windowOverlap);
    int *overlapSamplesArray = (int *)malloc(sizeof(int) * numOverlappedSamples);
    int backSamples = config.fftSamplingSize * (config.windowOverlap - 1) / config.windowOverlap;
    int fftSampleSize_1 = config.fftSamplingSize - 1;
    int pointer = 0;
    int loopEntered = 0;
    for(int i = 0; i < samplesArray.count; i++)
    {
        loopEntered++;
        overlapSamplesArray[pointer] = ((NSNumber *)samplesArray[i]).intValue;
        pointer++;
        if(pointer % config.fftSamplingSize == fftSampleSize_1) { i -= backSamples; }
    }
    
    samplesArray = [NSMutableArray new];
    for(int i = 0; i < numOverlappedSamples; i++) { samplesArray[i] = @(overlapSamplesArray[i]); }
    
    // perform FFT on the slices
    spectrogram = [Spectrogram new];
    for(int i = 0; i < samplesArray.count / config.fftSamplingSize; i++)
    {
        float *sampleBuffer = malloc(sizeof(float) * config.fftSamplingSize);
        for(int j = 0; j < config.fftSamplingSize; j++)
        {
            NSNumber *sample = samplesArray[i * config.fftSamplingSize + j];
            sampleBuffer[j] = sample.floatValue;
        }
        [spectrogram addSpectrum:[self applyFFT:sampleBuffer]];
    }
    
    [spectrogram generateNormalizedSpectrogram];
    [spectrogram applyThreshold];
    // [spectrogram printSpectrogram];
    peaks = [spectrogram getPeaks];
    NSLog(@"peaks: %lu", (unsigned long)peaks.count);
    
    hashes = [self createHashesFromPeaks];
    NSLog(@"hashes: %lu", (unsigned long)hashes.count);
    
    [self sendHashesToServer];
}

- (NSArray *)applyFFT:(float *)sampleBuffer
{
    NSMutableArray *amplitudes = [NSMutableArray new];
    
    int fftSize = config.fftSamplingSize;	// sample size
    
    float *signals_in = (float *) malloc(fftSize * sizeof(float));
    
    int windowSize = fftSize;
    float *window = (float *) malloc(sizeof(float) * windowSize);
    memset(window, 0, sizeof(float) * windowSize);
    vDSP_hamm_window(window, windowSize, 0);
    
    // apply window
    vDSP_vmul(sampleBuffer, 1, window, 1, signals_in, 1, fftSize);
    
    // create double array
    double *signals = (double *)malloc(sizeof(double) * config.fftSamplingSize);
    for(int i = 0; i < config.fftSamplingSize; i++) { signals[i] = (double)signals_in[i]; }
    
    // do FFT
    FFTHelper *helper = [[FFTHelper alloc] init];
    [helper transformData:signals];
    
    double *complexNumbers = (double *) malloc(sizeof(double) * config.fftSamplingSize);
    for(int i = 0; i < config.fftSamplingSize; i++) { complexNumbers[i] = signals[i]; }
    
    int indexSize = config.fftSamplingSize / 2;
    int positiveSize = indexSize / 2;
    
    double *magnitudes = (double *)malloc(sizeof(double) * positiveSize);
    for(int i = 0; i < indexSize; i+= 2)
    {
        magnitudes[i / 2] = sqrt(complexNumbers[i] * complexNumbers[i] + complexNumbers[i + 1] * complexNumbers[i + 1]);
    }
    
    for(int i = 0; i < positiveSize; i++) { [amplitudes addObject:@(magnitudes[i])]; }
    
    return amplitudes;
}

- (long)createHashFrom:(int) freq1 andFreq2:(int) freq2 andDelta: (int) d
{
    return 1000000 * freq1 + 1000 * freq2 + d;
}

- (NSArray *)createHashesFromPeaks
{
    NSMutableArray *ahashes = [NSMutableArray new];
    
    // perform K-NN
    for(int i = 0; i < peaks.count; i++)
    {
        __block Peak *peakI = (Peak *)peaks[i];
        
        // define comparator
        NSComparator comparePeaks = ^(id obj1, id obj2) {
            Peak *p1 = (Peak *)obj1;
            Peak *p2 = (Peak *)obj2;
            int d1 = [Peak getDistanceBetween:p1 andPeak:peakI];
            int d2 = [Peak getDistanceBetween:p2 andPeak:peakI];
            if(d1 > d2) { return NSOrderedDescending; }
            else if(d1 < d2) { return NSOrderedAscending; }
            return NSOrderedSame;
        };
        
        NSMutableArray *nearest = [NSMutableArray new];
        for(int j = 0; j < peaks.count; j++)
        {
            Peak *peakJ = (Peak *)peaks[j];
            if(i == j) { continue; }
            if(peakI.x >= peakJ.x) { continue; }
            
            if(nearest.count < config.fingerprintNeighbours)
            {
                [nearest addObject:peakJ];
                [nearest sortUsingComparator:comparePeaks];
                continue;
            }
            
            Peak *mostFarAwaySoFar = (Peak *)nearest[nearest.count - 1];
            if([Peak getDistanceBetween:peakI andPeak:mostFarAwaySoFar] <= [Peak getDistanceBetween:peakI andPeak:peakJ]) { continue; }
            
            [nearest addObject:peakJ];
            [nearest sortUsingComparator:comparePeaks];
            if(nearest.count > config.fingerprintNeighbours) { [nearest removeLastObject]; }
        }
        
        // now create hashes
        for(int k = 0; k < nearest.count; k++)
        {
            Peak *p1 = (Peak *)peaks[i];
            Peak *p2 = (Peak *)nearest[k];
            
            int freq1 = p1.y; int freq2 = p2.y;
            int t1 = p1.x; int t2 = p2.x;
            long hash = [self createHashFrom:freq1 andFreq2:freq2 andDelta:(t2 - t1)];
            [ahashes addObject:@{ @"hash" : @(hash), @"t" : @(t1) }];
        }
    }
    
    return ahashes;
}

- (void)sendHashesToServer
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:hashes
                                                       options:0
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSDictionary *params = @{ @"json" : jsonString };
    [manager POST:@"http://musicsense.no-ip.org/match" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        result = responseObject;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"nl.tudelft.MusicSense.HasResult" object:nil userInfo:@{ @"result" : responseObject }];
        
        // now send the peaks and spectrogram to the server
        historyId = [responseObject[@"id"] intValue];
        //[self sendPeaksAndSpectrogramToServer];
        
        NSLog(@"response: %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"send failed: %@", error);
    }];
}

- (void)sendPeaksAndSpectrogramToServer
{
    UIImage *spectrogramImage = [[self getSpectrogram] getSpectrogramImage];
    UIImage *peaksImage = [[self getSpectrogram] getPeaksImageWithPeaks:peaks];
    NSData *spectrogramImageData = [spectrogramImage bitmapDataWithFileHeader];
    NSData *peaksImageData = [peaksImage bitmapDataWithFileHeader];
    NSString *spectrogramImageBase = [spectrogramImageData base64EncodedStringWithOptions:0];
    NSString *peaksImageBase = [peaksImageData base64EncodedStringWithOptions:0];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSDictionary *params = @{ @"spectrogram" : spectrogramImageBase, @"peaks" : peaksImageBase, @"id" : @(historyId) };
    [manager POST:@"http://musicsense.no-ip.org/uploadpeaksspectrogram" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"image succesfully sent to server");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"send of images failed: %@", error);
    }];
}

- (Spectrogram *)getSpectrogram
{
    return spectrogram;
}

- (NSDictionary *)getResult
{
    return result;
}

- (NSArray *)getPeaks
{
    return peaks;
}

@end
