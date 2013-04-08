//
//  AppDelegate.m
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//

#import <cocos2d.h>

#import "AppDelegate.h"
#import "GameConfig.h"
#import "TestFlight.h"
#import "Parse/Parse.h"
#import "PlayerDataManager.h"
#import "LaunchScene.h"
#import "Talents.h"

#define TestFlightToken @"6352fe22-b170-4fd7-a38a-60ae0ac77d39"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Init the window	
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [TestFlight takeOff:TestFlightToken];
    
    [Parse setApplicationId:@"BajbrSl60Pz6ukDojWg8CAaUdCU7FoWr7UJCiJPs"
                  clientKey:@"2CSX0jPgh7K4X7PfWbmfPdyo3G8OfCqSa41JW4BZ"];
    
    
    
	CCDirector *director = [CCDirector sharedDirector];
    [director setProjection:kCCDirectorProjection2D];
    director.wantsFullScreenLayout = YES;
	[director setDelegate:self];
    
	//
	// Create the EAGLView manually
	//  1. Create a RGB565 format. Alternative: RGBA8
	//	2. depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
	//
	//
	CCGLView *glView = [CCGLView viewWithFrame:[self.window bounds]
								   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
						];
	
    // Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
	[CCTexture2D PVRImagesHavePremultipliedAlpha:YES];
	// Removes the startup flicker
    
	// attach the openglView to the director
	[director setView:glView];
    [glView setMultipleTouchEnabled:YES];
	
	[director setAnimationInterval:1.0/60];
	
    CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
	[sharedFileUtils setEnableFallbackSuffixes:YES];				// Default: NO. No fallback suffixes are going to be used
	[sharedFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];		// Default on iPhone RetinaDisplay is "-hd"
	[sharedFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "ipad"
	[sharedFileUtils setiPadRetinaDisplaySuffix:@"-ipad-hd"];	// Default on iPad RetinaDisplay is "-ipadhd"
    [director enableRetinaDisplay:YES];

    // Run the intro Scene
	[[CCDirector sharedDirector] pushScene: [[LaunchScene new] autorelease]];
    [[PlayerDataManager localPlayer] saveRemotePlayer];
    
    self.navController = [[[UINavigationController alloc] initWithRootViewController:director] autorelease];
    self.navController.navigationBarHidden = YES;
    
	// make the View Controller a child of the main window
	[self.window setRootViewController:self.navController];
	[self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	[[CCDirector sharedDirector] stopAnimation];
    [[PlayerDataManager localPlayer] saveLocalPlayer];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	CCDirector *director = [CCDirector sharedDirector];
	
	[[director view] removeFromSuperview];
	
	[_window release];
	
	[director end];	
    
    [[PlayerDataManager localPlayer] saveLocalPlayer];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)dealloc {
    [_window release];
	[super dealloc];
}


- (void)showDebugViewController {
    
}

@end
