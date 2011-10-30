//
//  Boss.m
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import "Boss.h"
#import "AssetManager.h"

// ToDo:  store maxhealth for boss and allies and use it to draw health bars of the right size

@implementation Boss

@synthesize healthBar;
@synthesize defaults;

// necessary for sub-classing CCSprite to work for some reason
-(id) initWithTexture:(CCTexture2D*)texture rect:(CGRect)rect
{
    if( (self=[super initWithTexture:texture rect:rect]))
    {
        defaults = [[AssetManager sharedInstance] getDefaults];
        
        int max_health_bar_size = [[defaults valueForKey:@"max_health_bar_size_boss"] intValue];
        
        health = [[defaults valueForKey:@"boss_max_health"] intValue];
        showHealthBar = true;
        
        healthBar = [CCSprite spriteWithFile:@"WhitePixel.png"];
        [healthBar setAnchorPoint:ccp(0.0f, 0.0f)];
        [healthBar setScaleX:health * max_health_bar_size / 1000];
        [healthBar setScaleY:25];
        [healthBar setColor:ccGREEN];
        // health bar will not rotate or scale if the enemy (parent) does ..
        healthBar.honorParentTransform &= ~(CC_HONOR_PARENT_TRANSFORM_SCALE | CC_HONOR_PARENT_TRANSFORM_ROTATE);
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        //[healthBar setPosition:ccp(20,  winSize.height - 20)];
        [healthBar setPosition:ccp(-500, 470)]; // ToDo:  Fix this crap!
        [self addChild:healthBar];
    }
    return self;
}

// ToDo:  put this in a helper class
int* colorStatusForHealthPercentageBoss(double percentage)
{
    int r = 0;
    int g = 255;
    int b = 0;
    if (percentage >= .5 && percentage <= 1){
        r = (1 - percentage) * 255;
        g = 255;
        r *= 2;
    } else if (percentage < .5 && percentage >= 0){
        g = percentage * 255;
        r = 255;
        g *= 2;
    }
    
    int* rv = malloc(sizeof(int) * 3);
    rv[0] = r;
    rv[1] = g;
    rv[2] = b;
    return rv;
}

-(void) updateHealthBar
{
    int* color = colorStatusForHealthPercentageBoss((double)health / 1000);
    
    int max_health_bar_size = [[defaults valueForKey:@"max_health_bar_size_boss"] intValue];
    [healthBar setScaleX:health * max_health_bar_size / 1000];
    [healthBar setColor:ccc3(color[0], color[1], color[2])];
}

@end
