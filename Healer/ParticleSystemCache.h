//
//  ParticleSystemCache.h
//  Healer
//
//  Created by Ryan Hart on 4/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface ParticleSystemCache : NSObject

+(ParticleSystemCache*)sharedCache;
-(CCParticleSystemQuad*)systemForKey:(NSString*)key;
@end
