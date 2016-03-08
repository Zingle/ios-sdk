

#import "ZNGLoadEarlierHeaderView.h"

#import "NSBundle+ZingleSDK.h"


const CGFloat kZNGLoadEarlierHeaderViewHeight = 32.0f;


@interface ZNGLoadEarlierHeaderView ()

@property (weak, nonatomic) IBOutlet UIButton *loadButton;

- (IBAction)loadButtonPressed:(UIButton *)sender;

@end



@implementation ZNGLoadEarlierHeaderView

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ZNGLoadEarlierHeaderView class])
                          bundle:[NSBundle bundleForClass:[ZNGLoadEarlierHeaderView class]]];
}

+ (NSString *)headerReuseIdentifier
{
    return NSStringFromClass([ZNGLoadEarlierHeaderView class]);
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.backgroundColor = [UIColor clearColor];

    [self.loadButton setTitle:[NSBundle zng_localizedStringForKey:@"load_earlier_messages"] forState:UIControlStateNormal];
    self.loadButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)dealloc
{
    _loadButton = nil;
    _delegate = nil;
}

#pragma mark - Reusable view

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.loadButton.backgroundColor = backgroundColor;
}

#pragma mark - Actions

- (IBAction)loadButtonPressed:(UIButton *)sender
{
    [self.delegate headerView:self didPressLoadButton:sender];
}

@end
