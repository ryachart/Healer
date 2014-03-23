//
//  TalentScene_iPhone.m
//  Healer
//
//  Created by Ryan Hart on 3/16/14.
//  Copyright (c) 2014 Ryan Hart Games. All rights reserved.
//

#import "TalentScene_iPhone.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "HealerStartScene_iPhone.h"
#import "Talents.h"
#import "IconDescriptionTableCellSprite.h"

@interface TalentScene_iPhone ()
@property (nonatomic, assign) CCTableView *talentsTableView;
@property (nonatomic, assign) CCMenu *backButton;
@end

@implementation TalentScene_iPhone

- (void)dealloc
{
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:@"assets-iphone/divinity-sprites.plist"];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets-iphone/divinity-sprites.plist"];
        
        BackgroundSprite *bgSprite = [[[BackgroundSprite alloc] initWithJPEGAssetName:@"homescreen-bg"] autorelease];
        [self addChild:bgSprite];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self addChild:backButton];
        [backButton setPosition:CGPointMake(85, SCREEN_HEIGHT * .92)];
        
        self.talentsTableView = [[[CCTableView alloc] initWithViewSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT - 80)] autorelease];
        [self.talentsTableView setPosition:CGPointMake(0, -50)];
        self.talentsTableView.verticalFillOrder = SWTableViewFillTopDown;
        [self.talentsTableView setPosition:CGPointMake(0, 0)];
        [self addChild:self.talentsTableView];
        self.talentsTableView.contentSize = CGSizeMake(SCREEN_WIDTH, 2000);
        [self.talentsTableView setDataSource:self];
        [self.talentsTableView setDelegate:self];
    }
    return self;
}

- (void)onEnter{
    [super onEnter];
    [self.talentsTableView reloadData];
    [self.talentsTableView scrollToTopAnimated:NO];
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene_iPhone alloc] init] autorelease]]];
}

- (NSUInteger)numberOfRowsInSection:(NSUInteger)section inTableView:(CCTableView*)tableview
{
    return [[Talents talentChoicesForTier:section] count];
}

- (NSUInteger)numberOfSectionsInTableView:(CCTableView *)tableView
{
    return NUM_DIV_TIERS;
}

- (CGSize)cellSizeForTable:(CCTableView *)table
{
    return CGSizeMake(SCREEN_WIDTH - 20, 80);
}

- (CCTableViewCell*)table:(CCTableView *)table cellAtIndex:(NSUInteger)idx
{
    CCTableViewSpriteCell *availableCell = (CCTableViewSpriteCell*)[table dequeueCell];
    
    if (!availableCell) {
        availableCell = [[[CCTableViewSpriteCell alloc] init] autorelease];
    }
    int sectionNumber = [table sectionForIndex:idx];
    CCSprite *node = [CCSprite node];

    if ([table isHeaderCellAtIndex:idx]) {
        CCLabelTTFShadow *tierLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"Tier %i", sectionNumber + 1] fontName:@"TrebuchetMS-Bold" fontSize:32.0f];
        [node addChild:tierLabel];
    } else {
        int sectionIndex = [table sectionIndexForIndex:idx];

        NSArray *choicesForSection = [Talents talentChoicesForTier:sectionNumber];
        NSString *spriteName = [Talents spriteFrameNameForChoice:[choicesForSection objectAtIndex:[table sectionIndexForIndex:idx]]];
        IconDescriptionTableCellSprite *iconSprite = [[[IconDescriptionTableCellSprite alloc] initWithIconSpriteFrameName:spriteName title:[choicesForSection objectAtIndex:sectionIndex] description:@""] autorelease];
        [iconSprite setScale:0.5];
        [iconSprite.itemSprite setScale:.66];
        [node addChild:iconSprite];
    }
    
    [availableCell setSprite:node];
    [node setPosition:CGPointMake(SCREEN_WIDTH / 2, 0)];
    return availableCell;
}

- (NSUInteger)numberOfCellsInTableView:(CCTableView *)table
{
    NSInteger sectionsInTableView = [self numberOfSectionsInTableView:table];
    return (sectionsInTableView * 3) + sectionsInTableView; //3 Rows per section plus 1 header per section
}

- (void)table:(CCTableView *)table cellTouched:(CCTableViewCell *)cell
{
    NSInteger selectedIndex = cell.idx;
    if ([table isHeaderCellAtIndex:selectedIndex]) return;
}

@end
