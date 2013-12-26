//
//  MainViewController.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "AudioStreamer.h"
#import "RSPlayer.h"
#import "RSFeeds.h"
#import "RSImage.h"

#import "WebArticleController.h"

#define TITLE_FONT_SIZE 15
#define SUBTITLE_FONT_SIZE 14
#define AUDIO_STREAM_DONE  @"Touch Me!"
#define AUDIO_STREAM_WAITING @"Buffering..."
#define AUDIO_STREAM_PLAYING @"Don't touch me!"
#define AUDIO_STREAM_PAUSED @"Paused!"

@interface MainViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) RSPlayer *player;
@property (strong, nonatomic) RSFeeds *feeds;
@property (strong, nonatomic) NSString *error;
@property (strong, nonatomic) NSString *statusInfo;
@property (strong, nonatomic) NSDictionary *presentingFeed;
@property (nonatomic) UIInterfaceOrientation orientation;

@end


@implementation MainViewController


#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self == nil) {
        return nil;
    }
    return self;
}

- (void)dealloc {
    [_player tearDown];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [RSPlayer playerWithURL:[NSURL URLWithString:RS_LIVE_STREAM_URL]];
    self.feeds = [RSFeeds feedsWithURL:[NSURL URLWithString:RS_FEEDS_URL]];
    
    [_player wakeUp];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    self.statusInfo = AUDIO_STREAM_DONE;
    self.orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = TRUE;
    self.navigationController.navigationBar.backItem.title = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsLoadedNotif:) name:RS_FEEDS_LOADED_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoadedNotif:) name:RS_IMAGE_LOADED_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerErrorNotif:) name:AUDIO_STREAMER_ERROR_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerPlayingNotif:) name:AUDIO_STREAMER_PLAYING_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerStatusChangedNotif:) name:ASStatusChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Navigation

- (void)presentWebArticle:(NSDictionary *)feed {
    self.presentingFeed = feed;
    [self performSegueWithIdentifier:@"pushWebArticle" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"pushWebArticle"]) {
        WebArticleController *controller = (WebArticleController *)segue.destinationViewController;
        controller.feed = _presentingFeed;
        self.presentingFeed = nil;
    } else if([segue.identifier isEqualToString:@"pushArticle"]) {
        WebArticleController *controller = (WebArticleController *)segue.destinationViewController;
        controller.feed = _presentingFeed;
        self.presentingFeed = nil;
    }
    
}


#pragma mark - Bindings

- (IBAction)playStopAction:(id)sender {
    self.error = nil;
    if(_player.isPlaying) {
        [_player stop];
    } else {
        [_feeds fetch];
        [_player start];
    }
}


#pragma mark - Feeds

- (void)feedsLoadedNotif:(NSNotification *)notif {
#ifdef DEBUG
    NSLog(@"Feeds: %@", _feeds.feeds);
#endif
    [self updateUi];
}

- (void)imageLoadedNotif:(NSNotification *)notif {
#ifdef DEBUG
    NSLog(@"Image loaded: %@", notif.userInfo[@"url"]);
#endif
    [self updateUi];
}

- (void)audioStreamerPlayingNotif:(NSNotification *)notif {
    self.error = nil;
    [self updateUi];
}

- (void)audioStreamerStatusChangedNotif:(NSNotification *)notif {
    AudioStreamer *as = notif.object;
    if(as.isDone) {
        self.statusInfo = AUDIO_STREAM_DONE;
    } else if(as.isPaused) {
        self.statusInfo = AUDIO_STREAM_PAUSED;
    } else if(as.isWaiting) {
        self.statusInfo = AUDIO_STREAM_WAITING;
    } else if(as.isPlaying) {
        self.statusInfo = AUDIO_STREAM_PLAYING;
    }
    [self updateUi];
}

- (void)audioStreamerErrorNotif:(NSNotification *)notif {
    self.error = notif.userInfo[@"info"];
    [self updateUi];
}


#pragma mark - Remote Events

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    [_player remoteControlReceivedWithEvent:(UIEvent *)receivedEvent];
}


#pragma mark - UIViewControllerRotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:orientation duration:duration];
    self.orientation = orientation;
    [((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout) invalidateLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)
        || (orientation == UIInterfaceOrientationPortrait)) {
        [_collectionView reloadData];
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _feeds.feeds.count * 3; // image & feed cells
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if (kind != UICollectionElementKindSectionHeader) {
        return nil;
    }
    
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                        withReuseIdentifier:@"NavigationView" forIndexPath:indexPath];
    
    UILabel *statusLabel = (UILabel *)[view viewWithTag:1];
    statusLabel.text = [self statusText];
    
    UIButton *playButton = (UIButton *)[view viewWithTag:2];
    [playButton addTarget:self action:@selector(playStopAction:) forControlEvents:UIControlEventTouchDown];
    
    UIView *bgView = [view viewWithTag:3];
    if(_player.isPlaying) {
        bgView.backgroundColor = [UIColor orangeColor];
    } else {
        bgView.backgroundColor = [UIColor clearColor];
    }
    
    return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger _feedIndex = indexPath.row / 3;
    
    NSDictionary *feed = _feeds.feeds[_feedIndex][@"node"];
    if((indexPath.row % 3) == 0) {
        // 0, 3, ... title
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TitleCell" forIndexPath:indexPath];
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
        titleLabel.text = feed[@"title"];
        
        if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            titleLabel.font = [titleLabel.font fontWithSize:TITLE_FONT_SIZE * 1.2];
        } else {
            titleLabel.font = [titleLabel.font fontWithSize:TITLE_FONT_SIZE];
        }
        return cell;
    }
    if((indexPath.row % 3) == 1) {
        // 1, 4, ... icons
        NSString *key = feed[@"mb_image"];
        RSImage *icon = _feeds.icons[key];
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IconCell" forIndexPath:indexPath];
        if(icon.image != nil) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
            imageView.image = icon.image;
        }
        
        return cell;
    }
    
    // 2, 5, ... subtitles
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SubtitleCell" forIndexPath:indexPath];
    
    UITextView *subtitleView = (UITextView *)[cell viewWithTag:1];
    subtitleView.text = feed[@"mb_subtitle"];
   
    subtitleView.editable = TRUE;
    if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        subtitleView.font = [subtitleView.font fontWithSize:SUBTITLE_FONT_SIZE * 1.2];
    } else {
        subtitleView.font = [subtitleView.font fontWithSize:SUBTITLE_FONT_SIZE];
    }
    subtitleView.editable = FALSE;
    
    return cell;
    
}


#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat w = [[self class] totalContentWidth:collectionView layout:collectionViewLayout cellCount:2];
    
    if(UIDeviceOrientationIsPortrait(_orientation)) {
        if((indexPath.row % 3) == 0) {
            return CGSizeMake(w, 50); // title size
        }
        if((indexPath.row % 3) == 1) {
            return CGSizeMake(90, 80); // image size
        }
        return CGSizeMake(w - 90, 80); // subtitle size
    }
    
    // landscape
    
    if((indexPath.row % 3) == 0) {
        return CGSizeMake(w, 50); // title size
    }
    
    if((indexPath.row % 3) == 1) {
        return CGSizeMake(130, 90); // image size
    }
    
    return CGSizeMake(w - 130, 90); // subtitle size
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *feed = _feeds.feeds[indexPath.row / 3][@"node"];
    [self presentWebArticle:feed];
}


#pragma mark - Private

- (void)updateUi {
    [_collectionView reloadData];
}

- (NSString *)statusText {
    if(_error) {
        return [NSString stringWithFormat:@"%@ [%@]", _statusInfo, _error];
    }
    return [NSString stringWithFormat:@"%@", _statusInfo];
}


#pragma mark - Helpers

+ (CGFloat)totalContentWidth:(UICollectionView *)collectionView  layout:(UICollectionViewFlowLayout *)layout cellCount:(NSUInteger)itemCount {
    return CGRectGetWidth(collectionView.frame) - layout.sectionInset.left - layout.sectionInset.right - (itemCount - 1) * layout.minimumInteritemSpacing;
}



@end
