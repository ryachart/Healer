//
//  RaidMemberHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RaidMemberHealthView.h"

#define HEALTH_BAR_BORDER 6

@implementation RaidMemberHealthView

@synthesize memberData, classNameLabel, healthLabel, interactionDelegate, defaultBackgroundColor, isTouched, effectsLabel;
@synthesize healthBarLayer;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        
        self.position = frame.origin;
        self.contentSize = frame.size;
        
        
        self.healthBarLayer = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255) width:frame.size.width - (HEALTH_BAR_BORDER *2) height:frame.size.height - (HEALTH_BAR_BORDER *2)];
        self.healthBarLayer.position = CGPointMake(HEALTH_BAR_BORDER, HEALTH_BAR_BORDER);
        
		self.classNameLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];            // [[UILabel alloc] initWithFrame:CGRectMake(1, 1, CGRectGetWidth(frame), CGRectGetHeight(frame)*.25)];
        [self.classNameLabel setPosition:CGPointMake(20, 10)];
        [self.classNameLabel setContentSize:CGSizeMake(frame.size.width, frame.size.height)];
        [self.classNameLabel setColor:ccc3(0, 0, 0)];
//		[classNameLabel setBackgroundColor:[UIColor clearColor]];
//		[classNameLabel setFont:[UIFont	systemFontOfSize:12]];

		self.healthLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];    //[[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)*.3, CGRectGetHeight(frame)*.3, CGRectGetWidth(frame)*.5, CGRectGetHeight(frame)*.25)];
        [self.healthLabel setPosition:CGPointMake(frame.size.width * .3, frame.size.height * .3)];
        [self.healthLabel setContentSize:CGSizeMake(frame.size.width * .5, frame.size.height * .25)];
        [self.healthLabel setColor:ccc3(0, 0, 0)];
		
		self.effectsLabel =  [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:12.0f];  //[[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)*.85, CGRectGetWidth(frame), CGRectGetHeight(frame)*.15)];
        [self.effectsLabel setPosition:CGPointMake(0, frame.size.height * .15)];
        [self.effectsLabel setContentSize:CGSizeMake(frame.size.width, frame.size.height * .15)];
        [self.effectsLabel setColor:ccc3(0, 0, 0)];
			
        [self addChild:self.healthBarLayer];
        [self addChild:self.classNameLabel];
        [self addChild:self.healthLabel];
		interactionDelegate = nil;
		
		isTouched = NO;
    }
    return self;
}

-(void)setMemberData:(RaidMember*)rdMember
{
	memberData = rdMember;
	
	if ([memberData class] == [Witch class]) [classNameLabel setString:@"Witch"];
	if ([memberData class] == [Ogre	 class]) [classNameLabel setString:@"Ogre"];
	if ([memberData class] == [Troll class]) [classNameLabel setString:@"Troll"];

}

-(void)onEnter{
    self.isTouchEnabled = YES;
    [super onEnter];
}

-(void)onExit{
    self.isTouchEnabled = NO;
    [super onExit];
}
-(void)updateHealth
{
	NSString *healthText;
	if (memberData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f", (((float)memberData.health) / memberData.maximumHealth)*100];
		self.healthBarLayer.contentSize = CGSizeMake(self.healthBarLayer.contentSize.width, (self.contentSize.height - (HEALTH_BAR_BORDER * 2) ) * (((float)memberData.health) / memberData.maximumHealth));
	}
	else {
		healthText = @"Dead";
        self.healthBarLayer.contentSize = CGSizeMake(self.healthBarLayer.contentSize.width, 0);
		[self setColor:ccc3(255, 0, 0)];
        [self setOpacity:255];
	}
	
	NSMutableString* effectText = [[NSMutableString alloc] initWithCapacity:10];
	for (Effect *eff in self.memberData.activeEffects){
		if ([eff isKindOfClass:[HealOverTimeEffect class]]){
			[effectText appendString:@"H"];
		}
		else if ([eff isKindOfClass:[ShieldEffect class]]){
			[effectText appendString:@"S"];
		}
		else if ([eff effectType] == EffectTypePositive){
			[effectText appendString:@"P"];
		}
	}

	
	

	if (![healthText isEqualToString:[healthLabel string]] || ![effectText isEqualToString:[effectsLabel string]]){
		//NSLog(@"DIFFERENT");
		[effectsLabel setString:effectText];
		[healthLabel setString:healthText];
	}
	[effectText release];
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
            [[self interactionDelegate] thisMemberSelected:self];
            isTouched = YES;
    }
}

//-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [touches anyObject];
//    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
//    
//    CGRect layerRect =  [self boundingBox];
//    layerRect.origin = CGPointZero;
//    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
//    
//    if (interactionDelegate != nil && CGRectContainsPoint(layerRect, convertedToNodeSpacePoint)){
//        if (!isTouched){
//            [[self interactionDelegate] thisMemberSelected:self];
//            isTouched = YES;
//        }
//    }
//}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
	if (interactionDelegate != nil){
        BOOL wasTouched = isTouched;
		isTouched = NO;
        if (wasTouched){
            [[self interactionDelegate] thisMemberUnselected:self];
        }
	}
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//	CGFloat percentageToFill = ((float)memberData.health)/memberData.maximumHealth;
//	
//	CGFloat width = CGRectGetWidth(self.frame) * .8;
//	CGFloat x = CGRectGetWidth(self.frame) * .10; //10% of the rect is a border
//	
//	CGFloat y = CGRectGetHeight(self.frame) * .10 + (CGRectGetHeight(self.frame) * .8 * (1.0 - percentageToFill));
//	CGFloat height = CGRectGetHeight(self.frame) * .8 - (CGRectGetHeight(self.frame) * .8 * (1.0 - percentageToFill));
//	
//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextSetRGBFillColor(context,0,1, 0, 1);
//	
//	UIRectFill(CGRectMake(x,y,width,height));
//	
//	
//	[classNameLabel drawTextInRect:classNameLabel.frame];
//	[healthLabel drawTextInRect:healthLabel.frame];
//	[effectsLabel drawTextInRect:effectsLabel.frame];
//	/*
//	 CGFloat R = arc4random()%200;
//	 CGFloat G = arc4random()%200;
//	 CGFloat B = arc4random()%200;
//	 */
//	
//	
//	
//	
//}


- (void)dealloc {
    [super dealloc];
}


@end
