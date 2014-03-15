//
//  RaidMemberPreBattleCard.m
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//

#import "RaidMemberPreBattleCard.h"
#import "RaidMember.h"
#import "PlayerDataManager.h"

@interface RaidMemberPreBattleCard ()
@property (nonatomic, retain) RaidMember *raidMember;
@property (readwrite) NSInteger count;
@end


@implementation RaidMemberPreBattleCard
- (void)dealloc {
    [_raidMember release];
    [super dealloc];
}

-(id)initWithFrame:(CGRect)frame count:(NSInteger)cnt andRaidMember:(RaidMember *)member{
    if (self = [super initWithSpriteFrameName:@"roster_bg.png"]){
        self.raidMember = member;
        self.count = cnt;
        self.contentSize = frame.size;
        self.position = frame.origin;
        self.anchorPoint = CGPointZero;
        
        
        CCLabelTTF *descLabel = [CCLabelTTF labelWithString:self.raidMember.info dimensions:CGSizeMake(98, 80) hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS" fontSize:10.0f];
        [descLabel setPosition:ccp(154, -2)];
        [self addChild:descLabel];
        
        CCLabelTTF *classNameLabel = [CCLabelTTF labelWithString:self.raidMember.title dimensions:CGSizeMake(80, 25) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:16];
        [classNameLabel setPosition:ccp(78, 48)];
        [self addChild:classNameLabel];
        
        CCLabelTTF *healthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i HP", (int)round(self.raidMember.maximumHealth * (1 + [PlayerDataManager localPlayer].allyHealthUpgrades * .01))] dimensions:CGSizeMake(120, 25) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0f];
        [healthLabel setPosition:ccp(98, 28)];
        [self addChild:healthLabel];
        
        CCLabelTTF *DPSLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i DPS", (int)self.raidMember.dps] dimensions:CGSizeMake(120, 25) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:14.0];
        [DPSLabel setPosition:ccp(98, 12)];
        [self addChild:DPSLabel];
        
        NSString* classIconSpriteFrameName = [NSString stringWithFormat:@"class_icon_%@.png", [member title].lowercaseString];
        CCSprite *classIcon = [CCSprite spriteWithSpriteFrameName:classIconSpriteFrameName];
        [classIcon setPosition:ccp(20, 34)];
        [self addChild:classIcon];
        
        CCLabelTTF *countLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"x%i", self.count] dimensions:CGSizeMake(50, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:16.0f];
        [countLabel setPosition:ccp(206, 38)];
        [self addChild:countLabel];
    }
    return self;
}
@end
