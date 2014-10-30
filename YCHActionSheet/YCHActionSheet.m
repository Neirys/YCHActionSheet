//
//  YCHActionSheet.m
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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"

#import "YCHActionSheet.h"

#pragma mark -
#pragma mark Static values

#define kYCHActionSheetDefaultBackgroundColor   [UIColor colorWithWhite:0.97 alpha:1.0]

static NSTimeInterval const kYCHActionSheetAnimationDuration  =   0.5;
static CGFloat const kYCHActionSheetBackgroundAlpha           =   0.4;
static CGFloat const kYCHActionSheetSectionCornerRadius       =   3.0;

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

#pragma mark - YCHButton class

@interface YCHButton : UIButton

@property (assign, nonatomic) NSUInteger sectionIndex;
@property (assign, nonatomic) NSUInteger buttonIndex;
@property (assign, nonatomic) BOOL showBottomLine;

@property (nonatomic, assign) BOOL disabled;

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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(!_disabled){
      [super touchesBegan:touches withEvent:event];
    }
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
    
    UIView *_rootView;
    UIView *_upperView;
    UIScrollView *_scrollView;
    UIView *_contentView;
    
    NSArray *_offScreenConstraints;
    NSArray *_onScreenConstraints;
}

@property (assign, nonatomic, readwrite, getter = isVisible) BOOL visible;
@property (strong, nonatomic, readwrite) UIButton *cancelButton;

@end

@implementation YCHActionSheet

#pragma mark - Life cycle methods

- (id)init
{
    if (self = [super init])
    {
        NSAssert(false, @"Use -[%@] instead", NSStringFromSelector(@selector(initWithSections:cancelButtonTitle:delegate:)));
    }
    return self;
}

- (instancetype)initWithSections:(NSArray *)sections cancelButtonTitle:(NSString *)cancelButtonTitle delegate:(id)delegate
{
    if (self = [super init])
    {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundWasTouched:)]];
        
        _mutableSections = [sections mutableCopy];
        [_mutableSections makeObjectsPerformSelector:@selector(setActionSheet:) withObject:self];
        _cancelButtonTitle = cancelButtonTitle;
        _delegate = delegate;
        
        [self setupCancelButton];
        [self setupBaseViews];
        [self setupSectionViews];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

#pragma mark - Custom getters / setters

- (NSArray *)sections
{
    return [_mutableSections copy];
}

- (void)setSections:(NSArray *)sections
{
    _mutableSections = [sections mutableCopy];
    [_mutableSections makeObjectsPerformSelector:@selector(setActionSheet:) withObject:self];
    [self setupSectionViews];
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
    [self setupSectionViews];
    
    return _mutableSections.count-1;
}

- (YCHActionSheetSection *)sectionAtIndex:(NSInteger)index
{
    return _mutableSections[index];
}

- (void)showInView:(UIView *)view
{
    // add self to presenting view and setup constraint
    [view addSubview:self];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[actionSheet]|" options:0 metrics:0 views:@{@"actionSheet":self}]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[actionSheet]|" options:0 metrics:0 views:@{@"actionSheet":self}]];
    [view layoutIfNeeded];
    
    // trigger delegate method willPresent
    if ([self.delegate respondsToSelector:@selector(willPresentActionSheet:)])
    {
        [self.delegate willPresentActionSheet:self];
    }
    
    // position action sheet offscreen
    CGFloat viewHeight = self.frame.size.height;
    NSString *vfl = [NSString stringWithFormat:@"V:|-(%f)-[uv]-(%f)-|", viewHeight, -viewHeight];
    _offScreenConstraints = [NSLayoutConstraint constraintsWithVisualFormat:vfl options:0 metrics:nil views:@{@"uv":_upperView}];
    [self addConstraints:_offScreenConstraints];
    [self layoutIfNeeded];
    
    // animate onscrenn
    [self removeConstraints:_offScreenConstraints];
    _onScreenConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[uv]-10-|" options:0 metrics:nil views:@{@"uv":_upperView}];
    [self addConstraints:_onScreenConstraints];
    
    void (^animation)(void) = ^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kYCHActionSheetBackgroundAlpha];
        [self layoutIfNeeded];
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        self.visible = YES;
        
        if ([self.delegate respondsToSelector:@selector(didPresentActionSheet:)])
        {
            [self.delegate didPresentActionSheet:self];
        }
    };
    
    [UIView animateWithDuration:kYCHActionSheetAnimationDuration delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:animation completion:completion];
    
    // calculate and setup content view frame + scroll view content size
    [_scrollView layoutIfNeeded];
    [self fixScrollViewContentSize];
}

- (void)dismiss
{
    if ([self.delegate respondsToSelector:@selector(willDismissActionSheet:)])
    {
        [self.delegate willDismissActionSheet:self];
    }
    
    [self removeConstraints:_onScreenConstraints];
    [self addConstraints:_offScreenConstraints];
    
    void (^animation)(void) = ^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
        [self layoutIfNeeded];
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        self.visible = NO;
        [self removeFromSuperview];
        
        if ([self.delegate respondsToSelector:@selector(didDismissActionSheet:)])
        {
            [self.delegate didDismissActionSheet:self];
        }
    };
    
    [UIView animateWithDuration:kYCHActionSheetAnimationDuration delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:animation completion:completion];
}

#pragma mark - Notification handlers

- (void)orientationDidChange:(NSNotification *)note
{
    [self fixScrollViewContentSize];
}

#pragma mark - Setup UI

- (void)setupBaseViews
{
    // upper content view
    _upperView = [UIView new];
    _upperView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_upperView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10@750)-[uv]-(10@750)-|" options:0 metrics:nil views:@{@"uv":_upperView}]];
    
    // position cancel button
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton addTarget:self action:@selector(cancelButtonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
    [_upperView addSubview:self.cancelButton];
    [_upperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cancel]|" options:0 metrics:nil views:@{@"cancel":self.cancelButton}]];
    [_upperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cancel]|" options:0 metrics:nil views:@{@"cancel":self.cancelButton}]];
    [_upperView layoutIfNeeded];
    
    // add a scrollView
    _scrollView = [UIScrollView new];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [_upperView addSubview:_scrollView];
    [_upperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sv]|" options:0 metrics:nil views:@{@"sv":_scrollView}]];
    [_upperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]-10-[cancel]" options:0 metrics:nil views:@{@"sv":_scrollView, @"cancel":self.cancelButton}]];
    
    // add a scroll view's content view
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [_scrollView addSubview:_contentView];
}

- (void)setupSectionViews
{
    [_contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_contentView removeConstraints:_contentView.constraints];
    
    UIView *previousSection = nil;
    for (int i = 0; i < self.sections.count; i++)
    {
        YCHActionSheetSection *section = self.sections[i];
        
        // create a section view + constraints
        UIView *sectionView = [UIView new];
        sectionView.layer.cornerRadius = kYCHActionSheetSectionCornerRadius;
        sectionView.layer.masksToBounds = YES;
        sectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_contentView addSubview:sectionView];
        [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[section]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:@{@"section":sectionView}]];
        
        if (!previousSection)
        {
            [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[section]" options:0 metrics:nil views:@{@"section":sectionView}]];
        }
        else
        {
            [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous]-10-[section]" options:0 metrics:nil views:@{@"previous":previousSection, @"section":sectionView}]];
        }
        
        // add buttons' section + constraints
        
        UIView *previousButton = nil;
        if (section.titleLabel)
        {
            // hack : wrap UILabel around an UIView to prevent the previous ugly animation during device rotation
            UIView *titleView = [UIView new];
            titleView.backgroundColor = kYCHActionSheetDefaultBackgroundColor;
            titleView.translatesAutoresizingMaskIntoConstraints = NO;
            [sectionView addSubview:titleView];
            [titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleView(45)]"
                                                                              options:0 metrics:nil
                                                                                views:@{@"titleView":titleView}]];
            [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:@{@"titleView":titleView}]];
            [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleView]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:@{@"titleView":titleView}]];
            
            section.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
            section.titleLabel.backgroundColor = [UIColor clearColor];
            [titleView addSubview:section.titleLabel];
            [titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:@{@"title":section.titleLabel}]];
            [titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:@{@"title":section.titleLabel}]];
            
            previousButton = titleView;
        }
        
        for (int j = 0; j < section.buttons.count; j++)
        {
            YCHButton *button = section.buttons[j];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.sectionIndex = i;
            button.buttonIndex = j;
            [button addTarget:self action:@selector(buttonWasTouched:) forControlEvents:UIControlEventTouchUpInside];
            [sectionView addSubview:button];
            [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:0 metrics:nil views:@{@"button":button}]];
            
            if (!previousButton)
            {
                [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:@{@"button":button}]];
            }
            else
            {
                [sectionView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous][button]"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:@{@"previous":previousButton, @"button":button}]];
            }
            
            previousButton = button;
        }
        
        if (previousButton)
        {
            [sectionView addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[last]|" options:0 metrics:nil views:@{@"last":previousButton}]
             ];
        }
        
        previousSection = sectionView;
    }
    
    if (previousSection)
    {
        [_contentView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[last]|" options:0 metrics:nil views:@{@"last":previousSection}]
         ];
    }
    
    // this is technically useless here but will prevent from displaying endless constraints log messages
    [self fixScrollViewContentSize];
}

- (void)setupCancelButton
{
    NSString *cancelTitle = self.cancelButtonTitle ?: @"Cancel";
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.contentEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    [self.cancelButton setBackgroundColor:kYCHActionSheetDefaultBackgroundColor];
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:cancelTitle
                                                                     attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:21.0]}];
    [self.cancelButton setAttributedTitle:attributed forState:UIControlStateNormal];
    self.cancelButton.layer.cornerRadius = kYCHActionSheetSectionCornerRadius;
}

#pragma mark - Event handler methods

- (void)buttonWasTouched:(id)sender
{
    YCHButton *button = (YCHButton *)sender;
    if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:sectionIndex:)])
    {
        [self.delegate actionSheet:self clickedButtonAtIndex:button.buttonIndex sectionIndex:button.sectionIndex];
    }
    
    BOOL shouldDismiss = YES;
    if ([self.delegate respondsToSelector:@selector(actionSheet:shouldDismissForButtonAtIndex:sectionIndex:)])
    {
        shouldDismiss = [self.delegate actionSheet:self shouldDismissForButtonAtIndex:button.buttonIndex sectionIndex:button.sectionIndex];
    }
    
    if (shouldDismiss && button.disabled != YES){
        [self dismiss];
    }
}

- (void)cancelButtonWasTouched:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(actionSheetDidCancel:)])
    {
        [self.delegate actionSheetDidCancel:self];
    }
    
    [self dismiss];
}

- (void)backgroundWasTouched:(UIGestureRecognizer *)gesture {
    [self dismiss];
}

#pragma mark - Helper methods

- (void)fixScrollViewContentSize
{
    CGSize theoricSize = [_contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGRect contentViewFrame = _contentView.frame;
    contentViewFrame.size = CGSizeMake(_scrollView.frame.size.width, theoricSize.height);
    CGFloat offsetY = _scrollView.frame.size.height - MIN(contentViewFrame.size.height, _scrollView.frame.size.height);
    contentViewFrame.origin = CGPointMake(0, offsetY);
    _contentView.frame = contentViewFrame;
    
    _scrollView.contentSize = _contentView.frame.size;
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

@property (nonatomic, strong) UIFont *buttonFont;
@property (nonatomic, strong) UIColor *normalButtonStateColor;
@property (nonatomic, strong) UIColor *disabledButtonStateColor;

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
        
        [self setUpButtonElements];
        
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

#pragma mark - Private Methods
- (void)setEnabledStateForButton:(YCHButton *)button{
    //set enabled button atributes
    NSMutableDictionary *enabledAtributes = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:_buttonFont}];
    if(_normalButtonStateColor != nil){
        [enabledAtributes setObject:_normalButtonStateColor forKey:NSForegroundColorAttributeName];
    }
    NSMutableAttributedString *attributedTextEnabled = [[NSMutableAttributedString alloc] initWithString:button.titleLabel.text
                                                                                              attributes:enabledAtributes];
    [button setAttributedTitle:attributedTextEnabled forState:UIControlStateNormal];
}

- (void)setDisabledStateForButton:(YCHButton *)button{
    //set disabled button atributes
    NSMutableDictionary *disabledAtributes = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:_buttonFont}];
    if(_disabledButtonStateColor != nil){
        [disabledAtributes setObject:_disabledButtonStateColor forKey:NSForegroundColorAttributeName];
    } else {
        //set default color to light gray if no color is set
        [disabledAtributes setObject:[UIColor lightGrayColor] forKey:NSForegroundColorAttributeName];
    }
    NSMutableAttributedString *attributedTextDisabled = [[NSMutableAttributedString alloc] initWithString:button.titleLabel.text
                                                                                               attributes:disabledAtributes];
    [button setAttributedTitle:attributedTextDisabled forState:UIControlStateNormal];
}
- (YCHButton *)getButtonAtIndex:(NSInteger )index{
    YCHButton *button = nil;
    if([_mutableButtons count] > index){
        if([ _mutableButtons[index]isKindOfClass:[UIButton class]]){
            button =  _mutableButtons[index];
        }
    }
    return button;
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

//enable or disable a button at a specific index
- (void)setEnabled:(BOOL)enabled buttonAtIndex:(NSInteger)index{
    YCHButton *button = [self getButtonAtIndex:index];
    if(button != nil){
        button.disabled = !enabled;
        button.highlighted = !enabled;
        if (enabled) {
            [self setEnabledStateForButton:button];
        } else {
            [self setDisabledStateForButton:button];
        }

    }
}

#pragma mark - Setup UI methods

- (void)setUpButtonElements{
    _buttonFont = [UIFont systemFontOfSize:21.0];
    _normalButtonStateColor = nil;
    _disabledButtonStateColor = nil;
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
        button.contentEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
        button.showBottomLine = buttonTitle != _mutableButtonTitles.lastObject;

        //set enabled button atributes
        NSMutableDictionary *enabledAtributes = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:_buttonFont}];
        
        NSMutableAttributedString *attributedTextEnabled = [[NSMutableAttributedString alloc] initWithString:buttonTitle
                                                                                                  attributes:enabledAtributes];
       
        if (self.isDestructiveSection)
        {
            [attributedTextEnabled addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, buttonTitle.length)];
        }
        [button setBackgroundColor:kYCHActionSheetDefaultBackgroundColor];
        [button setAttributedTitle:attributedTextEnabled forState:UIControlStateNormal];
        
        [_mutableButtons addObject:button];
    }
}

@end

#pragma GCC diagnostic pop

