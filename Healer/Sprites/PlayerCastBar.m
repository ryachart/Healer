//
//  PlayerCastBar.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerCastBar.h"


@implementation PlayerCastBar
@synthesize timeRemaining, castBar;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        [self setOpacity:255];
        [self setColor:ccGRAY];
		percentTimeRemaining = 0.0;
        
        
        self.timeRemaining = [CCLabelTTF labelWithString:@"Not Casting" fontName:@"Arial" fontSize:12.0];
        [self.timeRemaining setColor:ccRED];
        [self.timeRemaining setPosition:CGPointMake(50, 25)];
        [self addChild:self.timeRemaining z:100];
        
        self.castBar = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255)];
        
        [self.castBar setPosition:CGPointMake(0, 0)];
        [self.castBar setColor:ccGREEN];
        [self.castBar setOpacity:255];
        self.castBar.contentSize = CGSizeMake(0, frame.size.height);
        [self addChild:self.castBar];
    }
    return self;
}

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime
{
	if (remaining <= 0){
		[self.timeRemaining setString:@"Not casting"];
		percentTimeRemaining = 0.0;
        [self.castBar setContentSize:CGSizeMake(0, self.castBar.contentSize.height)];
	}
	else {
		percentTimeRemaining = remaining/maxTime;
        [self.castBar setContentSize:CGSizeMake(self.contentSize.width * (1 - percentTimeRemaining), self.castBar.contentSize.height)];
		[timeRemaining setString:[NSString stringWithFormat:@"%1.2f", remaining]];
	}
}


@end
