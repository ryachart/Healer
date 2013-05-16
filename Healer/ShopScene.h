//
//  StoreScene.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "cocos2d.h"
#import "IconDescriptionModalLayer.h"

@interface ShopScene : CCScene <IconDescriptorModalDelegate>
@property (nonatomic, readwrite) BOOL requiresGreaterHealFtuePurchase;
@property (nonatomic, readwrite) BOOL returnsToMap;
@end
