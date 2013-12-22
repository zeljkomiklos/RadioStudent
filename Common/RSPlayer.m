
//
//  RSStreamer.m
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "RSPlayer.h"
#import "RSStreamer.h"
#import "Reachability.h"
#import "Constants.h"


@interface RSPlayer ()
{
    UIBackgroundTaskIdentifier _bgTask;
    
}

@property (nonatomic) BOOL disconnected;
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) RSStreamer *streamer;
@property (strong, nonatomic) Reachability *reachability;


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
    
    self.reachability = [Reachability reachabilityForInternetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    [_reachability startNotifier];

    _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)tearDown {
    [_reachability stopNotifier];
    
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
#ifdef DEBUG
    NSLog(@"RSPlayer: remoteControlReceivedWithEvent: %@", receivedEvent);
#endif

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


#pragma mark - Reachability

- (void)reachabilityChanged:(NSNotification *)notif {
    Reachability *reach = [notif object];
    
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    BOOL internetConnectionAvailable = (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN);
    
    if ([self isPlaying] && !internetConnectionAvailable) {
        self.disconnected = YES;
        
#ifdef DEBUG
        NSLog(@"RSPlayer: disconnected");
#endif
        return;
    }
    
    if (_disconnected && internetConnectionAvailable) {
        self.disconnected = NO;
        
#ifdef DEBUG
        NSLog(@"RSPlayer: retry connection in 3 secs");
#endif
        
        [NSTimer scheduledTimerWithTimeInterval:3
                                         target:self
                                       selector:@selector(start)
                                       userInfo:nil
                                        repeats:NO];
    }
}

@end
