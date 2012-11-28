//
//  CCNumberChangeAction.m
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCNumberChangeAction.h"

@interface CCNumberChangeAction ()
@property (nonatomic, readwrite) NSInteger startNumber;
@property (nonatomic, readwrite) NSInteger finishNumber;
@property (nonatomic, readwrite) ccTime elapsed;
@end

@implementation CCNumberChangeAction

- (void)dealloc
{
    [_prefix release];
    [_suffix release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.elapsed = 0.0;
    }
    return self;
}

+ (CCNumberChangeAction*)actionWithDuration:(NSTimeInterval)duration fromNumber:(NSInteger)start toNumber:(NSInteger)finish
{
    CCNumberChangeAction *action = [CCNumberChangeAction action];
    [action setDuration:duration];
    [action setStartNumber:start];
    [action setFinishNumber:finish];
    return action;
}

- (void)update:(ccTime)time
{
    [super update:time];
    self.elapsed += time;
    float percentElapsed = MIN(duration_,self.elapsed) / duration_;
    
    NSInteger targetNumber = (self.finishNumber - self.startNumber) * percentElapsed;
    
    CCLabelTTF *targetLabel = (CCLabelTTF *)self.target;
    [targetLabel setString:[NSString stringWithFormat:@"%@%i%@", self.prefix ? self.prefix : @"", targetNumber, self.suffix ? self.suffix : @""]];
}

- (void)startWithTarget:(id)target
{
    NSAssert([target isKindOfClass:[CCLabelTTF class]], @"Attempt to run a CCNumberChangeAction on Not a Label");
    [super startWithTarget:target];
}

@end