//
//  SellDropSprite.m
//  Healer
//
//  Created by Ryan Hart on 5/27/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "SellDropSprite.h"
#import "CCLabelTTFShadow.h"

@implementation SellDropSprite

- (id)init
{
    if (self = [super initWithSpriteFrameName:@"spell_info_node_bg.png"]) {
        CCLabelTTFShadow *title = [CCLabelTTFShadow labelWithString:@"Sell" dimensions:CGSizeMake(self.contentSize.width, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        title.position = CGPointMake(self.contentSize.width / 2 + 10, self.contentSize.height - title.contentSize.height / 4);
        [self addChild:title];
        
        CCLabelTTFShadow *dropToSell = [CCLabelTTFShadow labelWithString:@"Drop items to sell" dimensions:self.contentSize hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        [dropToSell setPosition:CGPointMake(self.contentSize.width / 2, 10)];
        [dropToSell setOpacity:125];
        [self addChild:dropToSell];
    }
    return self;
}

@end
