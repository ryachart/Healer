//
//  Slot.h
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "CCSprite.h"

@interface Slot : CCSprite
@property (nonatomic, retain) CCSprite *inhabitant;

- (BOOL)canDropIntoSlotFromRect:(CGRect)candidateRect;
@end
