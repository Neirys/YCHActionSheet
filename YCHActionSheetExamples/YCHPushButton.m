//
//  YCHPushButton.m
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 24/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import "YCHPushButton.h"

@interface YCHPushButton ()
{
    UIButton *_button;
}

@end

@implementation YCHPushButton

- (instancetype)initWithTitle:(NSString *)buttonTitle frame:(CGRect)frame
{
    if (self = [super init])
    {
        self.userInteractionEnabled = YES;
        
        UIImage *bgNormal = [[UIImage imageNamed:@"bg_50"]
                             resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
        UIImage *bgSelected = [[UIImage imageNamed:@"bg_50_selected"]
                               resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
        
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = frame;
        [_button setBackgroundImage:bgNormal forState:UIControlStateNormal];
        [_button setBackgroundImage:bgSelected forState:UIControlStateSelected];
        [_button setTitle:buttonTitle forState:UIControlStateNormal];
        [_button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
        
    }
    return self;
}

- (void)buttonClicked:(id)sender
{
    NSLog(@"click");
}

@end
