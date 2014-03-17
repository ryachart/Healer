//
//  MyCocos2DClass.m
//  Healer
//
//  Created by Ryan Hart on 3/16/14.
//  Copyright 2014 Ryan Hart Games. All rights reserved.
//

#import "IconDescriptionTableCellSprite.h"
#import "CCLabelTTFShadow.h"

@interface IconDescriptionTableCellSprite ()
@property (nonatomic, assign) CCLabelTTFShadow *titleLabel;
@property (nonatomic, assign) CCLabelTTFShadow *descriptionLabel;
@property (nonatomic, assign) CCSprite *background;
@property (nonatomic, assign) CCSprite *itemSprite;
@end


@implementation IconDescriptionTableCellSprite

- (id)initWithIconSpriteFrameName:(NSString *)spriteFrameName title:(NSString*)title description:(NSString *)description
{
    if (self = [super init]) {
        self.background = [CCSprite spriteWithSpriteFrameName:@"icon_card_back.png"];
        [self addChild:self.background];
        
        self.itemSprite = [CCSprite spriteWithSpriteFrameName:spriteFrameName];
        [self.itemSprite setPosition:CGPointMake(52, 51)];
        [self.background addChild:self.itemSprite];
        
        self.titleLabel = [CCLabelTTFShadow labelWithString:title dimensions:CGSizeMake(300, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        self.titleLabel.position = CGPointMake(52, 26);
        self.titleLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.titleLabel];
        
        self.descriptionLabel = [CCLabelTTFShadow labelWithString:description dimensions:CGSizeMake(300, 40) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        self.descriptionLabel.position = CGPointMake(52, 8);
        self.descriptionLabel.shadowOffset = CGPointMake(-1, -1);
        [self addChild:self.descriptionLabel];
    }
    return self;
}
@end
