//
//  ArticleController.m
//  RadioStudent
//
//  Created by tigor on 23. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "WebArticleController.h"
#import "Constants.h"

@interface WebArticleController ()

@end

@implementation WebArticleController


#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = FALSE;
    self.navigationItem.title = _feed[@"title"];
    self.navigationController.navigationBar.backItem.title = @"RŠ";
}

- (void)viewDidAppear:(BOOL)animated {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", RS_HOST_URL, _feed[@"mb_link"]]];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
