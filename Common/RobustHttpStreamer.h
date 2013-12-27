//
//  RSStreamer.h
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "AudioStreamer.h"

@interface RobustHttpStreamer : AudioStreamer

@property (readonly) BOOL pausedByInterruption;
@property (readonly) AudioStreamerState state;

+ (RobustHttpStreamer *)streamWithURL:(NSURL *)url;

- (BOOL)togglePlayPause;



@end
