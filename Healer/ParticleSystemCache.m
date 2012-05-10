//
//  ParticleSystemCache.m
//  Healer
//
//  Created by Ryan Hart on 4/3/12.
//

#import "ParticleSystemCache.h"

@interface ParticleSystemCache ()
@property (nonatomic, retain) NSMutableDictionary *particleSystems;
@end

static ParticleSystemCache *_sharedCache = nil;
@implementation ParticleSystemCache
@synthesize particleSystems;

-(id)init{
    if (self=[super init]){
        self.particleSystems = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return self;
}

+(ParticleSystemCache*)sharedCache{
    if (!_sharedCache){
        _sharedCache = [[ParticleSystemCache alloc] init];
    }
    return _sharedCache;
}

-(CCParticleSystemQuad*)systemForKey:(NSString*)key{
    NSDictionary *systemInfo = [self.particleSystems objectForKey:key];
    if (!systemInfo){
        NSString *systemPath = [[NSBundle mainBundle] pathForResource:[key stringByDeletingPathExtension] ofType:@"plist" inDirectory:@"emitters"];   
        systemInfo = [NSDictionary dictionaryWithContentsOfFile:systemPath];
        [self.particleSystems setObject:systemInfo forKey:key];
    }
    CCParticleSystemQuad *system = [[[CCParticleSystemQuad alloc] initWithDictionary:systemInfo] autorelease];
    return system;
}

@end
