//
//  YCHActionSheet.h
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 23/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * YCHActionSheetDelegate protocol
 */

@class YCHActionSheetSection, YCHActionSheet;

@protocol YCHActionSheetDelegate <UIActionSheetDelegate>

@optional
- (void)actionSheet:(YCHActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex inSection:(YCHActionSheetSection *)section;

@end

/**
 * YCHActionSheet interface
 */

@interface YCHActionSheet : UIView

@property (weak, nonatomic) id <YCHActionSheetDelegate> delegate;

@property (strong, nonatomic) NSArray *sections;

@property (copy, nonatomic) NSString *cancelButtonTitle;
@property (strong, nonatomic, readonly) UIButton *cancelButton;

- (instancetype)initWithSections:(NSArray *)sections cancelButtonTitle:(NSString *)cancelButtonTitle delegate:(id)delegate;

- (void)show;

- (NSInteger)addSection:(YCHActionSheetSection *)section;
- (YCHActionSheetSection *)sectionAtIndex:(NSInteger)index;

@end

/**
 * YCHActionSheetSection interface
 */

@interface YCHActionSheetSection : NSObject

@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic, readonly) UILabel *titleLabel;

@property (strong, nonatomic) NSArray *buttonTitles;
@property (strong, nonatomic, readonly) NSArray *buttons;

- (instancetype)initWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (NSInteger)addButtonWithTitle:(NSString *)title;
- (NSString *)buttonAtIndex:(NSInteger)index;

@end
