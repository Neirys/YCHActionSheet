//
//  YCHViewController.m
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 23/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import "YCHViewController.h"

#import "YCHActionSheet.h"

@interface YCHViewController () <YCHActionSheetDelegate>
{
    YCHActionSheet *_actionSheet;
}
@end

@implementation YCHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)actionSheet:(YCHActionSheet *)actionSheet clickedButtonAtIndex:(NSUInteger)buttonIndex sectionIndex:(NSUInteger)sectionIndex
{
    NSLog(@"%@ / %@", @(sectionIndex), @(buttonIndex));
}

- (void)actionSheetDidCancel:(YCHActionSheet *)actionSheet
{
    NSLog(@"cancel");
}

- (void)willPresentActionSheet:(YCHActionSheet *)actionSheet
{
    NSLog(@"will present");
}

- (void)didPresentActionSheet:(YCHActionSheet *)actionSheet
{
    NSLog(@"did present");
}

- (void)willDismissActionSheet:(YCHActionSheet *)actionSheet
{
    NSLog(@"will dismiss");
}

- (void)didDismissActionSheet:(YCHActionSheet *)actionSheet
{
    NSLog(@"did dismiss");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)displayActionSheet:(id)sender
{
    YCHActionSheetSection *section1 = [YCHActionSheetSection destructiveSectionWithTitle:@"Reset"];
    YCHActionSheetSection *section2 = [[YCHActionSheetSection alloc] initWithTitle:@"Compression"
                                                                 otherButtonTitles:@"75%", @"50%", @"25%", nil];
    
    YCHActionSheetSection *section3 = [[YCHActionSheetSection alloc] initWithTitle:@"Rotation"
                                                                 otherButtonTitles:@"90°", @"-90°", nil];
//    YCHActionSheetSection *section3 = [[YCHActionSheetSection alloc] initWithTitle:@"Rotation"
//                                                                 otherButtonTitles:@"90°", @"-90°", @"test",@"test",@"test",@"test",@"test",@"test",@"test", nil];
    
    _actionSheet = [[YCHActionSheet alloc] initWithSections:@[section1, section2, section3]
                                                         cancelButtonTitle:@"Cancel"
                                                                  delegate:self];

    [_actionSheet showInView:self.view];
    NSLog(@"vc : %@", _actionSheet);
}

@end
