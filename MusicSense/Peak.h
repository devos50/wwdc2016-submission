//
//  Peak.h
//  MusicSense
//
//  Created by Martijn de Vos on 24-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Peak : NSObject

@property(nonatomic, assign) double intensity;
@property(nonatomic, assign) int x;
@property(nonatomic, assign) int y;

- (instancetype)initWithIntensity:(double)intensity andX:(int)x andY:(int)y;
- (void)printPeak;
+ (int)getDistanceBetween:(Peak *)p1 andPeak:(Peak *)p2;

@end
