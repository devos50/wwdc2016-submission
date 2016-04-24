//
//  HistoryTableViewController.m
//  MusicSense
//
//  Created by Martijn de Vos on 10-06-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

#import "HistoryTableViewController.h"
#import "AFNetworking.h"
#import "SVProgressHUD.h"
#import "UIKit+AFNetworking/UIKit+AFNetworking.h"

@implementation HistoryTableViewController
{
    NSArray *history;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadHistory];
}

- (void)loadHistory
{
    [SVProgressHUD showWithStatus:@"Loading"];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:@"http://musicsense.no-ip.org/historyapp" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        history = responseObject;
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
        [SVProgressHUD dismiss];
        UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"An error has occurred when fetching the history." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [errorAlertView show];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return history.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HistoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UILabel *mainLabel = [cell viewWithTag:1];
    UILabel *detailLabel = [cell viewWithTag:2];
    UIImageView *coverImageView = [cell viewWithTag:3];
    
    NSDictionary *songInfo = history[indexPath.row];
    mainLabel.text = [NSString stringWithFormat:@"%@ - %@", songInfo[@"song"][@"artist"], songInfo[@"song"][@"name"]];
    detailLabel.text = [NSString stringWithFormat:@"%@ - analyzing took %.2f sec", songInfo[@"date"], [songInfo[@"duration"] floatValue] / 1000.0f];
    
    [coverImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://musicsense.no-ip.org/covers/%@_thumb.png", songInfo[@"song"][@"id"]]]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

@end
