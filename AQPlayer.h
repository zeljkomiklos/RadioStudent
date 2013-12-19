#import <Foundation/Foundation.h>
#import "AudioFile.h"


#define AUDIOBUFFERS_NUMBER	 3
#define MAX_PACKET_COUNT	4096


@interface AQPlayer : NSObject

@property (readonly)				SInt64			currentPacketNumber;
@property (strong, nonatomic)		AudioFile		*audioFile;

- (id)initWithFile:(NSString *)file;

- (void)play;

@end
