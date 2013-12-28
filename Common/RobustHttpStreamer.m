//
//  RSStreamer.m
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

@import AVFoundation;

#import "RobustHttpStreamer.h"
#import "Constants.h"
#import "Version.h"

#define RSDefaultNumAQBufs 128
#define RSDefaultAQDefaultBufSize 4096


@interface RobustHttpStreamer ()

@property (nonatomic) BOOL pausedByInterruption;
@property (strong, nonatomic) Version *version;

@end


@implementation RobustHttpStreamer

#pragma mark - Lifecyle

+ (RobustHttpStreamer *)streamWithURL:(NSURL *)url {
    assert(url != nil);
    RobustHttpStreamer *stream = [[RobustHttpStreamer alloc] init];
    stream->url = url;
    stream->bufferCnt = RSDefaultNumAQBufs;
    stream->bufferSize = RSDefaultAQDefaultBufSize;
    stream->timeoutInterval = 15;
	return stream;
}

- (id)init {
    if((self = [super init]) == nil) return nil;
    
    self.version = [[Version alloc] initWithString:[[UIDevice currentDevice] systemVersion]];
    
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - State

- (AudioStreamerState)state {
    return state_;
}


#pragma mark - Control

- (BOOL)start {
#ifdef DEBUG
    NSLog(@"RobustHttpStreamer: start");
#endif

    if(![super start]) {
        return NO;
    }
    
    BOOL success;
    
    NSError *error = nil;
    success = [ [AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                      error:&error];
    if (!success) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    success = [ [AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionOcurred:) name:AVAudioSessionInterruptionNotification object:nil];
    
    return TRUE;
}

- (void)stop {
#ifdef DEBUG
    NSLog(@"RobustHttpStreamer: stop");
#endif
    
    [super stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    
    NSError *deactivationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:NO error:&deactivationError];
    if(!success) {
        NSLog(@"%@", [deactivationError localizedDescription]);
    }
}

- (BOOL)togglePlayPause {
    if(_pausedByInterruption) {
        return FALSE;
    }
    
    if([self isPaused]) {
        [self play];
        return TRUE;
    }
    
    [self pause];
    return FALSE;
}

- (BOOL)play {
#ifdef DEBUG
    NSLog(@"RobustHttpStreamer: play");
#endif
    return [super play];
}

- (BOOL)pause {
#ifdef DEBUG
    NSLog(@"RobustHttpStreamer: pause");
#endif
    return [super pause];
}


#pragma mark - AVAudioSessionInterruptionNotification

- (void)interruptionOcurred:(NSNotification *)notif {
    NSInteger option = [notif.userInfo[AVAudioSessionInterruptionOptionKey] integerValue];
    if(_version.major == 7 && _version.minor == 0 && _version.micro <= 4) {
        // iOS [7.0.0 -> 7.0.4] - options mishmash bug
        switch (option) {
            case AVAudioSessionInterruptionTypeEnded: // actually - AVAudioSessionInterruptionTypeBegan
#ifdef DEBUG
                NSLog(@"RobustHttpStreamer: interruption began");
#endif
                if ([self isPlaying]) {
                    [self pause];
                    
                    self.pausedByInterruption = YES;
                }
                break;
            case AVAudioSessionInterruptionTypeBegan: // actually - AVAudioSessionInterruptionTypeEnded
#ifdef DEBUG
                NSLog(@"RobustHttpStreamer: interruption ended");
#endif
                if ([self isPaused] && _pausedByInterruption) {
                    [self play];
                    
                    self.pausedByInterruption = NO;
                }
                break;
            default:
                break;
        }
    } else {
        switch (option) {
            case AVAudioSessionInterruptionTypeBegan:
#ifdef DEBUG
                NSLog(@"RobustHttpStreamer: interruption began");
#endif
                if ([self isPlaying]) {
                    [self pause];
                    
                    self.pausedByInterruption = YES;
                }
                break;
            case AVAudioSessionInterruptionTypeEnded:
#ifdef DEBUG
                NSLog(@"RobustHttpStreamer: interruption ended");
#endif
                if ([self isPaused] && _pausedByInterruption) {
                    [self play];
                    
                    self.pausedByInterruption = NO;
                }
                break;
            default:
                break;
        }
    }
}

@end
