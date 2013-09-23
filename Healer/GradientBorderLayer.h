//
//  GradientBorderLayer.h
//  Healer
//
//  Created by Ryan Hart on 2/4/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@interface GradientBorderLayer : CCLayerColor
@property (nonatomic, readwrite) ccColor3B baseColor; //Defaults to red
@property (nonatomic, readwrite) float borderWidth; //Defaults to 100
@property (nonatomic, readwrite) float initialOpacity; //0 to 255.  Defaults to 255
@property (nonatomic, readwrite) float finalOpacity; //0 to 255.  Defaults to 0
@property (nonatomic, readonly) BOOL isFlashing;
- (void)flash; //Does nothing if opacity is already 255
@end
