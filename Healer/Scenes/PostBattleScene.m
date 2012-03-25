//
//  PostBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "PostBattleScene.h"
#import "QuickPlayScene.h"
@interface PostBattleScene()
-(void)done;
@end

@implementation PostBattleScene


-(id)initWithVictory:(BOOL)victory{
    self = [super init];
    if (self){
        if (victory){
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }else{
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"DEFEAT!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }
        
        CCMenuItemLabel *done = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Continue" fontName:@"Arial" fontSize:32] target:self selector:@selector(done)];
        
        CCMenu *menu = [CCMenu menuWithItems:done, nil];
        menu.position = CGPointMake(512, 200);
        [self addChild:menu];
    }
    return self;
}
                            
-(void)done{
    QuickPlayScene *qps = [[QuickPlayScene alloc] init];
    [[CCDirector sharedDirector] replaceScene:qps];
    [qps release];
}
@end
