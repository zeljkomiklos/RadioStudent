//
//  AppDelegate.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "AppDelegate.h"


#if defined(DEBUG)
#define LOG(fmt, args...) NSLog(@"%s " fmt, __PRETTY_FUNCTION__, ##args)
#else
#define LOG(...)
#endif


@interface AppDelegate ()
{
    UIBackgroundTaskIdentifier _bgTask;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&rootExceptionHandler);
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:1 * 1024 * 1024
                                                      diskCapacity:4 * 1024 * 1024
                                                          diskPath:nil];
    [NSURLCache setSharedURLCache:cache];
    
    _bgTask = UIBackgroundTaskInvalid;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    LOG(@"Starting background task!");

    _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RadioStudent-BG" expirationHandler:^{
        NSLog(@"Background task expired!");
        
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
    if(_bgTask == UIBackgroundTaskInvalid) {
        NSLog(@"Can't start a background task!");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if(_bgTask != UIBackgroundTaskInvalid) {
        LOG(@"Exiting background task!");

        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


static void rootExceptionHandler(NSException *exception) {
    NSLog(@"Root exception: %@", exception);
    NSLog(@"... stack trace: %@", [exception callStackReturnAddresses]);
    NSLog(@"... symbols: %@",  [exception callStackSymbols]);
}

@end
