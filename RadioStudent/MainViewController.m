//
//  MainViewController.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "AudioPlayer.h"


@interface MainViewController () <AudioPlayerDelegate>

@property (strong, nonatomic) AudioPlayer *audioPlayer;

@end


@implementation MainViewController


#pragma mark - Lifecycle methods

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self == nil) {
        return nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioPlayer = [AudioPlayer newInstance:RS_LIVE_STREAM_URL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Bindings

- (IBAction)playStopAction:(id)sender {
    if(_audioPlayer.isPlaying) {
        [_audioPlayer stopPlaying];
    } else {
        [_audioPlayer startPlaying];
    }
}


@end
