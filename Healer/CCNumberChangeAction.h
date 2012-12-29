//
//  CCNumberChangeAction.h
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface CCNumberChangeAction : CCActionInterval
@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *suffix;
+ (CCNumberChangeAction*)actionWithDuration:(NSTimeInterval)duration fromNumber:(NSInteger)start toNumber:(NSInteger)finishNumber;
@end
