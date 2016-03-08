

#import "ZNGInputToolbar.h"

#import "ZNGComposerTextView.h"

#import "ZNGToolbarButtonFactory.h"

#import "UIColor+ZingleSDK.h"
#import "UIImage+ZingleSDK.h"
#import "UIView+ZingleSDK.h"

static void * kZNGInputToolbarKeyValueObservingContext = &kZNGInputToolbarKeyValueObservingContext;


@interface ZNGInputToolbar ()

@property (assign, nonatomic) BOOL zng_isObserving;

- (void)zng_leftBarButtonPressed:(UIButton *)sender;
- (void)zng_rightBarButtonPressed:(UIButton *)sender;

- (void)zng_addObservers;
- (void)zng_removeObservers;

@end



@implementation ZNGInputToolbar

@dynamic delegate;

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.zng_isObserving = NO;
    self.sendButtonOnRight = YES;

    self.preferredDefaultHeight = 44.0f;
    self.maximumHeight = NSNotFound;

    ZNGToolbarContentView *toolbarContentView = [self loadToolbarContentView];
    toolbarContentView.frame = self.frame;
    [self addSubview:toolbarContentView];
    [self zng_pinAllEdgesOfSubview:toolbarContentView];
    [self setNeedsUpdateConstraints];
    _contentView = toolbarContentView;

    [self zng_addObservers];

    self.contentView.leftBarButtonItem = [ZNGToolbarButtonFactory defaultAccessoryButtonItem];
    self.contentView.rightBarButtonItem = [ZNGToolbarButtonFactory defaultSendButtonItem];

    [self toggleSendButtonEnabled];
}

- (ZNGToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[ZNGInputToolbar class]] loadNibNamed:NSStringFromClass([ZNGToolbarContentView class])
                                                                                          owner:nil
                                                                                        options:nil];
    return nibViews.firstObject;
}

- (void)dealloc
{
    [self zng_removeObservers];
    _contentView = nil;
}

#pragma mark - Setters

- (void)setPreferredDefaultHeight:(CGFloat)preferredDefaultHeight
{
    NSParameterAssert(preferredDefaultHeight > 0.0f);
    _preferredDefaultHeight = preferredDefaultHeight;
}

#pragma mark - Actions

- (void)zng_leftBarButtonPressed:(UIButton *)sender
{
    [self.delegate messagesInputToolbar:self didPressLeftBarButton:sender];
}

- (void)zng_rightBarButtonPressed:(UIButton *)sender
{
    [self.delegate messagesInputToolbar:self didPressRightBarButton:sender];
}

#pragma mark - Input toolbar

- (void)toggleSendButtonEnabled
{
    BOOL hasText = [self.contentView.textView hasText];

    if (self.sendButtonOnRight) {
        self.contentView.rightBarButtonItem.enabled = hasText;
    }
    else {
        self.contentView.leftBarButtonItem.enabled = hasText;
    }
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kZNGInputToolbarKeyValueObservingContext) {
        if (object == self.contentView) {

            if ([keyPath isEqualToString:NSStringFromSelector(@selector(leftBarButtonItem))]) {

                [self.contentView.leftBarButtonItem removeTarget:self
                                                          action:NULL
                                                forControlEvents:UIControlEventTouchUpInside];

                [self.contentView.leftBarButtonItem addTarget:self
                                                       action:@selector(zng_leftBarButtonPressed:)
                                             forControlEvents:UIControlEventTouchUpInside];
            }
            else if ([keyPath isEqualToString:NSStringFromSelector(@selector(rightBarButtonItem))]) {

                [self.contentView.rightBarButtonItem removeTarget:self
                                                           action:NULL
                                                 forControlEvents:UIControlEventTouchUpInside];

                [self.contentView.rightBarButtonItem addTarget:self
                                                        action:@selector(zng_rightBarButtonPressed:)
                                              forControlEvents:UIControlEventTouchUpInside];
            }

            [self toggleSendButtonEnabled];
        }
    }
}

- (void)zng_addObservers
{
    if (self.zng_isObserving) {
        return;
    }

    [self.contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                          options:0
                          context:kZNGInputToolbarKeyValueObservingContext];

    [self.contentView addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                          options:0
                          context:kZNGInputToolbarKeyValueObservingContext];

    self.zng_isObserving = YES;
}

- (void)zng_removeObservers
{
    if (!_zng_isObserving) {
        return;
    }

    @try {
        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(leftBarButtonItem))
                             context:kZNGInputToolbarKeyValueObservingContext];

        [_contentView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(rightBarButtonItem))
                             context:kZNGInputToolbarKeyValueObservingContext];
    }
    @catch (NSException *__unused exception) { }
    
    _zng_isObserving = NO;
}

@end
