//
//  AppDelegate.m
//  MusicSense
//
//  Created by Martijn de Vos on 20-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "AppDelegate.h"
#import "Analyzer.h"
#import "Configuration.h"
#import "AudioRecorder.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
{
    NSDictionary *result;
    Analyzer *analyzer;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMatchingResult:) name:@"nl.tudelft.MusicSense.HasResult" object:nil];
    
    return YES;
}

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply
{
    Configuration *config = [Configuration new];
    
    if(userInfo.count == 1)
    {
        result = nil;
        
        // Kick off a network request, heavy processing work, etc.
        if(config.useRawFolder)
        {
            analyzer = [[Analyzer alloc] initWithFileFromBundle:@"thedays-orig" isInDocuments:false andWithConfiguration:config];
        }
        else
        {
            // we now have to record ourselves
            [AudioRecorder startRecording];
            [self performSelector:@selector(stopRecording) withObject:self afterDelay:((float)config.recordingDuration / 1000.0)];
        }
        
        reply(@{ @"t" : @(55) });
    }
    else
    {
        reply(result);
    }
}

- (void)stopRecording
{
    [AudioRecorder stopRecording];
    Configuration *config = [Configuration new];
    analyzer = [[Analyzer alloc] initWithFileFromBundle:@"record" isInDocuments:true andWithConfiguration:config];
}

- (void)receivedMatchingResult:(NSNotification *)notification
{
    NSDictionary *resultDict = notification.userInfo[@"result"];
    result = resultDict;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
