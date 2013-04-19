//
//  SettingsScene.h
//  Healer
//
//  Created by Ryan Hart on 11/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import <MessageUI/MessageUI.h>

@interface SettingsScene : CCScene <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
+ (void)configureAudioForUserSettings;
@end
