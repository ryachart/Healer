//
//  CCShakeScreen.m
//  Healer
//
//  Created by Ryan Hart on 4/1/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCShakeScreen.h"
@interface CCShakeScreen ()
@property (nonatomic, readwrite) CGPoint initialPosition;
@end

@implementation CCShakeScreen
@synthesize initialPosition;

-(void)update:(ccTime)time{
    if (firstTick_){
        self.initialPosition = [target_ position];
        firstTick_ = NO;
    }
    int xJitter = ((duration_ - elapsed_)/duration_) * (arc4random() % 8) - 4;
    int yJitter = ((duration_ - elapsed_)/duration_) * (arc4random() % 8) - 4;
    
    int curX = self.initialPosition.x + xJitter;
    int curY = self.initialPosition.y + yJitter;
    
    [target_ setPosition:ccp(curX, curY)];
}
@end
