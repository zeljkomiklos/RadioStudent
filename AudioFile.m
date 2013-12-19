#import "AudioFile.h"

@interface AudioFile ()
{
    AudioFileID						_fileID;
    AudioStreamBasicDescription		_format;
    UInt64							_packetsCount;
    UInt32							_maxPacketSize;
}

@end

@implementation AudioFile

- (id)initWithURL:(CFURLRef)url {
    if (self = [super init]){
        AudioFileOpenURL(
                         url,
                         0x01, //fsRdPerm, read only
                         0, //no hint
                         &_fileID
                         );
        
        UInt32 sizeOfPlaybackFormatASBDStruct = sizeof _format;
        AudioFileGetProperty (
                              _fileID,
                              kAudioFilePropertyDataFormat,
                              &sizeOfPlaybackFormatASBDStruct,
                              &_format
                              );
        
        UInt32 propertySize = sizeof (_maxPacketSize);
        
        AudioFileGetProperty (
                              _fileID,
                              kAudioFilePropertyMaximumPacketSize,
                              &propertySize,
                              &_maxPacketSize
                              );
        
        propertySize = sizeof(_packetsCount);
        AudioFileGetProperty(_fileID, kAudioFilePropertyAudioDataPacketCount, &propertySize, &_packetsCount);
    }
    return self;
}

- (AudioFileID)fileID {
    return _fileID;
}

- (UInt64)packetsCount {
    return _packetsCount;
}

- (UInt32)maxPacketSize {
    return _maxPacketSize;
}

- (AudioStreamBasicDescription *)audioFormatRef {
    return &_format;
}

- (void) dealloc {
    AudioFileClose(_fileID);
}

@end