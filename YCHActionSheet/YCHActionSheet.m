//
//  YCHActionSheet.m
//
//  Version 1.0
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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"

#import "YCHActionSheet.h"

#pragma mark - 
#pragma mark Static values

#define kYCHActionSheetDefaultBackgroundColor   [UIColor colorWithWhite:0.97 alpha:1.0]

static CGFloat const kYCHActionSheetButtonHeight              =   44.0;
static CGFloat const kYCHActionSheetInterItemSpace            =   10.0;
static CGFloat const kYCHActionSheetHorizontalSpace           =   20.0;

static NSTimeInterval const kYCHActionSheetAnimationDuration  =   0.5;
static CGFloat const kYCHActionSheetBackgroundLayerAlpha      =   0.4;
static CGFloat const kYCHActionSheetItemCornerRadius          =   3.0;

#pragma mark - Functions

void YCHDrawBottomGradientLine(CGContextRef context, CGRect rect, CGFloat width)
{
    CGFloat colors [] = {
        0.90, 0.90, 0.90, 1.0,
        0.75, 0.75, 0.75, 1.0,
    };
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGPoint startCenter = CGPointMake(rect.size.width/2, rect.origin.y + rect.size.height - width);

    CGContextSaveGState(context);
    CGContextAddRect(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - width, rect.size.width, width));
    CGContextClip(context);
    CGContextDrawRadialGradient(context, gradient, startCenter, 0, startCenter, rect.size.width * 0.5, 0);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
}

#pragma mark - UIView categories

typedef NS_OPTIONS(NSUInteger, YCHRectCorner) {
    YCHRectCornerTop        =   UIRectCornerTopLeft | UIRectCornerTopRight,
    YCHRectCornerBottom     =   UIRectCornerBottomLeft | UIRectCornerBottomRight,
    YCHRectCornerAll        =   UIRectCornerAllCorners,
};

@interface UIView (YCHRoundedCorner)

- (void)roundCorners:(YCHRectCorner)corners withRadius:(CGFloat)radius;
- (void)roundCorners:(YCHRectCorner)corners;

@end

@implementation UIView (YCHRoundedCorner)

- (CAShapeLayer *)roundedCornerShapeWithFrame:(CGRect)frame corners:(UIRectCorner)corners radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    shape.frame = frame;
    shape.path = path.CGPath;
    return shape;
}

- (void)roundCorners:(YCHRectCorner)corners withRadius:(CGFloat)radius
{
    self.layer.mask = [self roundedCornerShapeWithFrame:self.bounds corners:(UIRectCorner)corners radius:radius];
}

- (void)roundCorners:(YCHRectCorner)corners
{
    [self roundCorners:corners withRadius:kYCHActionSheetItemCornerRadius];
}

@end

#pragma mark - YCHButton class

@interface YCHButton : UIButton

@property (assign, nonatomic) NSUInteger sectionIndex;
@property (assign, nonatomic) NSUInteger buttonIndex;
@property (assign, nonatomic) BOOL showBottomLine;

@end

@implementation YCHButton

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!self.showBottomLine)
        return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    YCHDrawBottomGradientLine(context, rect, 0.5);
}

- (void)setShowBottomLine:(BOOL)showBottomLine
{
    _showBottomLine = showBottomLine;
    [self setNeedsDisplay];
}

@end

#pragma mark - YCHLabel class

@interface YCHLabel : UILabel
@end

@implementation YCHLabel

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    YCHDrawBottomGradientLine(context, rect, 0.5);
}

@end

#pragma mark - YCHActionSheet implementation

@interface YCHActionSheet ()
{
    NSMutableArray *_mutableSections;
    UIScrollView *_scrollView;
    BOOL _willAnimate;
    
#warning TEST
    UIView *_rv;
    UIScrollView *_sv;
    UIView *_cv;
}

@property (assign, nonatomic, readwrite, getter = isVisible) BOOL visible;

@property (strong, nonatomic, readwrite) UIButton *cancelButton;
@property (strong, nonatomic) UIView *backgroundLayerView;

@property (weak, nonatomic) UIView *presentingView;

@end

@implementation YCHActionSheet

#pragma mark - Life cycle methods

- (id)init
{
    if (self = [super init])
    {
#warning TEST
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:_scrollView];
    }
    NSLog(@"%@", self);
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (instancetype)initWithSections:(NSArray *)sections cancelButtonTitle:(NSString *)cancelButtonTitle delegate:(id)delegate
{
    if (self = [self init])
    {
        _mutableSections = [sections mutableCopy];
        [_mutableSections makeObjectsPerformSelector:@selector(setActionSheet:) withObject:self];
        _cancelButtonTitle = cancelButtonTitle;
        _delegate = delegate;
        
        [self setupCancelButton];
    }
    return self;
}

//- (void)layoutSubviews
//{
//    [super layoutSubviews];
//    
//    [self setupUI];
//}

#warning TEST
//- (void)layoutSubviews
//{
//    CGRect contentViewFrame = _cv.frame;
//    contentViewFrame.size = CGSizeMake(_sv.frame.size.width, contentViewFrame.size.height);
//    CGFloat offsetY = _sv.frame.size.height - MIN(contentViewFrame.size.height, _sv.frame.size.height);
//    contentViewFrame.origin = CGPointMake(0, offsetY);
//    _cv.frame = contentViewFrame;
//    _sv.contentSize = _cv.frame.size;
//}

#pragma mark - Custom getters / setters

- (NSArray *)sections
{
    return [_mutableSections copy];
}

- (void)setSections:(NSArray *)sections
{
    _mutableSections = [sections mutableCopy];
}

- (UIView *)backgroundLayerView
{
    if (_backgroundLayerView)
        return _backgroundLayerView;
    
    _backgroundLayerView = [[UIView alloc] init];
    _backgroundLayerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _backgroundLayerView.backgroundColor = [UIColor blackColor];
    _backgroundLayerView.opaque = YES;
    _backgroundLayerView.alpha = 0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundLayerWasTouched:)];
    [_backgroundLayerView addGestureRecognizer:tap];
    
    return _backgroundLayerView;
}

#pragma mark - Public methods

- (NSInteger)addSection:(YCHActionSheetSection *)section
{
    if (self.isVisible)
    {
        NSLog(@"YCHActionSheet error - You cannot add a section if action sheet is already visible");
        return -1;
    }
    
    [section performSelector:@selector(setActionSheet:) withObject:self];
    [_mutableSections addObject:section];
    return _mutableSections.count-1;
}

- (YCHActionSheetSection *)sectionAtIndex:(NSInteger)index
{
    return _mutableSections[index];
}

#warning TEST
- (void)showInView:(UIView *)view
{
    // FIXME: hack only to retain self
    [view addSubview:self];
    
    // create a background black transparent layer + constraints
    UIView *rv = [UIView new];
    rv.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    rv.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:rv];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[root]|" options:0 metrics:0 views:@{@"root":rv}]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[root]|" options:0 metrics:0 views:@{@"root":rv}]];
    
    // position cancel button
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [rv addSubview:self.cancelButton];
    [self.cancelButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cancel(40)]" options:0 metrics:nil views:@{@"cancel":self.cancelButton}]];
    [rv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[cancel]-10-|" options:0 metrics:nil views:@{@"cancel":self.cancelButton}]];
    [rv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cancel]-10-|" options:0 metrics:nil views:@{@"cancel":self.cancelButton}]];
    [rv layoutIfNeeded];
    
    // add a scrollView
    _sv = [UIScrollView new];
    _sv.backgroundColor = [UIColor redColor];
    _sv.translatesAutoresizingMaskIntoConstraints = NO;
    [rv addSubview:_sv];
    [rv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[sv]-10-|" options:0 metrics:nil views:@{@"sv":_sv}]];
    [rv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[sv]-10-[cancel]" options:0 metrics:nil views:@{@"sv":_sv, @"cancel":self.cancelButton}]];
    
    // add a scroll view's content view
    _cv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _cv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _cv.backgroundColor = [UIColor greenColor];
    [_sv addSubview:_cv];
    
    UIView *previousSection = nil;
    for (int i = 0; i < self.sections.count; i++)
    {
        YCHActionSheetSection *section = self.sections[i];
        
        // create a section view + constraints
        UIView *sectionView = [UIView new];
        sectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_cv addSubview:sectionView];
        [_cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[section]|" options:0 metrics:nil views:@{@"section":sectionView}]];
        
        if (!previousSection)
        {
            [_cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[section]" options:0 metrics:nil views:@{@"section":sectionView}]];
        }
        else
        {
            [_cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous]-10-[section]" options:0 metrics:nil views:@{@"previous":previousSection, @"section":sectionView}]];
        }
        
        // add buttons' section + constraints
        
        UIView *previousButton = nil;
        if (section.titleLabel)
        {
            section.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [sectionView addSubview:section.titleLabel];
            [section.titleLabel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[title(40)]" options:0 metrics:nil views:@{@"title":section.titleLabel}]];
            [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|" options:0 metrics:nil views:@{@"title":section.titleLabel}]];
            [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]" options:0 metrics:nil views:@{@"title":section.titleLabel}]];
            previousButton = section.titleLabel;
        }
        
        for (int j = 0; j < section.buttons.count; j++)
        {
            YCHButton *button = section.buttons[j];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.sectionIndex = i;
            button.buttonIndex = j;
            [button addTarget:self action:@selector(buttonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            [sectionView addSubview:button];
            [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(40)]" options:0 metrics:nil views:@{@"button":button}]];
            [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:0 metrics:nil views:@{@"button":button}]];
            
            if (!previousButton)
            {
                [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]" options:0 metrics:nil views:@{@"button":button}]];
            }
            else
            {
                [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous][button]" options:0 metrics:nil views:@{@"previous":previousButton, @"button":button}]];
            }
            
            previousButton = button;
        }
        
        [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[last]|" options:0 metrics:nil views:@{@"last":previousButton}]];
        
        previousSection = sectionView;
    }
    
    [_cv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[last]|" options:0 metrics:nil views:@{@"last":previousSection}]];
    
    // calculate and setup content view frame + scroll view content size
    [_sv layoutIfNeeded];
    
    CGSize theoricSize = [_cv systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    NSLog(@"current scrollView size : %@", NSStringFromCGRect(_sv.frame));
    NSLog(@"theoric size : %@", NSStringFromCGSize(theoricSize));
    
    CGRect contentViewFrame = _cv.frame;
    contentViewFrame.size = CGSizeMake(_sv.frame.size.width, theoricSize.height);
    CGFloat offsetY = _sv.frame.size.height - MIN(contentViewFrame.size.height, _sv.frame.size.height);
    contentViewFrame.origin = CGPointMake(0, offsetY);
    _cv.frame = contentViewFrame;
    
    _sv.contentSize = _cv.frame.size;
    
}

- (void)orientationDidChange:(NSNotification *)note
{
    NSLog(@"%@", note);
    
    CGSize theoricSize = [_cv systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    NSLog(@"current scrollView size : %@", NSStringFromCGRect(_sv.frame));
    NSLog(@"theoric size : %@", NSStringFromCGSize(theoricSize));
    
    CGRect contentViewFrame = _cv.frame;
    contentViewFrame.size = CGSizeMake(_sv.frame.size.width, theoricSize.height);
    CGFloat offsetY = _sv.frame.size.height - MIN(contentViewFrame.size.height, _sv.frame.size.height);
    contentViewFrame.origin = CGPointMake(0, offsetY);
    _cv.frame = contentViewFrame;
    
    _sv.contentSize = _cv.frame.size;
}

//- (void)showInView:(UIView *)view
//{
//    _willAnimate = YES;
//    self.visible = YES;
//    self.presentingView = view;
//    
//    [self prepareUI];
//
//    // setup initial frame
//    CGFloat startY = view.bounds.origin.y + [self heightForView:view];
//    CGSize size = [self calculateFrameSize];
//    self.frame = CGRectMake([self widthForView:view]/2 - size.width/2, startY, size.width, size.height);
//    [view addSubview:self];
//    
//    // add an opaque background layer
//    self.backgroundLayerView.frame = view.bounds;
//    [view insertSubview:self.backgroundLayerView belowSubview:self];
//    
//    if ([self.delegate respondsToSelector:@selector(willPresentActionSheet:)])
//    {
//        [self.delegate willPresentActionSheet:self];
//    }
//    
//    void (^animation)(void) = ^{
//        self.frame = CGRectOffset(self.frame, 0, - self.frame.size.height);
//        self.backgroundLayerView.alpha = kYCHActionSheetBackgroundLayerAlpha;
//    };
//    
//    void (^completion)(BOOL finished) = ^(BOOL finished) {
//        _willAnimate = NO;
//        if ([self.delegate respondsToSelector:@selector(didPresentActionSheet:)])
//        {
//            [self.delegate didPresentActionSheet:self];
//        }
//    };
//    
//    [UIView animateWithDuration:kYCHActionSheetAnimationDuration delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:animation completion:completion];
//}

- (void)dismiss
{
    _willAnimate = YES;
    
    if ([self.delegate respondsToSelector:@selector(willDismissActionSheet:)])
    {
        [self.delegate willDismissActionSheet:self];
    }
    
    void (^animation)(void) = ^{
        self.frame = CGRectOffset(self.frame, 0, self.frame.size.height);
        self.backgroundLayerView.alpha = 0.0;
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        _willAnimate = NO;
        self.visible = NO;
        [self.backgroundLayerView removeFromSuperview];
        [self removeFromSuperview];
        
        if ([self.delegate respondsToSelector:@selector(didDismissActionSheet:)])
        {
            [self.delegate didDismissActionSheet:self];
        }
    };
    
    [UIView animateWithDuration:kYCHActionSheetAnimationDuration delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:animation completion:completion];
}

#pragma mark - Setup UI methods

- (void)prepareUI
{
    for (int i = 0; i < self.sections.count; i++)
    {
        YCHActionSheetSection *section = self.sections[i];
        
        if (section.titleLabel)
        {
            [_scrollView addSubview:section.titleLabel];
        }

        for (int j = 0; j < section.buttons.count; j++)
        {
            YCHButton *button = section.buttons[j];
            button.sectionIndex = i;
            button.buttonIndex = j;
            [button addTarget:self action:@selector(buttonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            [_scrollView addSubview:button];
        }
    }
    
    if (self.cancelButton)
    {
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
    }
}

- (void)setupUI
{
    // setup scrollView frame and contentSize
    _scrollView.frame = [self calculateScrollViewFrame];
    _scrollView.contentSize = [self calculateScrollViewContentSize];
    
    // in case of rotation, fix action sheet frame
    if (!_willAnimate)
    {
        [self fixActionSheetFrame];
    }
    
    // setup action sheet view
    CGFloat offsetY = 0;
    CGFloat buttonWidth = [self widthForView:self.presentingView] - kYCHActionSheetHorizontalSpace;
    for (YCHActionSheetSection *section in self.sections)
    {
        if (section.titleLabel)
        {
            section.titleLabel.frame = CGRectMake(0, offsetY, buttonWidth, kYCHActionSheetButtonHeight);
            [section.titleLabel roundCorners:YCHRectCornerTop];
            
            offsetY += kYCHActionSheetButtonHeight;
        }
        
        for (YCHButton *button in section.buttons)
        {
            button.frame = CGRectMake(0, offsetY, buttonWidth, kYCHActionSheetButtonHeight);
            [self roundCornerButton:button inSection:section];
            
            offsetY += kYCHActionSheetButtonHeight;
        }
        
        offsetY += kYCHActionSheetInterItemSpace;
    }
    
    if (self.cancelButton)
    {
        self.cancelButton.frame = CGRectMake(0, _scrollView.frame.size.height + kYCHActionSheetInterItemSpace, buttonWidth, kYCHActionSheetButtonHeight);
        [self.cancelButton roundCorners:YCHRectCornerAll];
    }
}

- (void)setupCancelButton
{
    NSString *cancelTitle = self.cancelButtonTitle ?: @"Cancel";
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setBackgroundColor:kYCHActionSheetDefaultBackgroundColor];
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:cancelTitle
                                                                     attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:21.0]}];
    [self.cancelButton setAttributedTitle:attributed forState:UIControlStateNormal];
}

#pragma mark - Event handler methods

- (void)buttonWasTouched:(id)sender
{
    YCHButton *button = (YCHButton *)sender;
    if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:sectionIndex:)])
    {
        [self.delegate actionSheet:self clickedButtonAtIndex:button.buttonIndex sectionIndex:button.sectionIndex];
    }
    
    [self dismiss];
}

- (void)cancelButtonWasTouched:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(actionSheetDidCancel:)])
    {
        [self.delegate actionSheetDidCancel:self];
    }
    
    [self dismiss];
}

- (void)backgroundLayerWasTouched:(UIGestureRecognizer *)gesture
{
    [self dismiss];
}

#pragma mark - Helper methods

- (void)roundCornerButton:(YCHButton *)button inSection:(YCHActionSheetSection *)section
{
    if (section.buttons.count == 1)
    {
        [button roundCorners:YCHRectCornerAll];
    }
    else if (button == section.buttons.lastObject)
    {
        [button roundCorners:YCHRectCornerBottom];
    }
    else if (button == section.buttons.firstObject && !section.titleLabel)
    {
        [button roundCorners:YCHRectCornerTop];
    }
}

- (void)fixActionSheetFrame
{
    CGSize frameSize = [self calculateFrameSize];
    CGRect frame = CGRectMake([self widthForView:self.presentingView]/2 - frameSize.width/2,
                              [self heightForView:self.presentingView] - frameSize.height,
                              frameSize.width,
                              frameSize.height);
    self.frame = frame;
}

- (CGSize)calculateFrameSize
{
    CGSize svSize = [self calculateScrollViewFrameSize];
    CGFloat height = svSize.height + kYCHActionSheetButtonHeight + (kYCHActionSheetInterItemSpace*2);
    return CGSizeMake(svSize.width, height);
}

- (CGSize)calculateScrollViewContentSize
{
    CGFloat height = 0;
    for (YCHActionSheetSection *section in _mutableSections)
    {
        if (section.title)
            height += kYCHActionSheetButtonHeight;
        
        height += (section.buttons.count * kYCHActionSheetButtonHeight);
        
        if (section != _mutableSections.lastObject)
            height += kYCHActionSheetInterItemSpace;
    }
    
    CGFloat width = [self widthForView:self.presentingView] - kYCHActionSheetHorizontalSpace;
    return CGSizeMake(width, height);
}

- (CGSize)calculateScrollViewFrameSize
{
    CGFloat maxHeight = [self heightForView:self.presentingView] - kYCHActionSheetButtonHeight - (5*kYCHActionSheetInterItemSpace);
    CGSize contentSize = [self calculateScrollViewContentSize];
    CGFloat height = MIN(maxHeight, contentSize.height);
    
    return CGSizeMake(contentSize.width, height);
}

- (CGRect)calculateScrollViewFrame
{
    CGSize svSize = [self calculateScrollViewFrameSize];
    return CGRectMake(0, 0, svSize.width, svSize.height);
}

- (BOOL)orientationConsideredAsPortrait:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation) || orientation == UIDeviceOrientationUnknown;
}

- (CGFloat)widthForView:(UIView *)view
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return ([self orientationConsideredAsPortrait:orientation]
            ? view.frame.size.width
            : view.frame.size.height);
}

- (CGFloat)heightForView:(UIView *)view
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return ([self orientationConsideredAsPortrait:orientation]
            ? view.frame.size.height
            : view.frame.size.width);
}

@end

#pragma mark - YCHActionSheetSection implementation

@interface YCHActionSheetSection ()
{
    NSMutableArray *_mutableButtonTitles;
    NSMutableArray *_mutableButtons;
}

@property (weak, nonatomic, readwrite) YCHActionSheet *actionSheet;

@property (strong, nonatomic, readwrite) YCHLabel *titleLabel;
@property (assign, nonatomic, readwrite, getter = isDestructiveSection) BOOL destructiveSection;

@end

@implementation YCHActionSheetSection

#pragma mark - Life cycle methods

- (instancetype)initWithTitle:(NSString *)title destructive:(BOOL)destructive firstButtonTitle:(NSString *)firstButtonTitle otherButtonsTitles:(va_list)otherButtonTitles
{
    if (self = [super init])
    {
        _title = title;
        _destructiveSection = destructive;
        
        _mutableButtonTitles = [NSMutableArray array];
        for (NSString *arg = firstButtonTitle; arg != nil; arg = va_arg(otherButtonTitles, NSString *))
        {
            [_mutableButtonTitles addObject:arg];
        }
        
        [self setupTitleLabel];
        [self setupButtons];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title destructive:(BOOL)destructive otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    va_list args;
    va_start(args, otherButtonTitles);
    self = [self initWithTitle:title destructive:destructive firstButtonTitle:otherButtonTitles otherButtonsTitles:args];
    va_end(args);
    return self;
}

- (instancetype)initWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    va_list args;
    va_start(args, otherButtonTitles);
    self = [self initWithTitle:title destructive:NO firstButtonTitle:otherButtonTitles otherButtonsTitles:args];
    va_end(args);
    return self;
}

+ (instancetype)sectionWithTitle:(NSString *)title otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    va_list args;
    va_start(args, otherButtonTitles);
    YCHActionSheetSection *sheet = [[self alloc] initWithTitle:title destructive:NO firstButtonTitle:otherButtonTitles otherButtonsTitles:args];
    va_end(args);
    return sheet;
}

+ (instancetype)destructiveSectionWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:nil destructive:YES otherButtonTitles:title, nil];
}

#pragma mark - Custom getters / setters

- (void)setTitle:(NSString *)title
{
    _title = title;
    [self setupTitleLabel];
}

- (NSArray *)buttonTitles
{
    return [_mutableButtonTitles copy];
}

- (void)setButtonTitles:(NSArray *)buttonTitles
{
    _mutableButtonTitles = [buttonTitles mutableCopy];
    [self setupButtons];
}

- (NSArray *)buttons
{
    return [_mutableButtons copy];
}

#pragma mark - Public methods

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    if (self.actionSheet.isVisible)
    {
        NSLog(@"YCHActionSheetSection error - You cannot add a button title when action sheet is already visible");
        return -1;
    }
    
    [_mutableButtonTitles addObject:title];
    [self setupButtons];
    return _mutableButtonTitles.count-1;
}

- (NSString *)buttonTitleAtIndex:(NSInteger)index
{
    return _mutableButtonTitles[index];
}

#pragma mark - Setup UI methods

- (void)setupTitleLabel
{
    if (!self.title)
        return;
    
    self.titleLabel = [[YCHLabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:13.0];
    self.titleLabel.text = self.title;
    self.titleLabel.textColor = [UIColor grayColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.backgroundColor = kYCHActionSheetDefaultBackgroundColor;
}

- (void)setupButtons
{
    _mutableButtons = [NSMutableArray array];
    for (NSString *buttonTitle in _mutableButtonTitles)
    {
        YCHButton *button = [YCHButton buttonWithType:UIButtonTypeSystem];
        button.showBottomLine = buttonTitle != _mutableButtonTitles.lastObject;

        NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:buttonTitle
                                                                                       attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:21.0]}];
        if (self.isDestructiveSection)
        {
            [attributed addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, buttonTitle.length)];
        }
        
        [button setAttributedTitle:attributed forState:UIControlStateNormal];
        [button setBackgroundColor:kYCHActionSheetDefaultBackgroundColor];
        
        [_mutableButtons addObject:button];
    }
}

@end

#pragma GCC diagnostic pop

