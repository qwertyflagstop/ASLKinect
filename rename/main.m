//
//  main.m
//  rename
//
//  Created by Nicholas Peretti on 4/23/16.
//  Copyright © 2016 qwertyflagstop. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        for (int i = 0; i<2; i++) {
            
        
        NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *dirContents;
            if (i==0) {
                dirContents = [fm contentsOfDirectoryAtPath:[@"~/Developer/signs/trainingData" stringByExpandingTildeInPath] error:nil];
            } else {
                dirContents = [fm contentsOfDirectoryAtPath:[@"~/Developer/signs/validationData" stringByExpandingTildeInPath] error:nil];

            }
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpeg'"];
        NSArray *onlyJPGs = [dirContents filteredArrayUsingPredicate:fltr];
        NSString *labelsString = @"";
        for (NSString *s in onlyJPGs) {
            int categor = [[s lastPathComponent] characterAtIndex:0] - 48;
            NSString *entry = [NSString stringWithFormat:@"%@ %i\n",s,categor];
            labelsString = [labelsString stringByAppendingString:entry];
        }
            if (i==0) {
                [labelsString writeToFile:[[@"~/Developer/signs" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"train.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            } else {
                [labelsString writeToFile:[[@"~/Developer/signs" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"val.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
    }
    return 0;
}
