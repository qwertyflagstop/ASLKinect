//
//  WorldScene.m
//  KinnectiveC
//
//  Created by Nicholas Peretti on 4/1/16.
//  Copyright © 2016 qwertyflagstop. All rights reserved.
//


#import "WorldScene.h"
#import <libfreenect_sync.h>




@implementation WorldScene
{
    SCNNode *_worldNode;
    NSMutableArray *nodes;
    SCNNode *cameraNode;
    SCNNode *depthMap;
    BOOL needsSaving;
    int picIndex;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self.rootNode addChildNode:_worldNode];
        
        needsSaving = NO;
        cameraNode = [SCNNode node];
        cameraNode.camera = [SCNCamera camera];
        cameraNode.camera.xFov = 12;
        cameraNode.camera.yFov = 12;
        cameraNode.camera.zNear = 0;
        cameraNode.camera.zFar = 4;
        cameraNode.position = SCNVector3Make(0, 0, 0);
        [self.rootNode addChildNode:cameraNode];
        
        needsSaving = NO;
        picIndex = 0;
        
        // create and add a light to the scene
        SCNNode *lightNode = [SCNNode node];
        lightNode.light = [SCNLight light];
        lightNode.light.type = SCNLightTypeOmni;
        lightNode.position = SCNVector3Make(0, 10, 10);
        [self.rootNode addChildNode:lightNode];
        
        
        // create and add an ambient light to the scene
        SCNNode *ambientLightNode = [SCNNode node];
        ambientLightNode.light = [SCNLight light];
        ambientLightNode.light.type = SCNLightTypeAmbient;
        ambientLightNode.light.color = [NSColor darkGrayColor];
        [self.rootNode addChildNode:ambientLightNode];
        nodes = [NSMutableArray new];
        
        
        depthMap = [SCNNode node];
        depthMap.position = SCNVector3Make(0, 0, -1);
        [self.rootNode addChildNode:depthMap];
        [self depthMap];
    }
    return self;
}


-(void)depthMap
{
    
    
    //    uint16_t *depthData = malloc(sizeof(uint16_t)*(640*480));
    //    unsigned int timestampDepth;
    //    freenect_sync_get_depth_with_res((void**)(&depthData), &timestampDepth, 0, FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_MM);
    //    int width = 240;
    //    int height = 240;
    //    int skip = 1;
    //    NSMutableArray *vectors = [[NSMutableArray alloc]init];
    //    NSMutableArray *lines = [[NSMutableArray alloc]init];
    //    BOOL nextTo = NO;
    //    for (int x = 320-width/2; x<320+width/2; x+=skip) {
    //        nextTo = NO;
    //        for (int y = 240-height/2; y<240+height/2; y+=skip) {
    //            float depth = depthData[y*640+x];
    //                if (depth<500||depth>1000) {
    //                    nextTo = NO;
    //                } else {
    //                    SCNVector3 vec = [self world:-depth x:x y:y];
    //                    [vectors addObject:[NSValue valueWithSCNVector3:vec]];
    //                    if (nextTo) {
    //                        [lines addObject:@[@(vectors.count-2),@(vectors.count-1)]];
    //                    } else {
    //                        nextTo = YES;
    //                    }
    //                }
    //        }
    //    }
    //    SCNVector3 vecData[vectors.count];
    //    int order[lines.count*2];
    //    for (int i = 0; i<lines.count; i++) {
    //        order[i*2] = [lines[i][0] intValue];
    //        order[i*2+1] = [lines[i][1] intValue];
    //    }
    //    for (int i = 0; i<vectors.count; i++) {
    //        vecData[i]=[vectors[i] SCNVector3Value];
    //    }
    //    SCNGeometrySource *sr = [SCNGeometrySource geometrySourceWithVertices:vecData count:vectors.count];
    //    SCNGeometryElement *el = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:order length:sizeof(order)] primitiveType:SCNGeometryPrimitiveTypeLine primitiveCount:lines.count bytesPerIndex:sizeof(int)];
    //    depthMap.geometry = [SCNGeometry geometryWithSources:@[sr] elements:@[el]];
    //    depthMap.geometry.firstMaterial.diffuse.contents = [NSColor redColor];
    //
    //    [self performSelectorOnMainThread:@selector(depthMap) withObject:nil waitUntilDone:NO];
    //
    int windowSize = 480;
    float minDepth = 0.4;
    float maxDepth = 0.75;
    uint16_t *depthData = malloc(sizeof(uint16_t)*(640*480));
    unsigned int timestampDepth;
    freenect_sync_get_depth_with_res((void**)(&depthData), &timestampDepth, 0, FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_MM);
    SCNVector3 vecs[windowSize*windowSize];
    float smallestZ = 99999999;
    float largestZ = 0;
    int left = 320-(windowSize/2);
    int top = 240-(windowSize/2);
    int totalx = 0;
    int totaly = 0;
    int points = 0;
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
            }
        }
    }

    int cropSize = 256;
    UInt8 *data = malloc(cropSize*cropSize*3);
    if (points>0) {
        
        int offset = 0;
        int averagX = totalx/points;
        int averageY = totaly/points;
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
        
        
        for (int y = 0;y<cropSize;y++) {
            for (int x = 0;x<cropSize;x++) {
                SCNVector3 vec = vecs[((stop+y)*windowSize)+(x+sleft)];
                if (vec.z>minDepth&&vec.z<maxDepth) {
                    totalx+=x;
                    totaly+=y;
                    points++;
                    if (vec.z<smallestZ) {
                        smallestZ = vec.z;
                    }
                    if (vec.z>largestZ) {
                        largestZ = vec.z;
                    }
                }
                
            }
        }
        
        
        for (int y = 0;y<cropSize;y++) {
            for (int x = 0;x<cropSize;x++) {
                SCNVector3 vec = vecs[((stop+y)*windowSize)+(x+sleft)];
                uint8_t red = 0;
                uint8_t green = 0;
                uint8_t blue = 0;
                if (vec.z>minDepth&&vec.z<maxDepth) {
                    float normDepth = (vec.z-smallestZ)/(largestZ-smallestZ);
                    [self hsv2RGB:normDepth sat:0.8 val:normDepth*0.5+0.5 red:&red green:&green blue:&blue];
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
        self.background.contents = videoFrame;
        NSImage *small = [self resizeImage:videoFrame size:NSMakeSize(64, 64)];
        
        
        if (needsSaving) {
            needsSaving = NO;
            NSRect rect = NSMakeRect(0, 0, 64, 64);
            NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:[small CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil]];
            [newRep setSize:[videoFrame size]];   // if you want the same resolution
            //NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.25] forKey:NSImageCompressionFactor]; // any number betwwen 0 to 1
            NSData *jpgdata = [newRep representationUsingType:NSJPEGFileType properties:@{}];
            if (picIndex%5==0) {
                [jpgdata writeToFile:[[@"~/Developer/signs/validationData" stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"2-%i.jpeg",picIndex]] atomically:YES];
            } else {
                [jpgdata writeToFile:[[@"~/Developer/signs/trainingData" stringByExpandingTildeInPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"2-%i.jpeg",picIndex]] atomically:YES];
            }
            picIndex++;
        }
        
        CGImageRelease(rgbImageRef);
        
        free(data);
    }
    
    [self performSelectorOnMainThread:@selector(depthMap) withObject:nil waitUntilDone:NO];
    
}

- (NSImage*) resizeImage:(NSImage*)sourceImage size:(NSSize)size
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


- (void)keyDown:(NSEvent *)event {
    needsSaving = YES;
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



@end
