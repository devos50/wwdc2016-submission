//
//  ViewController.m
//  MusicSense
//
//  Created by Martijn de Vos on 20-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "SenseViewController.h"
#import "Spectrogram.h"
#import <QuartzCore/QuartzCore.h>
#import "AudioRecorder.h"
#import "Configuration.h"
#import "Analyzer.h"
#import "AFNetworking.h"
#import "UIKit+AFNetworking/UIKit+AFNetworking.h"

@interface SenseViewController ()

@property(nonatomic, weak) IBOutlet UIImageView *spectrogramImageView;
@property(nonatomic, weak) IBOutlet UILabel *warningLabel;
@property(nonatomic, weak) IBOutlet UILabel *resultLabel;
@property(nonatomic, weak) IBOutlet UILabel *hintLabel1;
@property(nonatomic, weak) IBOutlet UILabel *hintLabel2;

@end

@implementation SenseViewController
{
    UIButton *listenButton;
    Configuration *config;
    BOOL isListening;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    config = [Configuration new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMatchingResult:) name:@"nl.tudelft.MusicSense.HasResult" object:nil];
    
    listenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    listenButton.frame = CGRectMake(self.view.frame.size.width / 2 - 75, self.view.frame.size.height / 2 - 75 - 30, 150, 150);
    [listenButton setTitle:@"Listen" forState:UIControlStateNormal];
    listenButton.backgroundColor = [UIColor colorWithRed:73.0/255.0 green:93.0/255.0 blue:0 alpha:1];
    [listenButton addTarget:self action:@selector(startRecording) forControlEvents:UIControlEventTouchUpInside];
    
    listenButton.layer.cornerRadius = listenButton.frame.size.width / 2;
    listenButton.clipsToBounds = YES;
    listenButton.layer.borderColor = [UIColor colorWithRed:102.0/255.0 green:153.0/255.0 blue:0.0 alpha:1.0].CGColor;
    listenButton.layer.borderWidth = 10.0f;
    
    [self.view addSubview:listenButton];
    
    //_spectrogramImageView.layer.borderColor = [UIColor blackColor].CGColor;
    //_spectrogramImageView.layer.borderWidth = 1.0f;
    //_spectrogramImageView.hidden = true;
    
    if(config.useRawFolder) { [self analyzeFileFromBundle:@"thedays-orig" isInDocuments:false]; }
}

- (void)receivedMatchingResult:(NSNotification *)notification
{
    NSDictionary *resultDict = notification.userInfo[@"result"];
    if([resultDict[@"has_result"] boolValue])
    {
        [self showAlbumCoverWithSongId:resultDict[@"song_id"]];
        self.resultLabel.text = [NSString stringWithFormat:@"%@ - %@", resultDict[@"song_artist"], resultDict[@"song_name"]];
    }
    else
    {
        self.resultLabel.text = @"This song could not be recognized.";
    }
}

- (void)showAlbumCoverWithSongId:(NSString *)songId
{
    [_spectrogramImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://musicsense.no-ip.org/covers/%@.png", songId]]];
    _spectrogramImageView.alpha = 0;
    _spectrogramImageView.hidden = NO;
    
    // fade the spectrogram image view in
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _spectrogramImageView.alpha = 1.0;
    } completion:nil];
}

- (void)analyzeFileFromBundle:(NSString *)filename isInDocuments:(BOOL)inDocuments
{
    self.resultLabel.text = @"Analyzing...";
    Analyzer *analyzer = [[Analyzer alloc] initWithFileFromBundle:filename isInDocuments:inDocuments andWithConfiguration:config];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        listenButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        [listenButton setFrame:CGRectMake(listenButton.frame.origin.x, _spectrogramImageView.frame.origin.y + _spectrogramImageView.frame.size.height + 20, 150, 150)];
    } completion:nil];
    
    [listenButton setTitle:@"Listen" forState:UIControlStateNormal];
}

-(IBAction) startRecording
{
    if(isListening) { return; }
    NSLog(@"startRecording");
    
    self.resultLabel.text = @"";
    isListening = YES;
    
    // hide the spectrogram
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _spectrogramImageView.alpha = 0.0;
    } completion:nil];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        listenButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        [listenButton setFrame:CGRectMake(self.view.frame.size.width / 2 - 75, self.view.frame.size.height / 2 - 75 - 30, 150, 150)];
    } completion:^(BOOL finished) {
        [self growListenButton];
    }];
    
    _warningLabel.hidden = YES;
    _hintLabel1.hidden = YES;
    _hintLabel2.hidden = YES;
    
    [AudioRecorder startRecording];
    
    [self performSelector:@selector(stopRecording) withObject:self afterDelay:((float)config.recordingDuration / 1000.0)];
    [listenButton setTitle:@"Listening..." forState:UIControlStateNormal];
    NSLog(@"recording");
}

- (void)stopRecording
{
    [AudioRecorder stopRecording];
    isListening = NO;
    [listenButton setTitle:@"Sensing..." forState:UIControlStateNormal];
    [self analyzeFileFromBundle:@"record" isInDocuments:true];
}

- (void)playRecording
{
    [AudioRecorder playRecording];
}

- (void)growListenButton
{
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        listenButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [self shrinkListenButton];
    }];
}

- (void)shrinkListenButton
{
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        listenButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        if(isListening) { [self growListenButton]; }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
