//
//  RSStreamer.h
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "AudioStreamer.h"


extern NSString * const RPScheduledRetryAttemptChangedNotification;


@class RobustHttpStreamer;

@interface RobustPlayer : NSObject

@property (readonly) BOOL isPlaying;
@property (readonly, nonatomic) NSTimer *scheduledRetryAttempt;

@property (readonly, nonatomic) RobustHttpStreamer *streamer;

+ (RobustPlayer *)playerWithURL:(NSURL *)url;

- (void)wakeUp;
- (void)tearDown;

- (BOOL)start;
- (void)stop;

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;


@end
