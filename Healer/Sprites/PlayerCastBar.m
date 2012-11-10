//
//  PlayerCastBar.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PlayerCastBar.h"
#import "Spell.h"

@interface PlayerCastBar ()
@property (nonatomic, readwrite) BOOL castHasBegun;
@end

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
        
        
        self.timeRemaining = [CCLabelTTF labelWithString:@"Not Casting" dimensions:self.contentSize hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.timeRemaining setColor:ccRED];
        [self.timeRemaining setPosition:CGPointMake(200, 15)];
        [self addChild:self.timeRemaining z:100];
        
        self.castBar = [CCLayerGradient layerWithColor:ccc4(0, 200, 50, 255) fadingTo:ccc4(0, 150, 100, 200) alongVector:CGPointMake(-1, 0)];
        
        [self.castBar setPosition:CGPointMake(4, 4)];
        [self.castBar setColor:ccGREEN];
        [self.castBar setOpacity:255];
        self.castBar.contentSize = CGSizeMake(0, frame.size.height - 8);
        [self addChild:self.castBar];
    }
    return self;
}

- (void)restartCast
{
    
}

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime forSpell:(Spell*)spell
{
	if (remaining <= 0){
		[self.timeRemaining setString:@"Not Casting"];
		percentTimeRemaining = 0.0;
        [self.castBar setContentSize:CGSizeMake(0, self.castBar.contentSize.height)];
        if (self.castHasBegun) {
            self.castHasBegun = NO;
            NSLog(@"Cast Finished: %@", spell.title);
        }
	}
	else {
        if (!self.castHasBegun) {
            self.castHasBegun = YES;
        }
		percentTimeRemaining = remaining/maxTime;
        [self.castBar setContentSize:CGSizeMake((self.contentSize.width - 8) * (1 - percentTimeRemaining), self.castBar.contentSize.height)];
		[timeRemaining setString:[NSString stringWithFormat:@"%@: %1.2f", spell.title,  remaining]];
	}
}

- (void)dealloc {
    [timeRemaining release];
    [castBar release];
    [super dealloc];
}

@end
