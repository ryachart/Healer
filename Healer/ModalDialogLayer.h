//
//  ModalDialogLayer.h
//  Healer
//
//  Created by Ryan Hart on 9/27/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@protocol ModalDialogLayerDelegate <NSObject>

//Subclasses should decide what their buttonIndexes mean
- (void)modalDialogLayerDidDismissWithButtonIndex:(NSInteger)buttonIndex;

@end

@interface ModalDialogLayer : CCLayer
@property (nonatomic, assign) CCSprite *contentSprite;
@property (nonatomic, assign) id <ModalDialogLayerDelegate> delegate;
- (id)initWithText:(NSString *)text;

- (void)show;
- (void)dismiss;
@end
