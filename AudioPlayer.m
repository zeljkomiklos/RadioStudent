//
//  AudioStream.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "AudioPlayer.h"
#import "FSAudioStream.h"
#import "Constants.h"

@interface AudioPlayer ()
{
}

@property (strong, nonatomic) FSAudioStream *audioStream;
@property (strong, nonatomic) NSURL *audioUrl;

@end

@implementation AudioPlayer

#pragma mark - Factory

+ (AudioPlayer *)newInstance:(NSString *)url {
    return [[AudioPlayer alloc] initWithUrl:url];
}

- (id)initWithUrl:(NSString *)url {
    self.audioUrl = [NSURL URLWithString:url];
    
    self.audioStream = [[FSAudioStream alloc] initWithUrl:[[NSURL alloc] initWithString:RS_LIVE_STREAM_URL]];
    
    return self;
}


#pragma mark - Control

- (BOOL)isPlaying {
    return self.audioStream.isPlaying;
}

- (void)startPlaying {
    [self.audioStream play];
}

- (void)stopPlaying {
    [self.audioStream stop];
    
}

@end
