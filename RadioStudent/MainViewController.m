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


@interface MainViewController ()

@property (strong, nonatomic) RSPlayer *player;

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
    
    [_player wakeUp];
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
        [_player start];
    }
}


#pragma mark - Remote Events

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    [_player remoteControlReceivedWithEvent:(UIEvent *)receivedEvent];
}



@end
