//
//  AssetManager.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright 2011 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AssetManager : NSObject {
    
    NSMutableDictionary *plistDefaults;
    
}

@property(nonatomic, retain) NSMutableDictionary *plistDefaults;

+(id)sharedInstance;
+(id)alloc;

-(NSMutableDictionary*) getDefaults;

@end
