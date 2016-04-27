//
//  WorldScene.h
//  KinnectiveC
//
//  Created by Nicholas Peretti on 4/1/16.
//  Copyright © 2016 qwertyflagstop. All rights reserved.
//

#import <SceneKit/SceneKit.h>


@interface WorldScene : SCNScene 

-(void)depthMap;

-(void)keyDown:(NSEvent *)theEvent;


@end
