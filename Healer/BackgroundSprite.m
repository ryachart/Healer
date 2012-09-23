//
//  BackgroundSprite.m
//  Healer
//
//  Created by Ryan Hart on 4/28/12.
//

#import "BackgroundSprite.h"

@implementation BackgroundSprite

- (id)initWithAssetName:(NSString*)assetName{
    if (self = [super initWithFile:[@"backgrounds" stringByAppendingPathComponent:[assetName stringByAppendingPathExtension:@"pvr.ccz"]]]){
        self.anchorPoint = ccp(0.0,0.0);
    }
    return self;
}

-(id)initWithJPEGAssetName:(NSString *)assetName {
    if (self = [super initWithFile:[@"backgrounds" stringByAppendingPathComponent:[assetName stringByAppendingPathExtension:@"jpg"]]]){
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
