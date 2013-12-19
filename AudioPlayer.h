//
//  AudioStream.h
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol AudioPlayerDelegate;


@interface AudioPlayer : NSObject

@property (weak, nonatomic) id <AudioPlayerDelegate> delegate;

@property (readonly, nonatomic) BOOL isPlaying;

#
+ (AudioPlayer *)newInstance:(NSString *)url;

#
- (void)startPlaying;
- (void)stopPlaying;

@end


@protocol AudioPlayerDelegate

@optional

- (void)audioPlayer:(AudioPlayer *)audioPlayer didStartPlaying:(id)identifier;
- (void)audioPlayer:(AudioPlayer *)audioPlayer didStopPlaying:(id)identifier;
- (void)audioPlayer:(AudioPlayer *)audioPlayer didPausePlaying:(id)identifier;
- (void)audioPlayer:(AudioPlayer *)audioPlayer didResumePlaying:(id)identifier;
- (void)audioPlayer:(AudioPlayer *)audioPlayer didLoseSignal:(id)identifier;
- (void)audioPlayer:(AudioPlayer *)audioPlayer didWillRetryPlaying:(id)identifier;

@end

