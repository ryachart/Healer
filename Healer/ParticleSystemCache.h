//
//  ParticleSystemCache.h
//  Healer
//
//  Created by Ryan Hart on 4/3/12.
//

#import "cocos2d.h"

@interface ParticleSystemCache : NSObject

+(ParticleSystemCache*)sharedCache;
-(CCParticleSystemQuad*)systemForKey:(NSString*)key;
@end
