//
//  Peak.m
//  MusicSense
//
//  Created by Martijn de Vos on 24-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "Peak.h"

@implementation Peak

- (instancetype)initWithIntensity:(double)intensity andX:(int)x andY:(int)y
{
    if(self = [super init])
    {
        self.intensity = intensity;
        self.x = x;
        self.y = y;
    }
    return self;
}

- (void)printPeak
{
    NSLog(@"(%f, %d, %d)", self.intensity, self.x, self.y);
}

+ (int)getDistanceBetween:(Peak *)p1 andPeak:(Peak *)p2
{
    return (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y);
}

@end
