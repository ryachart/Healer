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


#pragma mark - CCRBGAProtocol

- (void)setColor:(ccColor3B)color
{
    //Nothing
}

- (ccColor3B)color
{
    return ccBLACK;
}

- (void)setOpacity:(GLubyte)opacity
{
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            [colorChild setOpacity:opacity];
        }
    }
}

- (GLubyte)opacity
{
    float highestOpacity = 0;
    for (CCNode *child in self.children){
        if ([child conformsToProtocol:@protocol(CCRGBAProtocol)]) {
            id<CCRGBAProtocol> colorChild = (CCSprite*)child;
            highestOpacity = [colorChild opacity] > highestOpacity ? [colorChild opacity] : highestOpacity;
        }
    }
    return highestOpacity;
}
@end