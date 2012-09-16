//
//  Slot.m
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "Slot.h"

#define DEFAULT_INHABITANT_Z 0

@interface Slot ()
@property (nonatomic, assign) CCLabelTTF *titleLabel;
@property (nonatomic, assign) CCLabelTTF *accessoryLabel;
@end

@implementation Slot

- (void)dealloc{
    [_inhabitant release];
    [_title release];
    [_accessoryTitle release];
    [super dealloc];
}

- (id)initWithInhabitantOrNil:(CCSprite*)inhabitant{
    if (self = [super initWithSpriteFrameName:@"spell_icon_back.png"]){
        self.inhabitant = inhabitant;
        
        [self configureInhabitant];
        
        self.titleLabel = [CCLabelTTF labelWithString:nil dimensions:CGSizeMake(self.contentSize.width, 40) alignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:16.0];
        [self.titleLabel setPosition:CGPointMake(self.contentSize.width / 2, -20)];
        [self addChild:self.titleLabel];
        
        self.accessoryLabel = [CCLabelTTF labelWithString:nil dimensions:CGSizeMake(140, 70) alignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.accessoryLabel setPosition:CGPointMake(self.contentSize.width * 1.75, self.contentSize.height / 2 - 10)];
        [self addChild:self.accessoryLabel];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    [_title release];
    _title = [title retain];
    [self.titleLabel setString:title];
}

- (void)setAccessoryTitle:(NSString *)accessoryTitle {
    [_accessoryTitle release];
    _accessoryTitle = [accessoryTitle retain];
    [self.accessoryLabel setString:accessoryTitle];
}

- (void)setDefaultInhabitant:(CCSprite *)defaultInhabitant {
    if (_defaultInhabitant){
        [_defaultInhabitant removeFromParentAndCleanup:YES];
    }
    [_defaultInhabitant release];
    _defaultInhabitant = [defaultInhabitant retain];
    
    [_defaultInhabitant setAnchorPoint:CGPointZero];
    [self addChild:defaultInhabitant z:DEFAULT_INHABITANT_Z];
    [_defaultInhabitant setOpacity:50];
}

- (void)configureInhabitant {
    if (!self.inhabitant){
        return;
    }
    [self.inhabitant setAnchorPoint:CGPointZero];
    [self.inhabitant setPosition:CGPointZero];
    [self addChild:self.inhabitant z:DEFAULT_INHABITANT_Z + 5];
}

- (BOOL)canDropIntoSlotFromRect:(CGRect)candidateRect {
    if (CGRectIntersectsRect(self.boundingBox, candidateRect)){
        if (!self.inhabitant){
            return YES;
        }
    }
    return NO;
}

- (void)dropInhabitant:(CCSprite *)inhabitant {
    if (self.inhabitant == nil){
        [self.inhabitant removeFromParentAndCleanup:YES];
    }
    
    self.inhabitant = inhabitant;
    [self configureInhabitant];
}

- (CCSprite *)inhabitantRemovedForDragging {
    if (!self.inhabitant){
        return nil;
    }
    
    [self.inhabitant removeFromParentAndCleanup:YES];
    CCSprite *inhabitant = [self.inhabitant retain];
    self.inhabitant = nil;
    return [inhabitant autorelease];
}
@end
