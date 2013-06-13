//
//  PurchaseManager.m
//  Healer
//
//  Created by Ryan Hart on 5/16/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "PurchaseManager.h"
#import "PlayerDataManager.h"
#if ANDROID
#else
#import <Parse/Parse.h>
#endif

#define LEGACY_OF_TORMENT_EXPAC_ID @"torment_expac"
#define GOLD_ONE_ID @"gold_one"
#define CHEST_KEY @"chest_key"

NSString *const PlayerDidPurchaseExpansionNotification = @"com.healer.playerDidPurchaseExpac";

static PurchaseManager *_sharedPurchaseManager;

@interface PurchaseManager ()
@property (nonatomic, copy) ChestKeyPurchaseCompletion completion;
@end

@implementation PurchaseManager

+ (PurchaseManager*)sharedPurchaseManager
{
    if (!_sharedPurchaseManager) {
        _sharedPurchaseManager = [[PurchaseManager alloc] init];
    }
    return _sharedPurchaseManager;
}

- (id)init
{
    if (self = [super init]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)getProducts
{
    SKProductsRequest *productsReq = [[[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:LEGACY_OF_TORMENT_EXPAC_ID, GOLD_ONE_ID,CHEST_KEY, nil]] autorelease];
    [productsReq setDelegate:self];
    [productsReq start];
}

- (SKProduct *)legacyOfTormentProduct
{
    return [self productWithIdentifier:LEGACY_OF_TORMENT_EXPAC_ID];
}

- (SKProduct *)goldOneProduct
{
    return [self productWithIdentifier:GOLD_ONE_ID];
}

- (SKProduct *)chestKeyProduct
{
    return [self productWithIdentifier:CHEST_KEY];
}

- (SKProduct *)productWithIdentifier:(NSString *)identifier
{
    SKProduct *target = nil;
    if (!self.products) {
        return nil;
    }
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:identifier])
        {
            target = product;
            break;
        }
    }
    return target;
}

- (BOOL)startPurchaseForProduct:(SKProduct*)product
{
    if ([SKPaymentQueue canMakePayments]) {
        SKPayment *paymentForProduct = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:paymentForProduct];
        return YES;
    } else {
        return NO;
    }
    return NO;
}

- (BOOL)purchaseGoldOne
{
    SKProduct *reqProduct = [self goldOneProduct];
    if (!reqProduct) return NO;
    [self startPurchaseForProduct:reqProduct];
    return NO;
}

- (BOOL)purchaseLegacyOfTorment
{
    SKProduct *reqProduct = [self legacyOfTormentProduct];
    if (!reqProduct) return NO;
    [self startPurchaseForProduct:reqProduct];
    return NO;
}

- (void)purchaseChestKeyWithCompletion:(ChestKeyPurchaseCompletion)completion
{
    self.completion = completion;
    SKProduct *reqProduct = [self chestKeyProduct];
    if (!reqProduct) return;
    [self startPurchaseForProduct:reqProduct];
}

- (void)restorePurchases
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)saveRemotePurchase:(SKPaymentTransaction*)transaction
{
#if ANDROID
#else
    PFObject *purchaseObject = [PFObject objectWithClassName:@"purchase"];
    NSString* playerObjectID = [[NSUserDefaults standardUserDefaults] objectForKey:PlayerRemoteObjectIdKey];
    [purchaseObject setObject:playerObjectID forKey:@"playerObjectId"];
    [purchaseObject setObject:transaction.payment.productIdentifier forKey:@"productId"];
    [purchaseObject setObject:transaction.transactionIdentifier forKey:@"transactionId"];
    [purchaseObject saveEventually];
#endif
}

- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
    if (transaction.transactionState == SKPaymentTransactionStateFailed) {
        [self transactionFailed:transaction];
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    } else if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
#if ANDROID
        [self awardPurchase:transaction];
#else
        [PFPurchase downloadAssetForTransaction:transaction completion:^(NSString *filepath, NSError *error) {
            if (!error) {
                [self awardPurchase:transaction];
            } else {
                //This is probably a Parse Timeout
                [self completeTransaction:transaction]; //Infinite Retry
            }
        }];
#endif
    } else if (transaction.transactionState == SKPaymentTransactionStateRestored) {
        [self awardPurchase:transaction];
    }
}

- (void)transactionFailed:(SKPaymentTransaction *)transaction
{
    UIAlertView *failedTransaction = [[[UIAlertView alloc] initWithTitle:@"Purchase Failed" message:@"The purchase failed.  You have not been charged.  Please check your internet connection and try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease];
    [failedTransaction show];
    if (self.completion) {
        self.completion(NO);
        self.completion = nil;
    }
}

- (void)awardPurchase:(SKPaymentTransaction *)transaction
{
    if ([transaction.payment.productIdentifier isEqualToString:GOLD_ONE_ID]) {
        [[PlayerDataManager localPlayer] playerEarnsGold:1000];
        [self saveRemotePurchase:transaction];
    } else if ([transaction.payment.productIdentifier isEqualToString:LEGACY_OF_TORMENT_EXPAC_ID]) {
        [[PlayerDataManager localPlayer] purchaseContentWithKey:MainGameContentKey];
        [[PlayerDataManager localPlayer] saveLocalPlayer];
        [self saveRemotePurchase:transaction];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidPurchaseExpansionNotification object:nil];
    } else if ([transaction.payment.productIdentifier isEqualToString:CHEST_KEY]){
        if (self.completion) {
            self.completion(YES);
            self.completion = nil;
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return; //Dont show the thank you for the chests
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    UIAlertView *thankYou = [[[UIAlertView alloc] initWithTitle:@"Thank you!" message:@"Thank you for your purchase." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil] autorelease];
    [thankYou show];
}

#pragma mark - SKRequestDelegate

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Request Failed: %@", error.description);
}

- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"Request Finished: %@", request.description);
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.products = response.products;
    NSLog(@"%i Products Receieved", self.products.count);
}

#pragma mark - SKTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    NSLog(@"Removed transactions %i", transactions.count);
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"Failed to Restore Transactions: %@", error.description);
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"Updated Transactions: %i", transactions.count);
    
    for (SKPaymentTransaction *trans in transactions){
        [self completeTransaction:trans];
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"Completed Restore");
    UIAlertView *itemsRestored = [[[UIAlertView alloc] initWithTitle:@"Purchases Restored" message:@"Your previously purchased items have been restored." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil] autorelease];
    [itemsRestored show];
}

@end
