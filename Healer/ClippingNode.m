//
//  ClippingNode.m
//  Healer
//
//  Created by Ryan Hart on 4/12/12.
//
// http://www.cocos2d-iphone.org/forum/topic/3993#post-35014

#import "ClippingNode.h"

@interface ClippingNode (PrivateMethods)
-(void) deviceOrientationChanged:(NSNotification*)notification;
@end

@implementation ClippingNode
@synthesize clippingRegion;

-(void)preVisit{
    if (!self.visible)
        return;
    
    glEnable(GL_SCISSOR_TEST);
    
    CGRect clipRect = self.clippingRegion;
    CGPoint origin = [self convertToWorldSpaceAR:clipRect.origin];
    CGPoint topRight = [self convertToWorldSpaceAR:ccpAdd(clipRect.origin, ccp(clipRect.size.width, clipRect.size.height))];
    CGRect scissorRect = CGRectMake(origin.x, origin.y, topRight.x-origin.x, topRight.y-origin.y);
    
    
    // Handle Retina
    scissorRect = CC_RECT_POINTS_TO_PIXELS(scissorRect);
    
    glScissor((GLint) scissorRect.origin.x, (GLint) scissorRect.origin.y,
              (GLint) scissorRect.size.width, (GLint) scissorRect.size.height);
}
-(void)postVisit{
    glDisable(GL_SCISSOR_TEST);
}
-(void) visit
{
    [self preVisit];
    [super visit];
    [self postVisit];
}

@end