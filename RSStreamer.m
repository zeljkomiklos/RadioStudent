//
//  RSStreamer.m
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

@import AVFoundation;

#import "RSStreamer.h"

#define kDefaultNumAQBufs 32
#define kDefaultAQDefaultBufSize 4096


@interface RSStreamer ()

@property (nonatomic) BOOL pausedByInterruption;

@end


@implementation RSStreamer

#pragma mark - Lifecyle

+ (RSStreamer *)streamWithURL:(NSURL *)url {
    assert(url != nil);
    RSStreamer *stream = [[RSStreamer alloc] init];
    stream->url = url;
    stream->bufferCnt = kDefaultNumAQBufs;
    stream->bufferSize = kDefaultAQDefaultBufSize;
    stream->timeoutInterval = 15;
	return stream;
}


#pragma mark - Control

- (BOOL)start {
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
    [super stop];
    
    NSError *deactivationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:NO error:&deactivationError];
    if (!success) {
        NSLog(@"%@", [deactivationError localizedDescription]);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


#pragma mark - AVAudioSessionInterruptionNotification

- (void)interruptionOcurred:(NSNotification *)notif {
    NSInteger option = [notif.userInfo[AVAudioSessionInterruptionOptionKey] integerValue];
    switch (option) {
        case AVAudioSessionInterruptionTypeEnded: // iOS 7.0.4 - bug :: should be AVAudioSessionInterruptionTypeBegan
            NSLog(@"Case: interruption began!");
            if ([self isPlaying]) {
                [self pause];
                
                self.pausedByInterruption = YES;
            }
            break;
        case AVAudioSessionInterruptionTypeBegan: // iOS 7.0.4 - bug :: should be AVAudioSessionInterruptionTypeEnded
            NSLog(@"Case: interruption ended!");
            if ([self isPaused] && _pausedByInterruption) {
                [self play];
                
                self.pausedByInterruption = NO;
            }
            break;
        default:
            break;
    }
}

@end
