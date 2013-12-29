
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


#define MAX_RETRY_ATTEMPTS 5
#define INITIAL_REDELIVERY_SECS 5

#if defined(DEBUG)
#define LOG(fmt, args...) NSLog(@"%s " fmt, __PRETTY_FUNCTION__, ##args)
#else
#define LOG(...)
#endif


@interface RobustPlayer ()
{
    UIBackgroundTaskIdentifier _bgTask;
    
}

@property (nonatomic) BOOL disconnected;
@property (nonatomic) BOOL playing;

@property (nonatomic) int retryAttemtp;
@property (weak, nonatomic) NSTimer *scheduledRetryAttempt;

@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) RobustHttpStreamer *streamer;
@property (strong, nonatomic) Reachability *wwanReachability;
@property (strong, nonatomic) Reachability *wifiReachability;

@end


NSString * const RPScheduledRetryAttemptChangedNotification = @"RPScheduledRetryAttemptChanged";

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

- (BOOL)retry {
    if(_playing) {
        if(_streamer.isPlaying) {
            return TRUE;
        }
        
        _retryAttemtp++;
        if(_retryAttemtp > MAX_RETRY_ATTEMPTS) {
            [_scheduledRetryAttempt invalidate];
            self.scheduledRetryAttempt = nil;
            
            LOG(@"Giveup retrying: [%@]", _url);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RPScheduledRetryAttemptChangedNotification object:self];
            return FALSE;
        }
        
        LOG(@"Retry attempt: %d! [%@]", _retryAttemtp, _url);
        
        if(_streamer != nil) {
            [_streamer stop];
            self.streamer = nil;
        }
        
        self.streamer = [RobustHttpStreamer streamWithURL:_url];
        
        return [_streamer start];
    }
    return FALSE;
}

- (BOOL)isPlaying {
    return _streamer.isPlaying;
}

- (BOOL)start {
    if(self.shouldStopBeforeStart) {
        [self stop];
        return FALSE;
    }
    
    self.streamer = [RobustHttpStreamer streamWithURL:_url];
    
    return [_streamer start];
}

- (void)stop {
    [self clearRetryAttempts];
    
    self.playing = FALSE;
    
    [_streamer stop];
    
    self.streamer = nil;
}

- (BOOL)shouldStopBeforeStart {
    return _streamer != nil && !_streamer.isPaused;
}


#pragma mark - Remote Control

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    LOG(@"RobustPlayer: remoteControlReceivedWithEvent: %@", receivedEvent);
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [_streamer togglePlayPause];
                break;
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlNextTrack:
            case UIEventSubtypeRemoteControlPreviousTrack:
                [_streamer play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [_streamer pause];
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
        LOG(@"RobustPlayer: network not reachable [%@]!", reach.currentReachabilityString);
        self.disconnected = TRUE;
        return;
    }
    
    LOG(@"RobustPlayer: network reachable [%@]!", reach.currentReachabilityString);
    
    if (_playing && _disconnected && connectionAvailable) {
        self.disconnected = NO;
        
        if(_scheduledRetryAttempt) {
            [_scheduledRetryAttempt invalidate];
            self.scheduledRetryAttempt = nil;
        }
        
        if(_retryAttemtp >= MAX_RETRY_ATTEMPTS) {
            LOG(@"Giveup retrying: [%@]", _url);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RPScheduledRetryAttemptChangedNotification object:self];
            return;
        }
        
        int secs =  (1 << _retryAttemtp) * INITIAL_REDELIVERY_SECS;
        
        LOG(@"RobustPlayer: retry connection in %d secs!", secs);
        
        self.scheduledRetryAttempt = [NSTimer scheduledTimerWithTimeInterval:secs
                                                                      target:self
                                                                    selector:@selector(retry)
                                                                    userInfo:nil
                                                                     repeats:NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RPScheduledRetryAttemptChangedNotification object:self];
    }
    
}


#pragma mark - AudioStreamer

- (RobustHttpStreamer *)streamer {
    return _streamer;
}

- (void)audioStreamerStatusChangedNotif:(NSNotification *)notif {
    RobustHttpStreamer *as = notif.object;
    
    if(as.isDone) {
        if(_playing && !_disconnected) {
            
            if(_scheduledRetryAttempt) {
                [_scheduledRetryAttempt invalidate];
                self.scheduledRetryAttempt = nil;
            }
            
            if(_retryAttemtp >= MAX_RETRY_ATTEMPTS) {
                LOG(@"Giveup retrying: [%@]", _url);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:RPScheduledRetryAttemptChangedNotification object:self];
                return;
            }
            
            int secs =  (1 << _retryAttemtp) * INITIAL_REDELIVERY_SECS;
            
            LOG(@"RobustPlayer: restart player in %d secs!", secs);
            
            self.scheduledRetryAttempt =[NSTimer scheduledTimerWithTimeInterval:secs
                                                                         target:self
                                                                       selector:@selector(retry)
                                                                       userInfo:nil
                                                                        repeats:NO];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RPScheduledRetryAttemptChangedNotification object:self];
        }
    } else if(as.isPlaying) {
        [self clearRetryAttempts];
        self.playing = TRUE;
    }
}


#pragma mark - Retry Attempts

- (void)clearRetryAttempts {
    self.retryAttemtp = 0;
    if(_scheduledRetryAttempt) {
        [_scheduledRetryAttempt invalidate];
        self.scheduledRetryAttempt = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RPScheduledRetryAttemptChangedNotification object:self];
    }
}

@end
