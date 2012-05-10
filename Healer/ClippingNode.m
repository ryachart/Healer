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
    CCDirector *director = [CCDirector sharedDirector];
    CGSize size = [director winSize];
    CGPoint origin = [self convertToWorldSpaceAR:clipRect.origin];
    CGPoint topRight = [self convertToWorldSpaceAR:ccpAdd(clipRect.origin, ccp(clipRect.size.width, clipRect.size.height))];
    CGRect scissorRect = CGRectMake(origin.x, origin.y, topRight.x-origin.x, topRight.y-origin.y);
    
    // transform the clipping rectangle to adjust to the current screen
    // orientation: the rectangle that has to be passed into glScissor is
    // always based on the coordinate system as if the device was held with the
    // home button at the bottom. the transformations account for different
    // device orientations and adjust the clipping rectangle to what the user
    // expects to happen.
    ccDeviceOrientation orientation = [[CCDirector sharedDirector] deviceOrientation];
    switch (orientation) {
        case kCCDeviceOrientationPortrait:
            break;
        case kCCDeviceOrientationPortraitUpsideDown:
            scissorRect.origin.x = size.width-scissorRect.size.width-scissorRect.origin.x;
            scissorRect.origin.y = size.height-scissorRect.size.height-scissorRect.origin.y;
            break;
        case kCCDeviceOrientationLandscapeLeft:
        {
            float tmp = scissorRect.origin.x;
            scissorRect.origin.x = scissorRect.origin.y;
            scissorRect.origin.y = size.width-scissorRect.size.width-tmp;
            tmp = scissorRect.size.width;
            scissorRect.size.width = scissorRect.size.height;
            scissorRect.size.height = tmp;
        }
            break;
        case kCCDeviceOrientationLandscapeRight:
        {
            float tmp = scissorRect.origin.y;
            scissorRect.origin.y = scissorRect.origin.x;
            scissorRect.origin.x = size.height-scissorRect.size.height-tmp;
            tmp = scissorRect.size.width;
            scissorRect.size.width = scissorRect.size.height;
            scissorRect.size.height = tmp;
        }
            break;
    }
    
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