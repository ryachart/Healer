//
//  PurchaseManager.h
//  Healer
//
//  Created by Ryan Hart on 5/16/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void (^ChestKeyPurchaseCompletion)(BOOL success);

extern NSString *const PlayerDidPurchaseExpansionNotification;

@interface PurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate>
@property (nonatomic, retain) NSArray *products;

+ (PurchaseManager*)sharedPurchaseManager;

- (void)getProducts;
- (SKProduct *)legacyOfTormentProduct;
- (SKProduct *)goldOneProduct;
- (SKProduct *)chestKeyProduct;

- (BOOL)purchaseLegacyOfTorment; //Returns NO if the payment immediately fails
- (BOOL)purchaseGoldOne;
- (void)purchaseChestKeyWithCompletion:(ChestKeyPurchaseCompletion)completion;
- (void)restorePurchases;

@end
