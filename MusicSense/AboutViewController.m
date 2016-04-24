//
//  AboutViewController.m
//  MusicSense
//
//  Created by Martijn de Vos on 23/04/16.
//  Copyright © 2016 martijndevos. All rights reserved.
//

#import "AboutViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AboutViewController ()

@property(nonatomic, weak) IBOutlet UIButton *openReportButton;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.openReportButton.layer.masksToBounds = YES;
    self.openReportButton.layer.cornerRadius = 4.0f;
}

- (IBAction)didPressOpenReportButton:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://code-up.nl/wwdc/report.pdf"]];
}

@end