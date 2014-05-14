//
//  YCHPushButton.h
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 24/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YCHPushButton : UIView

@property (copy, nonatomic) NSString *buttonTitle;

- (instancetype)initWithTitle:(NSString *)buttonTitle frame:(CGRect)frame;

@end
