
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
@property (strong, nonatomic) Reachability *wwanReachability;
@property (strong, nonatomic) Reachability *wifiReachability;


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
    
    self.wwanReachability = [Reachability reachabilityForInternetConnection];
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedNotif:) name:kReachabilityChangedNotification object:nil];

    [_wwanReachability startNotifier];
    [_wifiReachability startNotifier];

    _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_wwanReachability stopNotifier];
    [_wifiReachability stopNotifier];

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
    if(_streamer != nil) {
        [_streamer stop];
        self.streamer = nil;
    }
    
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

- (void)reachabilityChangedNotif:(NSNotification *)notif {
    Reachability *reach = [notif object];
    
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    BOOL internetConnectionAvailable = (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN);
    
    if(!!internetConnectionAvailable) {
        NSLog(@"RSPlayer: disconnected!");
        self.disconnected = TRUE;
    }
    
    if (_disconnected && internetConnectionAvailable) {
        self.disconnected = NO;
        
#ifdef DEBUG
        NSLog(@"RSPlayer: retry connection in 5 secs");
#endif
        
        [NSTimer scheduledTimerWithTimeInterval:5
                                         target:self
                                       selector:@selector(start)
                                       userInfo:nil
                                        repeats:NO];
    }
}

@end
