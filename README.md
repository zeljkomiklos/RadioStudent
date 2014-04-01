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

mp3 stream 192kb/s: http://kruljo.radiostudent.si:8000/ehiq

JSON feeds: http://radiostudent.si/json-mobile

Feed url: http://radiostudent.si/{nodes.node[i].mb_link} (UIWebView)



## Vendor code

a) https://github.com/alexcrichton/AudioStreamer

b) https://github.com/tonymillion/Reachability


## In AppStore

App Name: RŠ

Apple ID: 784484940

### Release 1.0 description

Player of our favorite radio station in Ljubljana, Slovenia. 
Features: 
- play in background 
- remote control support 
- audio session interruption support 
- robust http audio connection with many redelivery attempts 

Established in 1969 by the Student Organization of the University of Ljubljana, the legendary Radio Študent (RŠ) is one of Europe's oldest and strongest non-commercial, alternative urban radio stations, attracting over 200 contributors to its high-quality non-commercial programming every year. RŠ is based in Ljubljana, the capital of Slovenia, until its declaration of independence in June 1991 the most developed republic of SFRJ (Socialist Federal Republic of Yugoslavia) and the member of EU since 1 May 2004, bordered by Italy, Austria, Hungary and Croatia.

The Radio Student homepage address is www.radiostudent.si. It is broadcast on 89.3 MHz (500 W) UKV stereo, covering Ljubljana and its surroundings (500,000 potential listeners).

In the history of Slovene radio broadcasting RŠ stands out as the foremost presenter and critical evaluator of actual global music events with its characteristic form of music criticism, heartfelt and absorbed presentation of liminal, edgy, marginalised and socially provocative music from the world, ranging from all alternative forms of rock, contemporary DJ and electronic music, jazz and improvised music, avant-garde and folk music, experimental music etc.

Due to the variety and range of these contributors, many innovative cultural, political and social initiatives have sprung from the activities of Radio Študent. RŠ programming policy fuses community radio and public service concepts. From its earliest days the station has promoted civil society initiatives, particularly in connection with urban lifestyles, freedom of speech, independent thought, libertarian values, cultural diversity, social critique, tolerance, social solidarity and human rights.

### Release 1.0.1 

Bug fixes.
