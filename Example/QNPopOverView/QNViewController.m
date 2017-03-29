//
//  QNViewController.m
//  QNPopOverView
//
//  Created by gitph101 on 03/28/2017.
//  Copyright (c) 2017 gitph101. All rights reserved.
//

#import "QNViewController.h"
#import "QNContentView.h"

@interface QNViewController ()

@property (nonatomic, strong) QNContentView *contentView;

@end

@implementation QNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.contentView];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (QNContentView *)contentView{
    if (!_contentView) {
        _contentView = [[QNContentView alloc] initWithFrame:[[self view] bounds]];
    }
    return _contentView;
}


@end
