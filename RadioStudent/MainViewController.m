//
//  MainViewController.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "RSPlayer.h"
#import "RSFeeds.h"


@interface MainViewController ()

@property (strong, nonatomic) RSPlayer *player;
@property (strong, nonatomic) RSFeeds *feeds;

@end


@implementation MainViewController


#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self == nil) {
        return nil;
    }
    return self;
}

- (void)dealloc {
    [_player tearDown];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [RSPlayer playerWithURL:[NSURL URLWithString:RS_LIVE_STREAM_URL]];
    self.feeds = [RSFeeds feedsWithURL:[NSURL URLWithString:RS_FEEDS_URL]];
    
    [_player wakeUp];
}

- (void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsLoadedNotif:) name:RS_FEEDS_LOADED_NOTIF object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Bindings

- (IBAction)playStopAction:(id)sender {
    if(_player.isPlaying) {
        [_player stop];
    } else {
        [_feeds fetch];
        [_player start];
    }
}


#pragma mark - Feeds

- (void)feedsLoadedNotif:(NSNotification *)notif {
    NSLog(@"Feeds: %@", _feeds.feeds);
}


#pragma mark - Remote Events

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    [_player remoteControlReceivedWithEvent:(UIEvent *)receivedEvent];
}

@end
