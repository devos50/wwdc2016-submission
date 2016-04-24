//
//  Spectrogram.h
//  MusicSense
//
//  Created by Martijn de Vos on 24-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Spectrogram : NSObject

- (void)addSpectrum:(NSArray *)spectrum;
- (void)printSpectrogram;
- (void)printNormalizedSpectrogram;
- (void)generateNormalizedSpectrogram;
- (void)applyThreshold;
- (NSArray *)getPeaks;
- (UIImage *)getSpectrogramImage;
- (UIImage *)getPeaksImageWithPeaks:(NSArray *)peaks;

@end
