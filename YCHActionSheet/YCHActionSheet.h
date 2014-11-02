//
//  YCHActionSheet.h
//
//  Version 1.0.2
//
//  https://github.com/Neirys/YCHActionSheet
//
//  Created by Yaman JAIOUCH on 23/04/2014.
//
//  Copyright (c) 2014 Yaman JAIOUCH
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import <UIKit/UIKit.h>

@class YCHActionSheetSection, YCHActionSheet;

/**
 *  YCHActionSheetDelegate protocol
 */

@protocol YCHActionSheetDelegate <NSObject>

@optional

// called when a button was clicked with section index and button index
- (void)actionSheet:(YCHActionSheet *)actionSheet clickedButtonAtIndex:(NSUInteger)buttonIndex sectionIndex:(NSUInteger)sectionIndex;

// called when a user clicked on the Cancel button
- (void)didCancelActionSheet:(YCHActionSheet *)actionSheet;

// called before / after an action sheet is shown
- (void)willPresentActionSheet:(YCHActionSheet *)actionSheet;
- (void)didPresentActionSheet:(YCHActionSheet *)actionSheet;

// called before / after an action sheet is dismiss
- (void)willDismissActionSheet:(YCHActionSheet *)actionSheet;
- (void)didDismissActionSheet:(YCHActionSheet *)actionSheet;

// Called when a button is clicked. Returning NO will prevent the click from dismissing the action sheet.
// The default is YES.
- (BOOL)actionSheet:(YCHActionSheet *)actionSheet shouldDismissForButtonAtIndex:(NSUInteger)buttonIndex sectionIndex:(NSUInteger)sectionIndex;

@end

/**
 *  YCHActionSheet interface
 */

@interface YCHActionSheet : UIView

@property (weak, nonatomic) id <YCHActionSheetDelegate> delegate;

// set to YES before animation completed
@property (assign, nonatomic, readonly, getter = isVisible) BOOL visible;

@property (strong, nonatomic) NSArray *sections;

// these are always non-nil. Default title = "Cancel"
@property (copy, nonatomic) NSString *cancelButtonTitle;
@property (strong, nonatomic, readonly) UIButton *cancelButton;

// main method to create an action sheet
// all objects contained in sections should be of type YCHActionSheetSection. Unexpected behavior otherwise
- (instancetype)initWithSections:(NSArray *)sections cancelButtonTitle:(NSString *)cancelButtonTitle delegate:(id<YCHActionSheetDelegate>)delegate;

// show an action sheet animated. view should be your controller main's view
- (void)showInView:(UIView *)view;

// return the added section index. adding a section while action sheet is visible will do nothing and return -1
- (NSInteger)addSection:(YCHActionSheetSection *)section;

// return a section for a given index. crash if index if out of bounds
- (YCHActionSheetSection *)sectionAtIndex:(NSInteger)index;

@end

/**
 *  YCHActionSheetSection interface
 */

@interface YCHActionSheetSection : NSObject

// default is nil. set when section is added to an action sheet
@property (weak, nonatomic, readonly) YCHActionSheet *actionSheet;

// title of this section
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic, readonly) UILabel *titleLabel;

// buttons of this section
@property (strong, nonatomic) NSArray *buttonTitles;
@property (strong, nonatomic, readonly) NSArray *buttons;

// a destructive section is a one-button section. text is colored in red
@property (assign, nonatomic, readonly, getter = isDestructiveSection) BOOL destructiveSection;

// main method to create an action sheet section
- (instancetype)initWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

// convenience method. same as -initWithTitle:otherButtonTitles:
+ (instancetype)sectionWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

// convenience method to create a destructive section
+ (instancetype)destructiveSectionWithTitle:(NSString *)title;

// return added button index. adding a button while action sheet is visible will do nothing and return -1
- (NSInteger)addButtonWithTitle:(NSString *)title;

// return a button title for a given index. crash if index is out of bounds
- (NSString *)buttonTitleAtIndex:(NSInteger)index;

@end
