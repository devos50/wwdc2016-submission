//
//  Spectrogram.m
//  MusicSense
//
//  Created by Martijn de Vos on 24-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "Spectrogram.h"
#import "Peak.h"

@implementation Spectrogram
{
    NSMutableArray *spectrogram;
    NSMutableArray *normalizedSpectrogram;
}

- (instancetype)init
{
    if(self = [super init])
    {
        spectrogram = [NSMutableArray new];
    }
    return self;
}

float hueToRgb(float p, float q, float t)
{
    if (t < 0)
        t += 1;
    if (t > 1)
        t -= 1;
    if (t < 1.0/6.0)
        return p + (q - p) * 6.0 * t;
    if (t < 1.0/2.0)
        return q;
    if (t < 2.0/3.0)
        return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

int *hslToRgb(float h, float s, float l)
{
    int *arr = malloc(sizeof(int) * 3);
    
    float r, g, b;
    
    if (s == 0) {
        r = g = b = l; // achromatic
    } else {
        float q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        float p = 2 * l - q;
        r = hueToRgb(p, q, h + 1.0/3.0);
        g = hueToRgb(p, q, h);
        b = hueToRgb(p, q, h - 1.0/3.0);
    }
    
    arr[0] = r * 255; arr[1] = g * 255; arr[2] = b * 255;
    
    return arr;
}

- (void)addSpectrum:(NSArray *)spectrum
{
    [spectrogram addObject: spectrum];
}

- (void)printSpectrogram
{
    NSLog(@"%@", spectrogram[0]);
}

- (void)printNormalizedSpectrogram
{
    NSLog(@"%@", normalizedSpectrogram);
}

- (double)getMaxValueSpectrogram
{
    double max = -10000000.0;
    for(int i = 0; i < spectrogram.count; i++)
    {
        NSArray *spectrum = spectrogram[i];
        for(int j = 0; j < spectrum.count; j++)
        {
            double val = ((NSNumber *)spectrum[j]).doubleValue;
            if(val > max) { max = val; }
        }
    }
    return max;
}

- (double)getMinValueSpectrogram
{
    double min = 10000000.0;
    for(int i = 0; i < spectrogram.count; i++)
    {
        NSArray *spectrum = spectrogram[i];
        for(int j = 0; j < spectrum.count; j++)
        {
            double val = ((NSNumber *)spectrum[j]).doubleValue;
            if(val < min) { min = val; }
        }
    }
    return min;
}

- (void)generateNormalizedSpectrogram
{
    normalizedSpectrogram = [NSMutableArray new];
    
    double minValid = 0.00000000001f;
    double maxVal = [self getMaxValueSpectrogram];
    double minVal = [self getMinValueSpectrogram];
    if(minVal == 0) { minVal = minValid; }
    double diff = log10(maxVal / minVal);
    
    for(int i = 0; i < spectrogram.count; i++)
    {
        NSArray *spectrum = spectrogram[i];
        NSMutableArray *newSpectrum = [NSMutableArray new];
        
        for(int j = 0; j < spectrum.count; j++)
        {
            double val = ((NSNumber *)spectrum[j]).doubleValue;
            if(val < minValid) { [newSpectrum addObject:@(0.0)]; }
            else { [newSpectrum addObject:@((log10(val / minVal)) / diff)]; }
        }
        [normalizedSpectrogram addObject: newSpectrum];
    }
}

- (void)applyThreshold
{
    // determine median
    NSMutableArray *allValues = [NSMutableArray new];
    for(int i = 0; i < spectrogram.count; i++)
    {
        NSArray *spectrum = spectrogram[i];
        for(int j = 0; j < spectrum.count; j++) { [allValues addObject:spectrum[j]]; }
    }
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [allValues sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    
    double median = -1;
    if(allValues.count % 2 == 0)
    {        
        double num1 = ((NSNumber *)allValues[allValues.count / 2 - 1]).doubleValue;
        double num2 = ((NSNumber *)allValues[allValues.count / 2]).doubleValue;
        median = (num1 + num2) / 2.0;
    }
    else { median = ((NSNumber *)allValues[allValues.count / 2]).doubleValue; }
        
    for(int i = 0; i < spectrogram.count; i++)
    {
        NSMutableArray *spectrum = spectrogram[i];
        for(int j = 0; j < spectrum.count; j++)
        {
            double val = ((NSNumber *)spectrum[j]).doubleValue;
            if(val < median / 2) { spectrum[j] = @(0.0); }
        }
    }
}

- (NSArray *)getPeaks
{
    int neighbourhoodRange = 6;
    unsigned long spectrogramWidth = spectrogram.count;
    unsigned long spectrogramHeight = ((NSArray *)spectrogram[0]).count;
    NSMutableArray *peaks = [NSMutableArray new];
    
    for(int y = 0; y < spectrogramHeight; y++)
    {
        for(int x = 0; x < spectrogramWidth; x++)
        {
            double val = ((NSNumber *)spectrogram[x][y]).doubleValue;
            if(val == 0.0) { continue; }
            BOOL isBigger = YES;
            
            // iterate depending on the neighbourhood range
            for(int yin = y - neighbourhoodRange; yin <= y + neighbourhoodRange; yin++)
            {
                for(int xin = x - neighbourhoodRange; xin <= x + neighbourhoodRange; xin++)
                {
                    if(yin < 0 || yin >= spectrogramHeight || xin < 0 || xin >= spectrogramWidth)
                    {
                        continue;
                    }
                    
                    if(((NSNumber *)spectrogram[xin][yin]).doubleValue > ((NSNumber *)spectrogram[x][y]).doubleValue)
                    {
                        isBigger = false;
                        break;
                    }
                }
            }
            
            if(isBigger)
            {
                double val = ((NSNumber *)spectrogram[x][y]).doubleValue;
                Peak *peak = [[Peak alloc] initWithIntensity:val andX:x andY:y];
                [peaks addObject:peak];
            }
        }
    }
    
    return peaks;
}

- (UIImage *)getSpectrogramImage
{
    int width = (int)normalizedSpectrogram.count;
    CGFloat height = ((NSArray *)normalizedSpectrogram[0]).count;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel    = 4;
    size_t bytesPerRow      = (width * bitsPerComponent * bytesPerPixel + 7) / 8;
    size_t dataSize         = bytesPerRow * height;
    
    unsigned char *data = malloc(dataSize);
    memset(data, 0, dataSize);
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            double val = ((NSNumber *)normalizedSpectrogram[x][y]).doubleValue;
            float h = (1 - (float)val);
            float s = 1;
            float l = (float)val * (float)0.5;
            int *rgbs = hslToRgb(h, s, l);
            
            int byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            data[byteIndex + 0] = rgbs[0];
            data[byteIndex + 1] = rgbs[1];
            data[byteIndex + 2] = rgbs[2];
            data[byteIndex + 3] = 255;
        }
    }
    
    CGContextRef context = CGBitmapContextCreate(data, width, height,
                                                 bitsPerComponent,
                                                 bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(context);
    free(data);    
    return [self flipImage:result];
}

- (UIImage *)flipImage:(UIImage *)image
{
    UIGraphicsBeginImageContext(image.size);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(0.,0., image.size.width, image.size.height),image.CGImage);
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return i;
}

- (UIImage *)getPeaksImageWithPeaks:(NSArray *)peaks
{
    int width = (int)normalizedSpectrogram.count;
    CGFloat height = ((NSArray *)normalizedSpectrogram[0]).count;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel    = 4;
    size_t bytesPerRow      = (width * bitsPerComponent * bytesPerPixel + 7) / 8;
    size_t dataSize         = bytesPerRow * height;
    
    unsigned char *data = malloc(dataSize);
    memset(data, 0, dataSize);
    
    // color everything white
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            int byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            data[byteIndex + 0] = 255;
            data[byteIndex + 1] = 255;
            data[byteIndex + 2] = 255;
            data[byteIndex + 3] = 255;
        }
    }
    
    // color the peaks black
    [peaks enumerateObjectsUsingBlock:^(Peak *peak, NSUInteger idx, BOOL *stop)
    {
        int byteIndex = (bytesPerRow * peak.y) + peak.x * bytesPerPixel;
        data[byteIndex + 0] = 0;
        data[byteIndex + 1] = 0;
        data[byteIndex + 2] = 0;
        data[byteIndex + 3] = 255;
    }];
    
    CGContextRef context = CGBitmapContextCreate(data, width, height,
                                                 bitsPerComponent,
                                                 bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(context);
    free(data);
    
    // flip
    return [self flipImage:result];
}

@end
