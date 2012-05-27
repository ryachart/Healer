//
//  SpellInfoNode.m
//  Healer
//
//  Created by Ryan Hart on 4/27/12.
//

#import "SpellInfoNode.h"
#import "Spell.h"

@implementation SpellInfoNode
-(id)initWithSpell:(Spell*)spell{
    if (self = [super init]){
        CCLayerColor *spellIcon = [CCLayerColor layerWithColor:ccc4(255, 0, 0, 255)];
        [spellIcon setContentSize:CGSizeMake(100, 100)];
        //[spellIcon setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .7, 530 - (105 * i))];
        
        CCLabelTTF *spellNamePH = [CCLabelTTF labelWithString:spell.title dimensions:CGSizeMake(100, 100) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24.0];
        [spellNamePH setPosition:ccp(50,50)];
        [spellIcon addChild:spellNamePH];
        
        CCLayerColor *spellDetailsBackground = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255)];
        [spellDetailsBackground setContentSize:CGSizeMake(200, 100)];
        [spellDetailsBackground setPosition:CGPointMake(100,0)];
        [self addChild:spellIcon];
        
        CCLabelTTF *spellDetailsLabel = [CCLabelTTF labelWithString:spell.info dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellDetailsLabel setColor:ccBLACK];
        [spellDetailsLabel setPosition:ccp(102,14)];
        
        CCLabelTTF *spellCostLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost: %i", spell.energyCost] dimensions:CGSizeMake(200, 20) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellCostLabel setColor:ccBLACK];
        [spellCostLabel setPosition:ccp(102, 86)];
        
        CCLabelTTF *spellCastTimeLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cast Time: %1.2f", spell.castTime] dimensions:CGSizeMake(200, 20) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellCastTimeLabel setColor:ccBLACK];
        [spellCastTimeLabel setPosition:ccp(102, 70)];
        
        CCLabelTTF *spellCooldownLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f", spell.cooldown] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
        [spellCooldownLabel setColor:ccBLACK];
        [spellCooldownLabel setPosition:ccp(102, 44)];
        
        [self addChild:spellDetailsBackground];
        [spellDetailsBackground addChild:   spellDetailsLabel];
        [spellDetailsBackground addChild:   spellCostLabel];
        [spellDetailsBackground addChild:   spellCastTimeLabel];
        [spellDetailsBackground addChild:   spellCooldownLabel];
        
    }
    return self;
}
@end
