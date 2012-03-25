//
//  PlayerHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerHealthView.h"

@implementation PlayerHealthView
@synthesize memberData, healthLabel, isTouched, interactionDelegate, defaultBackgroundColor, healthBar;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        self.isTouchEnabled = YES;
        isTouched = NO;
        [self setDefaultBackgroundColor:ccWHITE];
        
        self.healthLabel = [CCLabelTTF labelWithString:@"100.0" fontName:@"Arial" fontSize:14];
        [self.healthLabel setPosition:CGPointMake(frame.size.width * .5, frame.size.height * .5)];
        [self.healthLabel setColor:ccBLACK];
        [self addChild:self.healthLabel z:10];
        
        self.healthBar = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255)];
        [self.healthBar setPosition:CGPointMake(0, 0)];
        self.healthBar.contentSize = CGSizeMake(0, frame.size.height);
        [self addChild:self.healthBar];
    }
    return self;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//UITouch *touch = [touches anyObject];
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    if (interactionDelegate != nil && CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
        [[self interactionDelegate] playerSelected:self];
        isTouched = YES;
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (interactionDelegate != nil){
        BOOL wasTouched = isTouched;
		isTouched = NO;
        if (wasTouched){
            [[self interactionDelegate] playerUnselected:self];
        }
	}
}

-(void)updateHealth
{
	NSString *healthText;
    float healthPercentage = (((float)memberData.health) / memberData.maximumHealth);
    self.healthBar.contentSize = CGSizeMake(healthPercentage * self.contentSize.width, self.healthBar.contentSize.height);
	if (memberData.health >= 1){
        
		healthText = [NSString stringWithFormat:@"%3.1f", (healthPercentage)*100];
	}
	else {
		healthText = @"Dead";
		[self setColor:ccRED];
	}
	
	if (![healthText isEqualToString:[self.healthLabel string]]){
		//NSLog(@"DIFFERENT");
		[self.healthLabel setString:healthText];
	}
}


- (void)dealloc {
    [super dealloc];
}


@end
