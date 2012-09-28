//
//  RaidMemberPreBattleCard.m
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//

#import "RaidMemberPreBattleCard.h"
#import "RaidMember.h"

@interface RaidMemberPreBattleCard ()
@property (nonatomic, retain) RaidMember *raidMember;
@property (readwrite) NSInteger count;
@end


@implementation RaidMemberPreBattleCard
@synthesize count, raidMember;
-(id)initWithFrame:(CGRect)frame count:(NSInteger)cnt andRaidMember:(RaidMember *)member{
    if (self = [super initWithColor:ccc4(255, 255, 255, 255)]){
        self.raidMember = member;
        self.count = cnt;
        self.contentSize = frame.size;
        self.position = frame.origin;
        
        CCLayerColor *countBackground = [CCLayerColor layerWithColor:ccc4(130, 130, 130, 255)];
        [countBackground setPosition:ccp(0, 0)];
        [countBackground setContentSize:CGSizeMake(100, 100)];
        [self addChild:countBackground];
        
        CCLayerColor *detailBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
        [detailBackground setPosition: ccp(100, 0)];
        [detailBackground setContentSize:CGSizeMake(200, 100)];
        [self addChild:detailBackground];
        
        CCLabelTTF *healthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Health: %i", raidMember.maximumHealth] dimensions:CGSizeMake(200, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
        [healthLabel setColor:ccBLACK];
        [healthLabel setPosition:ccp(100, 78)];
        [detailBackground addChild:healthLabel];
        
        CCLabelTTF *DPSLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"DPS: %1.2f", raidMember.dps] dimensions:CGSizeMake(200, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
        [DPSLabel setColor:ccBLACK];
        [DPSLabel setPosition:ccp(100, 58)];
        [detailBackground addChild:DPSLabel];
        
        CCLabelTTF *descLabel = [CCLabelTTF labelWithString:self.raidMember.info dimensions:CGSizeMake(200, 80) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:12];
        [descLabel setColor:ccBLACK];
        [descLabel setPosition:ccp(100, 20)];
        [detailBackground addChild:descLabel];
        
        CCLabelTTF *classNameLabel = [CCLabelTTF labelWithString:self.raidMember.title dimensions:CGSizeMake(95, 48) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:16];
        [classNameLabel setPosition:ccp(50, 78)];
        [countBackground addChild:classNameLabel];
        
        CCLabelTTF *countLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", count] dimensions:CGSizeMake(50, 50) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
        [countLabel setPosition:ccp(50, 24)];
        [countBackground addChild:countLabel];
    }
    return self;
}

- (void)dealloc {
    [raidMember release];
    [super dealloc];
}
@end
