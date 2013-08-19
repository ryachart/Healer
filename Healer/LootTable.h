//
//  LootTable.h
//  Healer
//
//  Created by Ryan Hart on 5/30/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LootTable : NSObject
@property (nonatomic, readonly, retain) NSArray *items;
@property (nonatomic, readonly, retain) NSArray *weights;
- (id)initWithItems:(NSArray *)items andWeights:(NSArray*)weights;

- (id)randomObject;
@end
