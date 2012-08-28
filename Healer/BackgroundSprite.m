//
//  BackgroundSprite.m
//  Healer
//
//  Created by Ryan Hart on 4/28/12.
//

#import "BackgroundSprite.h"

@implementation BackgroundSprite

- (id)initWithAssetName:(NSString*)assetName{
    NSString *assetsPath = [[NSBundle mainBundle] pathForResource:assetName ofType:@"pvr.ccz"  inDirectory:@"backgrounds"];
    if (self = [super initWithFile:assetsPath]){
        self.anchorPoint = ccp(0.0,0.0);
    }
    return self;
}

-(id)initWithJPEGAssetName:(NSString *)assetName {
    NSString *assetsPath = [[NSBundle mainBundle] pathForResource:assetName ofType:@"jpg"  inDirectory:@"backgrounds"];
    if (self = [super initWithFile:assetsPath]){
        self.anchorPoint = ccp(0.0,0.0);
    }
    return self;
}

+ (CCSprite*)launchImageBackground
{
    UIImage *image = [UIImage imageNamed:@"Default-Landscape"];
    BackgroundSprite *sprite = [[BackgroundSprite alloc] initWithCGImage:[image CGImage] key:@"Default-Landscape"];
    [sprite setAnchorPoint:CGPointMake(0, 0)];
    return [sprite autorelease];
}

@end
