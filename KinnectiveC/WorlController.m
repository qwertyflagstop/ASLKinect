//
//  WorlController.m
//  KinnectiveC
//
//  Created by Nicholas Peretti on 4/1/16.
//  Copyright © 2016 qwertyflagstop. All rights reserved.
//
#import "WorlController.h"
#import <libfreenect_sync.h>
#import "WorldScene.h"


@interface WorlController ()
{
    NSRect _frame;
}

@end




@implementation WorlController

- (void)awakeFromNib {
    [super viewDidLoad];

}

-(instancetype)initWithFrame:(NSRect)frame;
{
    self = [super init];
    if (self) {
        _frame = frame;
        self.gameView = [[WorldView alloc]initWithFrame:_frame];
    }
    return self;
}

-(void)loadView
{
    self.view = [[NSView alloc]initWithFrame:_frame];
}

-(void)setUpFloor
{
    
    // create a new scene
    self.wScene = [[WorldScene alloc]init];
    [self.view addSubview:self.gameView];
    
    
    // set the scene to the view
    self.gameView.scene = self.wScene;
    
    // allows the user to manipulate the camera
    self.gameView.allowsCameraControl = YES;
    
    // show statistics such as fps and timing information
    self.gameView.showsStatistics = YES;
    
    // configure the view
    self.gameView.backgroundColor = [NSColor whiteColor];
    
    

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

-(void)keyDown:(NSEvent *)theEvent
{
    [self.wScene keyDown:theEvent];
}

@end
