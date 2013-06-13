//
//  ClippingNode.h
//  Healer
//
//  Created by Ryan Hart on 4/12/12.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

/** Restricts (clips) drawing of all children to a specific region. */
@interface ClippingNode : CCNode <CCRGBAProtocol>
{
}

@property (nonatomic) CGRect clippingRegion;

@end