//
//  ShopItemNode.h
//  Healer
//
//  Created by Ryan Hart on 4/26/12.
//

#import "cocos2d.h"

@class ShopItem;

@interface ShopItemNode : CCSprite
@property (nonatomic, retain) ShopItem *item;
- (id)initWithShopItem:(ShopItem*)item target:(id)target selector:(SEL)selector;
- (id)initForIphoneWithShopItem:(ShopItem*)item;
- (void)checkPlayerHasItem;
@end
