//
//  SGViewController.h
//  SouZhen
//
//  Created by chenwang on 13-8-17.
//  Copyright (c) 2013年 songguo. All rights reserved.
//

#import "YMCoverViewController.h"

@interface SGViewController : YMCoverViewController

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) NSString *viewBundleName;
@property (nonatomic) BOOL navigationBarHidden;

@end
