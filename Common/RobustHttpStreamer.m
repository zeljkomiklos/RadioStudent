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

#if defined(DEBUG)
#define LOG(fmt, args...) NSLog(@"%s " fmt, __PRETTY_FUNCTION__, ##args)
#else
#define LOG(...)
#endif

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
    
    success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruptionOccured:)
                                                 name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    
    return TRUE;
}

- (void)stop {
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
    return [super play];
}

- (BOOL)pause {
    return [super pause];
}


#pragma mark - AVAudioSessionInterruptionNotification

- (void)audioSessionInterruptionOccured:(NSNotification *)notif {
    NSNumber *n = notif.userInfo[AVAudioSessionInterruptionTypeKey];
    if(n == nil) {
        return;
    }
    
    NSUInteger type =  n.unsignedIntegerValue;
    switch (type) {
        case AVAudioSessionInterruptionTypeBegan:
            LOG(@"Interruption began");
            if ([self isPlaying]) {
                [self pause];
                
                self.pausedByInterruption = YES;
            }
            break;
        case AVAudioSessionInterruptionTypeEnded:
            LOG(@"Interruption ended");
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
