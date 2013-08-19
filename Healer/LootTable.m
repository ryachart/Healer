//
//  LootTable.m
//  Healer
//
//  Created by Ryan Hart on 5/30/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "LootTable.h"

@interface LootTable ()
@property (nonatomic, readwrite, retain) NSArray *weights;
@property (nonatomic, readwrite, retain) NSArray *items;
@end

@implementation LootTable

- (void)dealloc
{
    [_weights release];
    [_items release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.weights = [NSArray array];
        self.items = [NSArray array];
    }
    return self;
}

- (id)initWithItems:(NSArray *)items andWeights:(NSArray *)weights
{
    if (self = [super init]) {
        self.items = items;
        self.weights = weights;
    }
    return self;
}

- (id)randomObject
{
    NSAssert(self.items.count == self.weights.count, @"Incorrect weights to items");
    if (self.items.count > 0 && self.weights.count > 0 && self.items.count == self.weights.count) {
        NSInteger totalWeights = 0;
        for (NSNumber *number in self.weights) {
            totalWeights += [number integerValue];
        }
        
        if (totalWeights > 0) {
            NSInteger random = arc4random() % totalWeights;
            for (int i = 0; i < self.items.count ; i++) {
                if (random < [[self.weights objectAtIndex:i] integerValue]) {
                    return [self.items objectAtIndex:i];
                }
                random -= [[self.weights objectAtIndex:i] integerValue];
            }
            NSAssert(nil, @"Failed to achieve randomness. You are a failure.");
        }
    }
    return nil;
}

@end
