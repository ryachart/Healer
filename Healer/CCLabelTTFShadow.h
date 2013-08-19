//
//  CCLabelTTFShadow.h
//  Healer
//
//  Created by Ryan Hart on 1/3/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@interface CCLabelTTFShadow : CCLabelTTF

@property (nonatomic, readwrite) ccColor3B shadowColor; //Default Black
@property (nonatomic, readwrite) CGPoint shadowOffset; //Default -2,-2
@property (nonatomic, readwrite) GLubyte shadowOpacity;

@end
