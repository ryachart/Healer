//
//  ClippingNode.h
//  Healer
//
//  Created by Ryan Hart on 4/12/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

/** Restricts (clips) drawing of all children to a specific region. */
@interface ClippingNode : CCNode 
{
}

@property (nonatomic) CGRect clippingRegion;

@end