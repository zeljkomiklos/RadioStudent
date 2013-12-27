
//
//  RSStreamer.m
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "RobustPlayer.h"
#import "RobustHttpStreamer.h"
#import "Reachability.h"
#import "Constants.h"


#define MAX_RESTART_ATTEMPTS 5
#define INITIAL_REDELIVERY_SECS 5

@interface RobustPlayer ()
{
    UIBackgroundTaskIdentifier _bgTask;
    
}

@property (nonatomic) BOOL disconnected;
@property (nonatomic) BOOL started;
@property (nonatomic) int restartAttemtp;

@property (weak, nonatomic) NSTimer *scheduledRestartAttempt;
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) RobustHttpStreamer *streamer;
@property (strong, nonatomic) Reachability *wwanReachability;
@property (strong, nonatomic) Reachability *wifiReachability;



@end

@implementation RobustPlayer

#pragma mark - Lifecycle

- (id)initWithURL:(NSURL *)url {
    if((self = [super init]) == nil) return nil;
    
    self.url = url;
    
    _bgTask = UIBackgroundTaskInvalid;
    
    return self;
}

+ (RobustPlayer *)playerWithURL:(NSURL *)url {
    return [[RobustPlayer alloc] initWithURL:url];
}


- (void)wakeUp {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.wwanReachability = [Reachability reachabilityForInternetConnection];
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedNotif:) name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerStatusChangedNotif:) name:ASStatusChangedNotification object:nil];
    
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

- (BOOL)restart {
    if(_started) {

        if(_streamer.isPlaying) {
            return TRUE;
        }
        
        _restartAttemtp++;
        if(_restartAttemtp <= MAX_RESTART_ATTEMPTS) {
            NSLog(@"Restart attempt: %d! [%@]", _restartAttemtp, _url);
            
            if(_streamer != nil) {
                [_streamer stop];
                self.streamer = nil;
            }

            self.streamer = [RobustHttpStreamer streamWithURL:_url];
            
            return [_streamer start];
        }
    }
    return FALSE;
}

- (BOOL)start {
    if(_streamer != nil) {
        [self stop];
    }
    
    self.streamer = [RobustHttpStreamer streamWithURL:_url];
    
    return [_streamer start];
}

- (void)stop {
    [self clearRestartAttempts];
    
    self.started = FALSE;
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
    BOOL connectionAvailable = (netStatus == ReachableViaWiFi || netStatus == ReachableViaWWAN);
    
    if(!connectionAvailable) {
        NSLog(@"RSPlayer: network not reachable!");
        self.disconnected = TRUE;
    }
    
    if (_disconnected && connectionAvailable && _restartAttemtp < MAX_RESTART_ATTEMPTS) {
        self.disconnected = NO;
        
        int secs =  (1 << _restartAttemtp) * INITIAL_REDELIVERY_SECS;
        
        if(_scheduledRestartAttempt) {
#ifdef DEBUG
            NSLog(@"RSPlayer: invalidating scheduled restart attempt!");
#endif
            [_scheduledRestartAttempt invalidate];
        }
        
#ifdef DEBUG
        NSLog(@"RSPlayer: retry connection in %d secs!", secs);
#endif
        
        self.scheduledRestartAttempt = [NSTimer scheduledTimerWithTimeInterval:secs
                                                                        target:self
                                                                      selector:@selector(restart)
                                                                      userInfo:nil
                                                                       repeats:NO];
    }
}


#pragma mark - AudioStreamer

- (void)audioStreamerStatusChangedNotif:(NSNotification *)notif {
    RobustHttpStreamer *as = notif.object;
    if(as.isDone) {
        if(_started && !_disconnected && _restartAttemtp < MAX_RESTART_ATTEMPTS) {
            int secs =  (1 << _restartAttemtp) * INITIAL_REDELIVERY_SECS;
            
            if(_scheduledRestartAttempt) {
#ifdef DEBUG
                NSLog(@"RSPlayer: invalidating scheduled restart attempt!");
#endif
                [_scheduledRestartAttempt invalidate];
            }
            
#ifdef DEBUG
            NSLog(@"RSPlayer: [AudioStreamer.status=%d]", as.state);
            NSLog(@"RSPlayer: [AudioStreamer.error=%@]", [AudioStreamer stringForErrorCode:as.errorCode]);
            NSLog(@"RSPlayer: restart player in %d secs!", secs);
#endif
            
            self.scheduledRestartAttempt =[NSTimer scheduledTimerWithTimeInterval:secs
                                                                           target:self
                                                                         selector:@selector(restart)
                                                                         userInfo:nil
                                                                          repeats:NO];
        }
    } else if(as.isPlaying) {
        [self clearRestartAttempts];
        self.started = TRUE;
    }
}


#pragma mark - Reset

- (void)clearRestartAttempts {
    self.restartAttemtp = 0;
    if(_scheduledRestartAttempt != nil) {
        [_scheduledRestartAttempt invalidate];
        _scheduledRestartAttempt = nil;
    }
}

@end
