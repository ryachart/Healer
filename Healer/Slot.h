//
//  Slot.h
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@class Slot;
@protocol SlotDelegate  <NSObject>
- (void)slotDidEmpty:(Slot*)slot;
@end

@interface Slot : CCSprite
@property (nonatomic, retain) CCSprite *inhabitant;
@property (nonatomic, retain) CCSprite *defaultInhabitant;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *accessoryTitle;

- (id)initWithInhabitantOrNil:(CCSprite*)inhabitant;
- (BOOL)canDropIntoSlotFromRect:(CGRect)candidateRect;
- (void)dropInhabitant:(CCSprite*)inhabitant;
- (CCSprite *)inhabitantRemovedForDragging;
@end
