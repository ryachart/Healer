//
//  ViewDivinityChoiceLayer.h
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@protocol ViewTalentChoiceLayerDelegate <NSObject>

- (void)dismissDivinityChoiceLayer:(CCLayer*)layer;

@end

@interface ViewTalentChoiceLayer : CCLayer
@property (nonatomic, assign) id<ViewTalentChoiceLayerDelegate> delegate;

- (id)initWithDivinityChoice:(NSString*)choice inTier:(NSInteger)tier;

@end
