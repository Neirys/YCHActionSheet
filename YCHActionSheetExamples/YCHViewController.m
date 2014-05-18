//
//  YCHViewController.m
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 23/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import "YCHViewController.h"

#import "YCHActionSheet.h"
#import "YCHPushButton.h"


@interface YCHViewController () <YCHActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation YCHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    YCHPushButton *button = [[YCHPushButton alloc] initWithTitle:@"Test" frame:CGRectMake(10, 10, 200, 100)];
//    [self.view addSubview:button];
    
//    UIImage *bgNormal = [[UIImage imageNamed:@"bg_50"]
//                         resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
//    UIImage *bgSelected = [[UIImage imageNamed:@"bg_50_selected"]
//                           resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
//    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    button.frame = CGRectMake(20, 20, 100, 30);
//    [button setBackgroundImage:bgNormal forState:UIControlStateNormal];
//    [button setBackgroundImage:bgSelected forState:UIControlStateSelected];
//    [button setTitle:@"test" forState:UIControlStateNormal];
//    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:button];
    
    YCHActionSheetSection *section1 = [[YCHActionSheetSection alloc] initWithTitle:nil otherButtonTitles:@"S1B1", @"S1B2", nil];
    YCHActionSheetSection *section2 = [[YCHActionSheetSection alloc] initWithTitle:@"Section 2" otherButtonTitles:@"S2B1", @"S2B2", @"S2B3", nil];
    YCHActionSheet *actionSheet = [[YCHActionSheet alloc] initWithSections:@[section1, section2] cancelButtonTitle:@"Cancel" delegate:nil];
    actionSheet.delegate = self;
    [actionSheet showFromView:self.view];
    
//    actionSheet.frame = CGRectMake(10, 50, 100, 100);
//    actionSheet.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
//    [self.view addSubview:actionSheet];
}

- (void)actionSheet:(YCHActionSheet *)actionSheet clickedButtonAtIndex:(NSUInteger)buttonIndex sectionIndex:(NSUInteger)sectionIndex
{
    NSLog(@"%@ / %@", @(sectionIndex), @(buttonIndex));
}

- (void)buttonClicked:(id)sender
{
    NSLog(@"click");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)displayActionSheet:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Test" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Hello", @"Button", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
//    [actionSheet showFromBarButtonItem:self.barButton animated:YES];
    [actionSheet showInView:self.view];
//    [actionSheet showFromToolbar:self.toolbar];
}

@end
