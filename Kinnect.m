//
//  Kinnect.m
//  Caffe
//
//  Created by Nicholas Peretti on 5/3/16.
//  Copyright © 2016 Venture Media. All rights reserved.
//

#import "Kinnect.h"
#import <libfreenect/libfreenect_sync.h>

@implementation Kinnect
{
    NSImage *_depth;
    int picindex;
    NSSize croppedSize;
    NSImage *_lastHD;
    uint16_t *lastDepth;
    
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        picindex = 0;
        croppedSize = NSMakeSize(64, 64);
    }
    return self;
}

-(uint16_t *)rawDepth
{
    return lastDepth;
}

-(uint16_t *)justDepth
{
    uint16_t *depthData = malloc(sizeof(uint16_t)*(640*480));
    unsigned int timestampDepth;
    freenect_sync_get_depth_with_res((void**)(&depthData), &timestampDepth, 0, FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_MM);
    return depthData;
}

-(NSImage *)highRes
{
    return _lastHD;
}

-(NSImage *)traceImages
{
    
    int windowSize = 480;
    float minDepth = 0.7;
    float maxDepth = 1.5;
    uint16_t *depthData = malloc(sizeof(uint16_t)*(640*480));
    unsigned int timestampDepth;
    freenect_sync_get_depth_with_res((void**)(&depthData), &timestampDepth, 0, FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_MM);
    lastDepth = depthData;
    SCNVector3 vecs[windowSize*windowSize];
    int left = 320-(windowSize/2);
    int top = 240-(windowSize/2);
    int totalx = 0;
    int totaly = 0;
    int points = 0;
    int tip = 9999;
    CGFloat minZ = 9999;
    CGFloat maxZ = -99999;
    for (int y = 0;y<windowSize;y++) {
        for (int x = 0;x<windowSize;x++) {
            int i = ((top+y)*640)+(left+x);
            float depth = depthData[i];
            SCNVector3 vec = [self world:depth x:i%640 y:(i/640)];
            vecs[y*windowSize+x] = vec;
            if (vec.z>minDepth&&vec.z<maxDepth) {
                totalx+=x;
                totaly+=y;
                points++;
                if (y<tip) {
                    tip = y;
                }
               
            }
        }
    }
    
    int cropSize = 128;
    UInt8 *data = malloc(cropSize*cropSize*3);
    if (points>0) {
        int offset = 0;
        int averagX = totalx/points;
        int averageY = tip+60;
        if (averagX<cropSize/2) {
            averagX=cropSize/2;
        }
        if (averagX>640-(cropSize/2)) {
            averagX=640-(cropSize/2);
        }
        if (averageY<cropSize/2) {
            averageY=cropSize/2;
        }
        if (averageY>480-(cropSize/2)) {
            averageY=480-(cropSize/2);
        }
        int sleft = averagX-(cropSize/2);
        int stop = averageY-(cropSize/2);
        
        //CGFloat dictanceTotals = 0;
        SCNVector3 newMidPoint = SCNVector3Make(0, 0, 0);
        points = 0;
        for (int y = 0;y<cropSize;y++) {
            for (int x = 0;x<cropSize;x++) {
                SCNVector3 vec = vecs[((stop+y)*windowSize)+(x+sleft)];
                if (vec.z>minDepth&&vec.z<maxDepth) {
                    newMidPoint = vectorAdd(newMidPoint, vec);
                    points++;
                    minZ = vec.z<minZ?vec.z:minZ;
                    maxZ = vec.z>maxZ?vec.z:maxZ;
                }
                
            }
        }
        newMidPoint = SCNVector3Make(newMidPoint.x/points, newMidPoint.y/points, newMidPoint.z/points);

        
        for (int y = 0;y<cropSize;y++) {
            for (int x = 0;x<cropSize;x++) {
                SCNVector3 vec = vecs[((stop+y)*windowSize)+(x+sleft)];
                uint8_t red = 0;
                uint8_t green = 0;
                uint8_t blue = 0;
                if (vec.z>minDepth&&vec.z<maxDepth) {
                    //float normDepth = (vec.z-minDepth)/(largestZ-minDepth);
                    CGFloat distance = lengthOf(vectorSubtract(vec,newMidPoint));
                    float normDistanc = distance/0.1;
                    [self hsv2RGB:normDistanc sat:1.0 val:1.0 red:&red green:&green blue:&blue];
                }
                data[offset++]= red;
                data[offset++]= green;
                data[offset++]= blue;
                
            }
        }
        
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
        CFDataRef rgbData = CFDataCreate(NULL, data, cropSize*cropSize*3);
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
        
        CGImageRef rgbImageRef = CGImageCreate(cropSize, cropSize, 8, 24, cropSize * 3, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
        
        CFRelease(rgbData);
        
        CGDataProviderRelease(provider);
        
        CGColorSpaceRelease(colorspace);
        
        NSImage *videoFrame = [[NSImage alloc]initWithCGImage:rgbImageRef size:NSMakeSize(cropSize, cropSize)];
        _lastHD = videoFrame;
        NSImage *small = [self resizeImage:videoFrame size:croppedSize];
        _depth = small;
        
        CGImageRelease(rgbImageRef);
        
        free(data);
    }
    return _depth;
}



- (NSImage*)resizeImage:(NSImage*)sourceImage size:(NSSize)size
{
    NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
    NSImage*  targetImage = [[NSImage alloc] initWithSize:size];
    
    [targetImage lockFocus];
    
    [sourceImage drawInRect:targetFrame
                   fromRect:NSZeroRect       //portion of source image to draw
                  operation:NSCompositeCopy  //compositing operation
                   fraction:1.0              //alpha (transparency) value
             respectFlipped:YES              //coordinate system
                      hints:@{NSImageHintInterpolation:
                                  [NSNumber numberWithInt:NSImageInterpolationMedium]}];
    
    [targetImage unlockFocus];
    
    return targetImage;
}

-(SCNVector3)world:(float)depth x:(float)x y:(float)y
{
    double fx_d = 1.0 / 5.9421434211923247e+02;
    double fy_d = 1.0 / 5.9104053696870778e+02;
    double cx_d = 3.3930780975300314e+02;
    double cy_d = 2.4273913761751615e+02;
    depth = depth/1000.0;
    SCNVector3 result = SCNVector3Make((float)((x - cx_d) * depth * fx_d), (float)((y - cy_d) * depth * fy_d), (float)(depth));
    return result;
}

-(void)hsv2RGB:(float)h sat:(float)s val:(float)v red:(uint8_t *)r green:(uint8_t *)g blue:(uint8_t *)b
{
    NSColor *col = [NSColor colorWithCalibratedHue:h saturation:s brightness:v alpha:1.0];
    CGFloat red,green,blue,alph;
    [col getRed:&red green:&green blue:&blue alpha:&alph];
    *r = (uint8_t)(red*255);
    *g = (uint8_t)(green*255);
    *b = (uint8_t)(blue*255);
}

-(void)addToTrainingSet:(int)index
{
    NSRect rect = NSMakeRect(0, 0, [_depth size].width, [_depth size].height);
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:[_depth CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil]];
    [newRep setSize:[_depth size]];   // if you want the same resolution
    //NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.25] forKey:NSImageCompressionFactor]; // any number betwwen 0 to 1
    NSData *jpgdata = [newRep representationUsingType:NSJPEGFileType properties:@{}];
    if (picindex%5==0) {
        [jpgdata writeToFile:[[@"~/Developer/signs/validationData" stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%i-%i.jpeg",index,picindex]] atomically:YES];
    } else {
        [jpgdata writeToFile:[[@"~/Developer/signs/trainingData" stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%i-%i.jpeg",index,picindex]] atomically:YES];
    }
    picindex++;
}
-(void)addToTrainingSet:(NSImage *)image atIndex:(int)index
{
    image = [self resizeImage:image size:NSMakeSize(64, 64)];
    NSRect rect = NSMakeRect(0, 0, [image size].width, [image size].height);
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil]];
    [newRep setSize:[image size]];   // if you want the same resolution
    NSData *jpgdata = [newRep representationUsingType:NSJPEGFileType properties:@{}];
    if (picindex%5==0) {
        [jpgdata writeToFile:[[@"~/Developer/signs/validationData" stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%i-%i.jpeg",index,picindex]] atomically:YES];
    } else {
        [jpgdata writeToFile:[[@"~/Developer/signs/trainingData" stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%i-%i.jpeg",index,picindex]] atomically:YES];
    }
    picindex++;
}
-(NSImage *)depthImage
{
    return _depth;
}


#pragma mark - Vector math

SCNVector3 crossProduct(SCNVector3 a, SCNVector3 b)
{
    return SCNVector3Make(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
}

SCNVector3 normalize(SCNVector3 v)
{
    CGFloat len = sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2));
    
    return SCNVector3Make(v.x/len, v.y/len, v.z/len);
}

SCNVector3 vectorSubtract(SCNVector3 a, SCNVector3 b)
{
    return SCNVector3Make(a.x-b.x, a.y-b.y, a.z-b.z);
}

SCNVector3 vectorAdd(SCNVector3 a, SCNVector3 b)
{
    return SCNVector3Make(a.x+b.x, a.y+b.y, a.z+b.z);
}

CGFloat lengthOf(SCNVector3 v)
{
    CGFloat len = sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2));
    return len;
}

@end
