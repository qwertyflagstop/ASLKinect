//
//  AppDelegate.m
//  KinnectiveC
//
//  Created by Nicholas Peretti on 3/30/16.
//  Copyright © 2016 qwertyflagstop. All rights reserved.
//

#import "AppDelegate.h"
#import "WorlController.h"
#import <SceneKit/SceneKit.h>
#import <libfreenect_sync.h>
#import <SpriteKit/SpriteKit.h>
#import <DeepBelief/DeepBelief.h>

@interface AppDelegate ()
{
   
}

@property (strong) WorldScene *scene;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
   
    WorlController *wc = [[WorlController alloc]initWithFrame:self.worldWindow.frame];
    [self.worldWindow.contentView addSubview:wc.view];
    [wc setUpFloor];
    
}




- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


-(void)updateImage
{
    
    uint16_t *depthData = malloc(sizeof(uint16_t)*(640*480));
    unsigned int timestampDepth;
    freenect_sync_get_depth_with_res((void**)(&depthData), &timestampDepth, 0, FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_MM);
    int min = 200;
    int max = 5000;
    uint8 *depthImageData = malloc(sizeof(uint8)*(640*480)*3);
    for(int i = 0;i<640*480;i++)
    {
        
        if (depthData[i]<min||depthData[i]>max) {
            
            //hsv2rgb(0, 0, 0, &depthImageData[i*3],  &depthImageData[i*3+1],  &depthImageData[i*3+2]);
        } else {
            
            float depth = 0.5*(sin(((float)depthData[i]*0.01))+1);
            //hsv2rgb(depth, 0.9, 1, &depthImageData[i*3],  &depthImageData[i*3+1],  &depthImageData[i*3+2]);
            [self hsv2RGB:depth sat:0.9 val:1.0 red:&depthImageData[i*3] green:&depthImageData[i*3+1] blue:&depthImageData[i*3+2]];
        }
    }
    CFDataRef depthImageDataRef = CFDataCreate(NULL, depthImageData, 640*480*3);
    CGDataProviderRef greyProvider = CGDataProviderCreateWithCFData(depthImageDataRef);
    CGColorSpaceRef greyRef = CGColorSpaceCreateDeviceRGB();
    CGImageRef greyImageRef = CGImageCreate(640, 480, 8, 24, 640 * 3, greyRef, kCGBitmapByteOrderDefault, greyProvider, NULL, true, kCGRenderingIntentDefault);
    CFRelease(depthImageDataRef);
    CGDataProviderRelease(greyProvider);
    CGColorSpaceRelease(greyRef);
    NSImage *greyFrame = [[NSImage alloc]initWithCGImage:greyImageRef size:NSMakeSize(640, 480)];
    //[self.depthImageView setImage:greyFrame];
    CGImageRelease(greyImageRef);
    
    
    
    
    UInt8 *data;
    unsigned int timestamp;
    
    freenect_sync_get_video_with_res((void**)(&data), &timestamp, 0, FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB);
      CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CFDataRef rgbData = CFDataCreate(NULL, data, 640*480*3);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
    
    CGImageRef rgbImageRef = CGImageCreate(640, 480, 8, 24, 640 * 3, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    
    CFRelease(rgbData);
    
    CGDataProviderRelease(provider);
    
    CGColorSpaceRelease(colorspace);
    
    // use the created CGImage
    NSImage *videoFrame = [[NSImage alloc]initWithCGImage:rgbImageRef size:NSMakeSize(640, 480)];
    
    [self.imageView setImage:videoFrame];
    
    CGImageRelease(rgbImageRef);
    
    [self performSelectorOnMainThread:@selector(updateImage) withObject:nil waitUntilDone:NO];
    
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
