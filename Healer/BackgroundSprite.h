//
//  BackgroundSprite.h
//  Healer
//
//  Created by Ryan Hart on 4/28/12.
//

#import "cocos2d.h"

@interface BackgroundSprite : CCSprite

-(id)initWithAssetName:(NSString*)assetName;
-(id)initWithJPEGAssetName:(NSString*)assetName;

+ (BackgroundSprite*)launchImageBackground;
@end
