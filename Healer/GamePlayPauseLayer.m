//
//  GamePlayPauseLayer.m
//  Healer
//
//  Created by Ryan Hart on 3/31/12.
//

#import "GamePlayPauseLayer.h"
#import "Encounter.h"
#import "Enemy.h"
#import "IconDescriptionTableCellSprite.h"
#import "AbilityDescriptor.h"
#import "CCLabelTTFShadow.h"

@interface GamePlayPauseLayer ()
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, assign) CCTableView *bossAbilityTableView;

@end

@implementation GamePlayPauseLayer
- (id)initWithDelegate:(id)delegate encounter:(Encounter*)encounter {
    if (self = [super initWithColor:ccc4(0, 0, 0, 0)]){
        self.delegate = delegate;
        self.encounter = encounter;
        
        CCLabelTTFShadow *paused = [CCLabelTTF labelWithString:@"Paused" fontName:@"Marion-Bold" fontSize:IS_IPAD ? 64.0 : 36.0];
        [paused setPosition: IS_IPAD ? CGPointMake(512, 670) : CGPointMake(160, SCREEN_HEIGHT - 50)];
        [self addChild:paused];
        
        CCLabelTTFShadow *closeLabel = [CCLabelTTF labelWithString:@"Resume" fontName:@"TrebuchetMS-Bold" fontSize:IS_IPAD ? 48.0 : 28.0];
        CCLabelTTFShadow *quitLabel = [CCLabelTTF labelWithString:@"Escape" fontName:@"TrebuchetMS-Bold" fontSize:IS_IPAD ? 48.0 : 28.0];
        CCLabelTTFShadow *restartLabel = [CCLabelTTF labelWithString:@"Restart" fontName:@"TrebuchetMS-Bold" fontSize:IS_IPAD ? 48.0 : 28.0];
        
        CCMenu *menu = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:closeLabel target:self selector:@selector(close)],
                                            [CCMenuItemLabel itemWithLabel:quitLabel target:self selector:@selector(quit)], nil];
        
        if (IS_IPAD) {
            [menu alignItemsHorizontallyWithPadding:100.0];
        } else {
            [menu alignItemsVerticallyWithPadding:30.0];
            self.bossAbilityTableView = [[[CCTableView alloc] initWithViewSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT / 2.35)] autorelease];
            self.bossAbilityTableView.contentSize = CGSizeMake(SCREEN_WIDTH, 2000);
            [self.bossAbilityTableView setDataSource:self];
            [self.bossAbilityTableView setDelegate:self];
            [self addChild:self.bossAbilityTableView];
        }
        
        [self addChild:menu];
        
        if (IS_POCKET) {
            [menu setPosition:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT - 140)];
            
            CCLabelTTFShadow *abilitiesLabel = [CCLabelTTF labelWithString:@"Boss Abilities" fontName:@"TrebuchetMS-Bold" fontSize:28.0];
            abilitiesLabel.position = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 290);
            abilitiesLabel.color = ccRED;
            [self addChild:abilitiesLabel];
            
        }
        
        CCMenu *restartMenu = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:restartLabel target:self selector:@selector(restart)], nil];
        [self addChild:restartMenu];
        [restartMenu setPosition: IS_IPAD ? CGPointMake(512, 300) : CGPointMake(160, SCREEN_HEIGHT - 240)];
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    
    [self runAction:[CCFadeTo actionWithDuration:.33 opacity:180]];
    if (!IS_IPAD){
        [self.bossAbilityTableView reloadData];
        [self.bossAbilityTableView scrollToTopAnimated:NO];
    }
}

- (void)quit{
    [self.delegate pauseLayerDidQuit];
}


- (void)close{
    [self.delegate pauseLayerDidFinish];
}

- (void)restart
{
    [self.delegate pauseLayerDidRestart];
}


#pragma mark - Boss Abilities Table View

-(void)table:(CCTableView *)table cellTouched:(CCTableViewCell *)cell
{
    
}

- (CGSize)cellSizeForTable:(CCTableView *)table
{
    return CGSizeMake(SCREEN_WIDTH - 20, 60);
}

- (CCTableViewCell*)table:(CCTableView *)table cellAtIndex:(NSUInteger)idx
{
    CCTableViewSpriteCell *availableCell = (CCTableViewSpriteCell*)[table dequeueCell];
    
    if (!availableCell) {
        availableCell = [[[CCTableViewSpriteCell alloc] init] autorelease];
    }
    
    AbilityDescriptor *abilityDesc = [[(Enemy*)self.encounter.enemies.firstObject abilityDescriptors] objectAtIndex:idx];
    
    IconDescriptionTableCellSprite *sprite = [[[IconDescriptionTableCellSprite alloc] initWithIconSpriteFrameName:abilityDesc.iconName title:abilityDesc.abilityName description:abilityDesc.abilityDescription] autorelease];
    
    [availableCell setSprite:sprite];
    [sprite setScale:.5];
    [sprite setPosition:CGPointMake(SCREEN_WIDTH / 2, 0)];
    return availableCell;
}

- (NSUInteger)numberOfCellsInTableView:(CCTableView *)table
{
    return [(Enemy*)self.encounter.enemies.firstObject abilityDescriptors].count;
}
@end
