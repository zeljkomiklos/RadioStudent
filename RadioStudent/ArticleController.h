//
//  ArticleController.h
//  RadioStudent
//
//  Created by tigor on 23. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArticleController : UIViewController

@property (strong, nonatomic) NSDictionary *feed;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
