//
//  Configuration.h
//  MusicSense
//
//  Created by Martijn de Vos on 21-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Configuration : NSObject

@property(nonatomic, assign) BOOL useRawFolder;
@property(nonatomic, assign) int recordingDuration;
@property(nonatomic, assign) int fftSamplingSize;
@property(nonatomic, assign) int windowOverlap;
@property(nonatomic, assign) int neighbourhoodRange;
@property(nonatomic, assign) int fingerprintNeighbours;
@property(nonatomic, assign) int hashSize;

@end
