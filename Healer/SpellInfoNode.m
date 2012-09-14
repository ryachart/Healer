//
//  SpellInfoNode.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "SpellInfoNode.h"
#import "Spell.h"

@interface SpellInfoNode ()
@property (nonatomic, assign) CCSprite *spellIcon;
@end

@implementation SpellInfoNode
-(id)initWithSpell:(Spell*)spell{
    if (self = [super init]){
        self.spellIcon = [CCSprite spriteWithSpriteFrameName:@"unknown-icon.png"];
        [self.spellIcon setAnchorPoint:CGPointZero];
        CCSpriteFrame *spellSpriteFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[spell spriteFrameName]];
        if (spellSpriteFrame){
            [self.spellIcon setDisplayFrame:spellSpriteFrame];
        }
        //[spellIcon setPosition:CGPointMake(0,0)];
        
        CCLabelTTF *spellNamePH = [CCLabelTTF labelWithString:spell.title dimensions:CGSizeMake(100, 100) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24.0];
        [spellNamePH setPosition:ccp(50,50)];
        [spellNamePH setColor:ccBLACK];
        [self.spellIcon addChild:spellNamePH];
        [self addChild:self.spellIcon];

        CCLayerColor *spellDetailsBackground = [CCLayerColor layerWithColor:ccc4(120, 120, 120, 255)];
        [spellDetailsBackground setContentSize:CGSizeMake(200, 100)];
        [spellDetailsBackground setPosition:CGPointMake(100,0)];
        
        CCLabelTTF *spellDetailsLabel = [CCLabelTTF labelWithString:spell.info dimensions:CGSizeMake(200, 70) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellDetailsLabel setColor:ccBLACK];
        [spellDetailsLabel setPosition:ccp(102,38)];
        
        CCLabelTTF *spellCastTimeLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cast Time: %1.2f", spell.castTime] dimensions:CGSizeMake(200, 20) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellCastTimeLabel setColor:ccBLACK];
        [spellCastTimeLabel setPosition:ccp(102, 90)];
        
        CCLabelTTF *spellCooldownLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f", spell.cooldown] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellCooldownLabel setColor:ccBLACK];
        [spellCooldownLabel setPosition:ccp(102, 66)];
        
        [self addChild:spellDetailsBackground];
        [spellDetailsBackground addChild:   spellDetailsLabel];
        [spellDetailsBackground addChild:   spellCastTimeLabel];
        [spellDetailsBackground addChild:   spellCooldownLabel];
        
    }
    return self;
}
@end
