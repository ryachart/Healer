//
//  Ally.m
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import "Ally.h"
#import "AssetManager.h"


@implementation Ally

@synthesize healthBar;
@synthesize defaults;

//-(id) init
//{
//    //self = [self initWithFile:@"Assassin.PNG"];
//    self = [super init];
//    if (self)
//    {
//        NSLog(@"Why are we calling init?");
//        
//    }
//    
//    return self;  
//}

// necessary for sub-classing CCSprite to work for some reason
-(id) initWithTexture:(CCTexture2D*)texture rect:(CGRect)rect
{
    if( (self=[super initWithTexture:texture rect:rect]))
    {
        defaults = [[AssetManager sharedInstance] getDefaults];
        
        int max_health_bar_size = [[defaults valueForKey:@"max_health_bar_size"] intValue];
        
        health = [[defaults valueForKey:@"ally_max_health"] intValue];
        showHealthBar = true;
        
        healthBar = [CCSprite spriteWithFile:@"WhitePixel.png"];
        [healthBar setScaleX:health * max_health_bar_size / 100];
        [healthBar setScaleY:10];
        [healthBar setAnchorPoint:ccp(0.0f,0.0f)];
        [healthBar setColor:ccGREEN];
        // health bar will not rotate or scale if the enemy (parent) does ..
        healthBar.honorParentTransform &= ~(CC_HONOR_PARENT_TRANSFORM_SCALE | CC_HONOR_PARENT_TRANSFORM_ROTATE);
        
        CGRect bb = [self boundingBox];
        [healthBar setPosition:ccp(0.0f, bb.origin.y * -2)];
        
        [self addChild:healthBar];
        NSLog(@"initWithT: %@", [self description]);
    }
    return self;
}


char* colorStatusForHealthPercentage(double percentage)
{
    float r = 0.0;
    float g = 255.0;
    float b = 0.0;
    if (percentage >= .5 && percentage <= 1){
        r = (1.0 - percentage) * 255.0;
        r *= 2;
        g = 255.0;
    } else if (percentage < .5 && percentage >= 0){
        g = percentage * 255.0;
        g *= 2;
        r = 255.0;
    }
    
    char* rv = malloc(sizeof(char) * 3);
    rv[0] = r;
    rv[1] = g;
    rv[2] = b;
    return rv;
}

-(void) updateHealthBar
{
    char* color = colorStatusForHealthPercentage((double)health / 100);
    
    int max_health_bar_size = [[defaults valueForKey:@"max_health_bar_size"] intValue];
    [healthBar setScaleX:health * max_health_bar_size / 100];
    
    [healthBar setColor:ccc3(color[0], color[1], color[2])];
    
    free(color);
}


@end
