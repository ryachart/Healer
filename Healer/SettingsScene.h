//
//  SettingsScene.h
//  Healer
//
//  Created by Ryan Hart on 11/10/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import <MessageUI/MessageUI.h>
#import "IconDescriptionModalLayer.h"

@interface SettingsScene : CCScene <UIAlertViewDelegate, MFMailComposeViewControllerDelegate, IconDescriptorModalDelegate>
+ (void)configureAudioForUserSettings;
@end
