//
//  Analyzer.h
//  MusicSense
//
//  Created by Martijn de Vos on 21-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"
#import "Spectrogram.h"

@interface Analyzer : NSObject

- (id)initWithFileFromBundle:(NSString *)filename isInDocuments:(BOOL)inDocuments andWithConfiguration:(Configuration *)configg;
- (Spectrogram *)getSpectrogram;
- (NSDictionary *)getResult;
- (NSArray *)getPeaks;
- (void)sendPeaksAndSpectrogramToServer;

@end
