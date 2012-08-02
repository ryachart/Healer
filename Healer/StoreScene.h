//
//  StoreScene.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "cocos2d.h"
#import "ShopItemExtendedNode.h"

typedef enum {
    StoreCategoryEssentials,
    StoreCategoryTopShelf,
    StoreCategoryArchives,
    StoreCategoryVault
} StoreCategory;

@interface StoreScene : CCScene <ShopItemExtendedNodeDelegate>

@end
