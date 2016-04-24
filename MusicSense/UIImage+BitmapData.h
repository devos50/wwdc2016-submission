//
//  UIImage+BitmapData.h
//  MusicSense
//
//  Created by Martijn de Vos on 28-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImage (BitmapData)
- (NSData *)bitmapData;
- (NSData *)bitmapFileHeaderData;
- (NSData *)bitmapDataWithFileHeader;
@end



# pragma pack(push, 1)
typedef struct s_bitmap_header
{
    // Bitmap file header
    UInt16 fileType;
    UInt32 fileSize;
    UInt16 reserved1;
    UInt16 reserved2;
    UInt32 bitmapOffset;
    
    // DIB Header
    UInt32 headerSize;
    UInt32 width;
    UInt32 height;
    UInt16 colorPlanes;
    UInt16 bitsPerPixel;
    UInt32 compression;
    UInt32 bitmapSize;
    UInt32 horizontalResolution;
    UInt32 verticalResolution;
    UInt32 colorsUsed;
    UInt32 colorsImportant;
} t_bitmap_header;
#pragma pack(pop)