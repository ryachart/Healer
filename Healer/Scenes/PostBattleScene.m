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
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:nil fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }else{
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"DEFEAT!" fontName:nil fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }
        
        CCMenuItem *done = [CCMenuItem itemWithTarget:self selector:@selector(done)];
        
        CCMenu *menu = [CCMenu menuWithItems:done, nil];
        menu.position = CGPointMake(512, 200);
        [self addChild:menu];
    }
    return self;
}
                            
-(void)done{
    
}
@end
