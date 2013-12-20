
//
//  RSStreamer.m
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "RSPlayer.h"
#import "RSStreamer.h"

@interface RSPlayer ()
{
    UIBackgroundTaskIdentifier _bgTask;
}


@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) RSStreamer *streamer;

@end

@implementation RSPlayer

#pragma mark - Lifecycle

- (id)initWithURL:(NSURL *)url {
    if((self = [super init]) == nil) return nil;
    
    self.url = url;
    
    _bgTask = UIBackgroundTaskInvalid;
    
    return self;
}

+ (RSPlayer *)playerWithURL:(NSURL *)url {
    return [[RSPlayer alloc] initWithURL:url];
}


- (void)wakeUp {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)tearDown {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    if(_bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
    }
    
    [self stop];
    
    self.streamer = nil;
}


#pragma mark - Control

- (BOOL)isPlaying {
    return _streamer.isPlaying;
}

- (BOOL)start {
    self.streamer = [RSStreamer streamWithURL:_url];

    return [_streamer start];
}

- (void)stop {
    [_streamer stop];
    
    self.streamer = nil;
}


#pragma mark - Remote Control

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [_streamer togglePlayPause];
                break;
            default:
                break;
        }
    }
}

@end
