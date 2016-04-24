//
//  ResultInterfaceController.m
//  MusicSense
//
//  Created by Martijn de Vos on 21-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "ResultInterfaceController.h"

@interface ResultInterfaceController()

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *resultLabel;

@end


@implementation ResultInterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    NSDictionary *result = (NSDictionary *)context;
    
    if([result[@"has_result"] boolValue])
    {
        [_resultLabel setText:[NSString stringWithFormat:@"%@ - %@", result[@"song_artist"], result[@"song_name"]]];
    }
    else
    {
        [_resultLabel setText:@"This song could not be recognized. Please try again."];
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissController];
}

@end