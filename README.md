RadioStudent
============

RŠ for iPhone iOS 7+.


## Project specification

### Play audio stream.

#### Audio streams

mp3 stream 192kb/s: http://kruljo.radiostudent.si:8000/ehiq

mp3 stream 128kb/s: http://kruljo.radiostudent.si:8000/hiq


### Display list of feeds.

JSON feeds: http://radiostudent.si/json-mobile


### Display content of selected feed.

Feed url: http://radiostudent.si/{nodes.node[i].mb_link}



## Current implementation

mp3 stream 192kb/s: http://kruljo.radiostudent.si:8000/ehiq (beta!)

JSON feeds: http://radiostudent.si/json-mobile (beta!)

Feed url: http://radiostudent.si/{nodes.node[i].mb_link} (open URL in WebView - basic implementation!)



## Vendor code

a) https://github.com/alexcrichton/AudioStreamer

b) https://github.com/tonymillion/Reachability

c) https://github.com/TakahikoKawasaki/nv-ios-version



## In AppStore

Apple ID: 784484940

### Release 1.0 features

- play in background
- remote control events
- audio session interruption events
- robust http audio connection with many redelivery attempts.
