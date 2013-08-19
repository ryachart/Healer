//
//  Slot.m
//  Healer
//
//  Created by Ryan Hart on 9/13/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "Slot.h"
#import "CCLabelTTFShadow.h"

#define DEFAULT_INHABITANT_Z 0

@interface Slot ()
@property (nonatomic, assign) CCLabelTTFShadow *titleLabel;
@property (nonatomic, assign) CCLabelTTFShadow *accessoryLabel;
@property (nonatomic, assign) CCSprite *lockedSprite;
@property (nonatomic, readwrite) CCSprite *selectedSprite;
@end

@implementation Slot

- (void)dealloc{
    [_inhabitant release];
    [_title release];
    [_accessoryTitle release];
    [super dealloc];
}

- (id)initWithSpriteFrameName:(NSString*)spriteFrameName andInhabitantOrNil:(CCSprite*)inhabitant{
    if (self = [super initWithSpriteFrameName:spriteFrameName]){
        self.selectedSprite = [CCSprite spriteWithSpriteFrameName:@"spell_icon_selected.png"];
        self.selectedSprite.position = CGPointMake(self.contentSize.width/2, self.contentSize.height/2);
        [self.selectedSprite setVisible:NO];
        [self addChild:self.selectedSprite z:-1];
        self.selectionColor = ccYELLOW;
        
        self.inhabitant = inhabitant;
        
        [self configureInhabitant];
        
        self.titleLabel = [CCLabelTTFShadow    labelWithString:nil dimensions:CGSizeMake(self.contentSize.width, 40) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:16.0];
        [self.titleLabel setPosition:CGPointMake(self.contentSize.width / 2, -20)];
        [self addChild:self.titleLabel];
        
        self.accessoryLabel = [CCLabelTTFShadow labelWithString:nil dimensions:CGSizeMake(140, 70) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.accessoryLabel setPosition:CGPointMake(self.contentSize.width * 1.75, self.contentSize.height / 2 - 10)];
        [self addChild:self.accessoryLabel];
        
        self.lockedSprite = [CCSprite spriteWithSpriteFrameName:@"lock.png"];
        [self.lockedSprite setScale:1.33];
        [self.lockedSprite setPosition:CGPointMake(self.contentSize.width / 2, self.contentSize.height / 2)];
        [self.lockedSprite setVisible:NO];
        [self addChild:self.lockedSprite];
    }
    return self;
}

- (void)setIsLocked:(BOOL)isLocked
{
    _isLocked = isLocked;
    self.lockedSprite.visible = _isLocked;
}

- (void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    self.selectedSprite.visible = isSelected;
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
        if (!self.inhabitant && !self.isLocked){
            return YES;
        }
    }
    return NO;
}

- (void)dropInhabitant:(CCSprite *)inhabitant {
    if (inhabitant == nil){
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

- (void)setTitleColor:(ccColor3B)titleColor
{
    _titleColor = titleColor;
    self.titleLabel.color = titleColor;
}

- (void)setSelectionColor:(ccColor3B)selectionColor
{
    _selectionColor = selectionColor;
    self.selectedSprite.color = selectionColor;
}
@end
