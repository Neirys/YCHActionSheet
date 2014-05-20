//
//  YCHActionSheet.m
//  YCHActionSheetExamples
//
//  Created by Yaman JAIOUCH on 23/04/2014.
//  Copyright (c) 2014 Yaman JAIOUCH. All rights reserved.
//

#import "YCHActionSheet.h"

#define kYCHActionSheetDefaultBackgroundColor   [UIColor colorWithWhite:0.97 alpha:1.0]

static CGFloat const kYCHActionSheetButtonHeight              =   44.0;
static CGFloat const kYCHActionSheetInterItemSpace            =   10.0;
static CGFloat const kYCHActionSheetHorizontalSpace           =   20.0;

static NSTimeInterval const kYCHActionSheetAnimationDuration  =   0.5;
static CGFloat const kYCHActionSheetBackgroundLayerAlpha      =   0.4;
static CGFloat const kYCHActionSheetItemCornerRadius          =   3.0;

/**
 *  Functions
 */

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

/**
 *  UIView categories
 */

@interface UIView (YCHRoundedCorner)

- (void)roundTopCornersWithRadius:(CGFloat)radius;
- (void)roundBottomCornersWithRadius:(CGFloat)radius;
- (void)roundAllCornersWithRadius:(CGFloat)radius;

@end

@implementation UIView (YCHRoundedCorner)

- (CAShapeLayer *)roundedCornerShapeForFrame:(CGRect)frame corners:(UIRectCorner)corners radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    shape.frame = frame;
    shape.path = path.CGPath;
    return shape;
}

- (void)roundCorners:(UIRectCorner)corners radius:(CGFloat)radius
{
    self.layer.mask = [self roundedCornerShapeForFrame:self.bounds corners:corners radius:radius];
}

- (void)roundTopCornersWithRadius:(CGFloat)radius
{
    [self roundCorners:(UIRectCornerTopRight | UIRectCornerTopLeft) radius:radius];
}

- (void)roundBottomCornersWithRadius:(CGFloat)radius
{
    [self roundCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) radius:radius];
}

- (void)roundAllCornersWithRadius:(CGFloat)radius
{
    [self roundCorners:(UIRectCornerAllCorners) radius:radius];
}

@end

/**
 *  YCHButton class
 */

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

/**
 *  YCHLabel class
 */

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

/**
 *  YCHActionSheet implementation
 */

@interface YCHActionSheet ()
{
    NSMutableArray *_mutableSections;
}
@property (assign, nonatomic, readwrite, getter = isVisible) BOOL visible;

@property (strong, nonatomic, readwrite) UIButton *cancelButton;
@property (strong, nonatomic) UIView *backgroundLayerView;

@property (weak, nonatomic) UIView *presentingView;

@end

@implementation YCHActionSheet

- (id)init
{
    if (self = [super init])
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;
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

- (void)layoutSubviews
{
    [self setupUI];
}

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

- (void)showInView:(UIView *)view
{
    self.visible = YES;
    self.presentingView = view;

    CGFloat startY = view.bounds.origin.y + [self heightForView:view];
    CGFloat width = [self widthForView:view] - kYCHActionSheetHorizontalSpace;
    CGFloat height = [self calculateFrameHeight];
    self.frame = CGRectMake([self widthForView:view]/2 - width/2, startY, width, height);
    [view addSubview:self];
    
    self.backgroundLayerView.frame = view.bounds;
    [view insertSubview:self.backgroundLayerView belowSubview:self];
    
    if ([self.delegate respondsToSelector:@selector(willPresentActionSheet:)])
    {
        [self.delegate willPresentActionSheet:self];
    }
    
    void (^animation)(void) = ^{
        self.frame = CGRectOffset(self.frame, 0, - self.frame.size.height);
        self.backgroundLayerView.alpha = kYCHActionSheetBackgroundLayerAlpha;
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(didPresentActionSheet:)])
        {
            [self.delegate didPresentActionSheet:self];
        }
    };
    
    [UIView animateWithDuration:kYCHActionSheetAnimationDuration delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:animation completion:completion];
}

- (void)dismiss
{
    if ([self.delegate respondsToSelector:@selector(willDismissActionSheet:)])
    {
        [self.delegate willDismissActionSheet:self];
    }
    
    void (^animation)(void) = ^{
        self.frame = CGRectOffset(self.frame, 0, self.frame.size.height);
        self.backgroundLayerView.alpha = 0.0;
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
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

- (void)setupUI
{
    CGFloat buttonWidth = [self widthForView:self.presentingView] - kYCHActionSheetHorizontalSpace;
    CGFloat offsetY = 0;
    
    for (int i = 0; i < self.sections.count; i++)
    {
        YCHActionSheetSection *section = self.sections[i];
        
        // 1°) display title
        UILabel *titleLabel = section.titleLabel;
        if (titleLabel)
        {
            titleLabel.frame = CGRectMake(0, offsetY, buttonWidth, kYCHActionSheetButtonHeight);
            [titleLabel roundTopCornersWithRadius:kYCHActionSheetItemCornerRadius];
            [self addSubview:titleLabel];
            offsetY += kYCHActionSheetButtonHeight;
        }
        
        // 2°) display buttons
        NSArray *buttons = section.buttons;
        for (int j = 0; j < buttons.count; j++)
        {
            YCHButton *button = buttons[j];
            
            button.frame = CGRectMake(0, offsetY, buttonWidth, kYCHActionSheetButtonHeight);
            button.sectionIndex = i;
            button.buttonIndex = j;
            [button addTarget:self action:@selector(buttonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            
            
            if (buttons.count == 1)
            {
                [button roundAllCornersWithRadius:kYCHActionSheetItemCornerRadius];
            }
            else if (button == buttons.lastObject)
            {
                [button roundBottomCornersWithRadius:kYCHActionSheetItemCornerRadius];
            }
            else if (button == buttons.firstObject && !titleLabel)
            {
                [button roundTopCornersWithRadius:kYCHActionSheetItemCornerRadius];
            }
            
            [self addSubview:button];
            
            offsetY += kYCHActionSheetButtonHeight;
        }
        
        offsetY += kYCHActionSheetInterItemSpace;
    }
    
    // 3°) display cancel
    if (self.cancelButton)
    {
        self.cancelButton.frame = CGRectMake(0, offsetY, buttonWidth, kYCHActionSheetButtonHeight);
        [self.cancelButton roundAllCornersWithRadius:kYCHActionSheetItemCornerRadius];
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.cancelButton];
    }
}

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

- (void)setupCancelButton
{
    NSString *cancelTitle = self.cancelButtonTitle ?: @"Cancel";
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelButton setBackgroundColor:kYCHActionSheetDefaultBackgroundColor];
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:cancelTitle
                                                                     attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:21.0]}];
    [self.cancelButton setAttributedTitle:attributed forState:UIControlStateNormal];
}

- (CGFloat)calculateFrameHeight
{
    CGFloat height = 0;
    for (YCHActionSheetSection *section in _mutableSections)
    {
        if (section.title)
            height += kYCHActionSheetButtonHeight;
        
        height += (section.buttons.count * kYCHActionSheetButtonHeight);
        
        // this is for separation
        height += kYCHActionSheetInterItemSpace;
    }
    
    // this is for cancel button
    height += kYCHActionSheetButtonHeight;
    
    // this is for letting some space
    height += kYCHActionSheetInterItemSpace;
    
    return height;
}

- (CGFloat)widthForView:(UIView *)view
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    return (UIInterfaceOrientationIsPortrait(orientation) || orientation == UIDeviceOrientationUnknown
            ? view.frame.size.width
            : view.frame.size.height);
}

- (CGFloat)heightForView:(UIView *)view
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    return (UIInterfaceOrientationIsPortrait(orientation) || orientation == UIDeviceOrientationUnknown
            ? view.frame.size.height
            : view.frame.size.width);
}

@end

/**
 *  YCHActionSheetSection implementation
 */

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

+ (instancetype)destructiveSectionWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:nil destructive:YES otherButtonTitles:title, nil];
}

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

