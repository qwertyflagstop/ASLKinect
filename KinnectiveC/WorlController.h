//
//  WorlController.h
//  KinnectiveC
//
//  Created by Nicholas Peretti on 4/1/16.
//  Copyright © 2016 qwertyflagstop. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WorldView.h"
#import "WorldScene.h"

@interface WorlController : NSViewController

@property (nonatomic,strong) WorldView *gameView;
@property (nonatomic,strong) WorldScene *wScene;
-(instancetype)initWithFrame:(NSRect)frame;
-(void)setUpFloor;


@end
