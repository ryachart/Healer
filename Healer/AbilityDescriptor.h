//
//  AbilityDescriptor.h
//  Healer
//
//  Created by Ryan Hart on 8/1/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

@class Effect;

@interface AbilityDescriptor : NSObject
@property (nonatomic, retain) NSString* abilityName;
@property (nonatomic, retain) NSString* iconName;
@property (nonatomic, retain) NSString* abilityDescription;
@property (nonatomic, assign) Effect *monitoredEffect;
- (NSInteger)stacks;
@end
