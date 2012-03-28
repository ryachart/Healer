//
//  Announcer.h
//  Healer
//
//  Created by Ryan Hart on 3/27/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Announcer <NSObject>
-(void)announce:(NSString*)announcement;
@end
