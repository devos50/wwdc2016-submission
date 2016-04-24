//
//  InterfaceController.m
//  MusicSense WatchKit Extension
//
//  Created by Martijn de Vos on 15-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()

@property (nonatomic, weak) IBOutlet WKInterfaceButton *listenButton;

@end


@implementation InterfaceController
{
    NSTimer *checkResultTimer;
    BOOL isListening;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (IBAction)listenButtonPressed:(id)sender
{
    if(isListening) { return; }
    isListening = YES;
    [WKInterfaceController openParentApplication:@{ @"request" : @"listenRequest" } reply:^(NSDictionary *replyInfo, NSError *error) {
        // process reply data
        NSLog(@"listen request done: %@", replyInfo);
        [_listenButton setTitle:@"Listening"];
    }];
    
    checkResultTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkResultAvailable) userInfo:nil repeats:YES];
}

- (void)checkResultAvailable
{
    [WKInterfaceController openParentApplication:@{ } reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"received result: %@", replyInfo);
        if(replyInfo.count > 0)
        {
            isListening = NO;
            [checkResultTimer invalidate];
            [_listenButton setTitle:@"listen"];
            [self presentControllerWithName:@"ResultPage" context:replyInfo];
        }
    }];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



