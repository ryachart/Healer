//
//  BackgroundSprite.m
//  Healer
//
//  Created by Ryan Hart on 4/28/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "BackgroundSprite.h"

@implementation BackgroundSprite

-(id)initWithAssetName:(NSString*)assetName{
    NSString *assetsPath = [[NSBundle mainBundle] pathForResource:assetName ofType:@"pvr.ccz"  inDirectory:@"assets"];
    if (self = [super initWithFile:assetsPath]){
        self.anchorPoint = ccp(0.0,0.0);
    }
    return self;
}

@end
