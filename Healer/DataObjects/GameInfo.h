//
//  GameInfo.h
//  RaidLeader
//
//  Created by Ryan Hart on 11/7/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GameInfo : NSObject {
	NSMutableDictionary *itemDictionary;
}
@property (readonly, retain) NSMutableDictionary *itemDictionary;

+(id)sharedInstance;

@end
