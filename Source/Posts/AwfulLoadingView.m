//  AwfulLoadingView.m
//
//  Copyright 2013 Awful Contributors. CC BY-NC-SA 3.0 US https://github.com/Awful/Awful.app

#import "AwfulLoadingView.h"
#import "FVGifAnimation.h"

@interface AwfulDefaultLoadingView : AwfulLoadingView @end
@interface AwfulGasChamberLoadingView : AwfulDefaultLoadingView @end
@interface AwfulFYADLoadingView : AwfulDefaultLoadingView @end
@interface AwfulYOSPOSLoadingView : AwfulLoadingView @end
@interface AwfulMacinyosLoadingView : AwfulLoadingView @end
@interface AwfulWinpos95LoadingView : AwfulLoadingView @end


@interface AwfulLoadingView ()

@property (nonatomic) UILabel *messageLabel;

@property (nonatomic) BOOL lockTintColor;

- (void)retheme;

@end


@implementation AwfulLoadingView

+ (instancetype)loadingViewWithType:(AwfulLoadingViewType)type
{
    switch (type) {
        case AwfulLoadingViewTypeDefault: return [AwfulDefaultLoadingView new];
        case AwfulLoadingViewTypeGasChamber: return [AwfulGasChamberLoadingView new];
        case AwfulLoadingViewTypeFYAD: return [AwfulFYADLoadingView new];
        case AwfulLoadingViewTypeYOSPOS: return [AwfulYOSPOSLoadingView new];
        case AwfulLoadingViewTypeMacinyos: return [AwfulMacinyosLoadingView new];
        case AwfulLoadingViewTypeWinpos95: return [AwfulWinpos95LoadingView new];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.messageLabel = [UILabel new];
    [self addSubview:self.messageLabel];
    return self;
}

- (NSString *)message
{
    return self.messageLabel.text;
}

- (void)setMessage:(NSString *)message
{
    self.messageLabel.text = message;
    [self setNeedsLayout];
}

- (void)setTintColor:(UIColor *)tintColor
{
    if (_tintColor == tintColor || self.lockTintColor) return;
    _tintColor = tintColor;
    [self retheme];
}

- (void)retheme
{
    self.messageLabel.font = [UIFont boldSystemFontOfSize:13];
}

#pragma mark - UIView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    self.frame = (CGRect){ .size = newSuperview.frame.size };
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

@end


@interface AwfulDefaultLoadingView ()

@property (nonatomic) UIActivityIndicatorView *spinner;

@end


@implementation AwfulDefaultLoadingView

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.spinner = [UIActivityIndicatorView new];
    [self addSubview:self.spinner];
    self.tintColor = [UIColor colorWithWhite:0.82 alpha:1];
    return self;
}

- (void)retheme
{
    [super retheme];
    self.backgroundColor = self.tintColor;
    self.spinner.backgroundColor = self.backgroundColor;
    CGFloat whiteness;
    BOOL ok = [self.tintColor getWhite:&whiteness alpha:nil];
    if (!ok) whiteness = 1;
    if (whiteness < 0.1) {
        self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.messageLabel.textColor = [UIColor colorWithWhite:0.95 alpha:1];
        self.messageLabel.shadowColor = nil;
    } else {
        self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.messageLabel.textColor = [UIColor darkGrayColor];
        self.messageLabel.shadowColor = [UIColor whiteColor];
        self.messageLabel.shadowOffset = CGSizeMake(0, 1);
    }
    self.messageLabel.backgroundColor = self.backgroundColor;
}

#pragma mark - UIView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
}

- (void)layoutSubviews
{
    [self.messageLabel sizeToFit];
    const CGFloat spinnerWidth = 14;
    const CGFloat margin = 8;
    CGRect container = (CGRect){
        .size.width = CGRectGetWidth(self.messageLabel.frame) + margin + spinnerWidth,
        .size.height = spinnerWidth,
    };
    container.origin.x = (CGRectGetWidth(self.bounds) - CGRectGetWidth(container)) / 2;
    container.origin.y = CGRectGetMidY(self.bounds) - CGRectGetHeight(container) / 2;
    container = CGRectIntegral(container);
    CGRect spinnerFrame, labelFrame;
    CGRectDivide(container, &spinnerFrame, &labelFrame, spinnerWidth + margin, CGRectMinXEdge);
    spinnerFrame.size.width -= margin;
    self.spinner.frame = spinnerFrame;
    self.messageLabel.frame = labelFrame;
}

@end


@implementation AwfulGasChamberLoadingView

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.tintColor = [UIColor colorWithRed:0.082 green:0.6 blue:0.2 alpha:1];
    self.lockTintColor = YES;
    return self;
}

- (void)retheme
{
    [super retheme];
    self.messageLabel.shadowColor = nil;
}

@end


@implementation AwfulFYADLoadingView

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.tintColor = [UIColor colorWithRed:0.992 green:0.6 blue:0.6 alpha:1];
    self.lockTintColor = YES;
    return self;
}

- (void)retheme
{
    [super retheme];
    self.messageLabel.shadowColor = nil;
}

@end


@interface AwfulYOSPOSLoadingView ()

@property (nonatomic) UILabel *asciiSpinner;
@property (nonatomic) NSTimer *spinnerTimer;

@end


@implementation AwfulYOSPOSLoadingView

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = [UIColor blackColor];
    
    self.asciiSpinner = [UILabel new];
    self.asciiSpinner.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:15];
    self.asciiSpinner.backgroundColor = self.backgroundColor;
    [self advanceSpinner];
    [self addSubview:self.asciiSpinner];
    
    self.messageLabel.backgroundColor = self.backgroundColor;
    self.messageLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:13];
    return self;
}

- (void)advanceSpinner
{
    NSString *state = self.asciiSpinner.text;
    if ([state isEqualToString:@"/"]) {
        self.asciiSpinner.text = @"-";
    } else if ([state isEqualToString:@"-"]) {
        self.asciiSpinner.text = @"\\";
    } else if ([state isEqualToString:@"\\"]) {
        self.asciiSpinner.text = @"|";
    } else {
        self.asciiSpinner.text = @"/";
    }
}

- (void)retheme
{
    self.messageLabel.textColor = self.tintColor;
    self.asciiSpinner.textColor = self.tintColor;
}

#pragma mark - UIView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)startAnimating
{
    self.spinnerTimer = [NSTimer scheduledTimerWithTimeInterval:0.12
                                                         target:self
                                                       selector:@selector(spinnerTimerDidFire:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)spinnerTimerDidFire:(NSTimer *)timer
{
    [self advanceSpinner];
}

- (void)stopAnimating
{
    [self.spinnerTimer invalidate];
    self.spinnerTimer = nil;
}

- (void)layoutSubviews
{
    [self.asciiSpinner sizeToFit];
    [self.messageLabel sizeToFit];
    const CGFloat margin = 8;
    CGRect container = (CGRect){
        .size.width = (CGRectGetWidth(self.asciiSpinner.frame) + margin +
                       CGRectGetWidth(self.messageLabel.frame)),
        .size.height = CGRectGetHeight(self.asciiSpinner.frame),
    };
    container.origin.x = CGRectGetMidX(self.bounds) - CGRectGetWidth(container) / 2;
    container.origin.y = CGRectGetMidY(self.bounds) - CGRectGetHeight(container) / 2;
    container = CGRectIntegral(container);
    CGRect spinnerFrame, labelFrame;
    CGRectDivide(container, &spinnerFrame, &labelFrame,
                 CGRectGetWidth(self.asciiSpinner.frame) + margin, CGRectMinXEdge);
    spinnerFrame.size.width -= margin;
    self.asciiSpinner.frame = spinnerFrame;
    self.messageLabel.frame = labelFrame;
}

@end


@interface AwfulMacinyosLoadingView ()

@property (nonatomic) UIImageView *finderImageView;

@end


@implementation AwfulMacinyosLoadingView

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = [UIColor colorWithPatternImage:
                            [UIImage imageNamed:@"macinyos-wallpaper"]];
    
    self.finderImageView = [UIImageView new];
    self.finderImageView.image = [UIImage imageNamed:@"macinyos-loading"];
    self.finderImageView.contentMode = UIViewContentModeCenter;
    self.finderImageView.backgroundColor = [UIColor whiteColor];
    self.finderImageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.finderImageView.layer.borderWidth = 1;
    [self insertSubview:self.finderImageView atIndex:0];
    
    self.messageLabel.font = [UIFont fontWithName:@"GeezaPro" size:15];
    self.messageLabel.backgroundColor = self.finderImageView.backgroundColor;
    return self;
}

- (void)retheme
{
    // noop
}

#pragma mark - UIView

- (void)layoutSubviews
{
    CGRect finderImageFrame = CGRectMake(0, 0, 300, 275);
    finderImageFrame.origin.x = CGRectGetMidX(self.bounds) - CGRectGetWidth(finderImageFrame) / 2;
    finderImageFrame.origin.y = CGRectGetMidY(self.bounds) - CGRectGetHeight(finderImageFrame) / 2;
    finderImageFrame = CGRectIntegral(finderImageFrame);
    self.finderImageView.frame = finderImageFrame;
    CGFloat bottomMargin = (CGRectGetHeight(finderImageFrame) -
                            self.finderImageView.image.size.height) / 2;
    [self.messageLabel sizeToFit];
    self.messageLabel.center = CGPointMake(CGRectGetMidX(finderImageFrame),
                                           CGRectGetMaxY(finderImageFrame) - bottomMargin / 2);
}

@end


@interface AwfulWinpos95LoadingView ()

@property (nonatomic) UIImageView *hourglassImageView;

@end


@implementation AwfulWinpos95LoadingView

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    self.backgroundColor = [UIColor colorWithRed:0.067 green:0.502 blue:0.502 alpha:1];
    
    self.hourglassImageView = [UIImageView new];
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:@"hourglass" withExtension:@"gif"];
    FVGifAnimation *gif = [[FVGifAnimation alloc] initWithURL:gifURL];
    [gif setAnimationToImageView:self.hourglassImageView];
    [self addSubview:self.hourglassImageView];
    UIPanGestureRecognizer *pan = [UIPanGestureRecognizer new];
    [pan addTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:pan];
    
    self.messageLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:13];
    self.messageLabel.backgroundColor = self.backgroundColor;
    return self;
}

- (void)didPan:(UIPanGestureRecognizer *)pan
{
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.hourglassImageView.center = [pan locationInView:self];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [pan translationInView:self];
        self.hourglassImageView.frame = CGRectOffset(self.hourglassImageView.frame,
                                                     translation.x, translation.y);
        [pan setTranslation:CGPointZero inView:self];
    }
}

- (void)retheme
{
    // noop
}

#pragma mark - UIView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        [self.hourglassImageView startAnimating];
    } else {
        [self.hourglassImageView stopAnimating];
    }
}

- (void)layoutSubviews
{
    [self.hourglassImageView sizeToFit];
    [self.messageLabel sizeToFit];
    const CGFloat margin = 8;
    CGRect container = (CGRect){
        .size.width = (CGRectGetWidth(self.hourglassImageView.frame) + margin +
                       CGRectGetWidth(self.messageLabel.frame)),
        .size.height = CGRectGetHeight(self.hourglassImageView.frame),
    };
    container.origin.x = CGRectGetMidX(self.bounds) - CGRectGetWidth(container) / 2;
    container.origin.y = CGRectGetMidY(self.bounds) - CGRectGetHeight(container) / 2;
    container = CGRectIntegral(container);
    CGRect hourglassFrame, labelFrame;
    CGRectDivide(container, &hourglassFrame, &labelFrame,
                 CGRectGetWidth(self.hourglassImageView.frame) + margin, CGRectMinXEdge);
    hourglassFrame.size.width -= margin;
    self.hourglassImageView.frame = hourglassFrame;
    self.messageLabel.frame = labelFrame;
}

@end
