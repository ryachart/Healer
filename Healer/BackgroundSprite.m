//
//  BackgroundSprite.m
//  Healer
//
//  Created by Ryan Hart on 4/28/12.
//

#import "BackgroundSprite.h"

@implementation BackgroundSprite

-(id)initWithAssetName:(NSString*)assetName{
    NSString *assetsPath = [[NSBundle mainBundle] pathForResource:assetName ofType:@"pvr.ccz"  inDirectory:@"backgrounds"];
    if (self = [super initWithFile:assetsPath]){
        self.anchorPoint = ccp(0.0,0.0);
    }
    return self;
}

@end
