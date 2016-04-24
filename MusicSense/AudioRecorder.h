//
//  AudioRecorder.h
//  MusicSense
//
//  Created by Martijn de Vos on 21-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioRecorder : NSObject

+ (void)startRecording;
+ (void)stopRecording;
+ (void)playRecording;

@end
