//
//  ZNGMessageEntryView.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGMessageEntryView.h"

@interface ZNGMessageEntryView () <UITextViewDelegate>

@property (assign, nonatomic)NSUInteger lastTextLength;
@property (strong, nonatomic)UIView *outterTextView;
@property (strong, nonatomic)UIImageView *tailImageView;
@property (assign, nonatomic)BOOL needsConstraintsSetup;

@end

const CGFloat ZNGTailViewInset = 8.0;
const CGFloat ZNGButtonCornerRadius = 5;
const CGFloat ZNGMargin = 12;

@implementation ZNGMessageEntryView

#pragma mark - Properties
- (void)setBackgroundColor:(UIColor *)backgroundColor{
    self.outterTextView.backgroundColor = backgroundColor;
}

- (void)setText:(NSString *)text{
    self.textView.text = text;
}

- (NSString*)text{
    return self.textView.text;
}

#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super initWithCoder:aDecoder];
    if(self){
        super.backgroundColor   = [UIColor clearColor];
        
        self.outterTextView                     = [[UIView alloc] init];
        self.outterTextView.backgroundColor     = [UIColor clearColor];
        self.outterTextView.layer.cornerRadius  = 5;
        self.outterTextView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.tailImageView                      = [[UIImageView alloc] init];
        self.tailImageView.backgroundColor      = [UIColor clearColor];
        self.tailImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.tailImageView.image                = [UIImage imageNamed:@"message_tail_whiteLowRight"];
        
        self.textView                           = [[UITextView alloc] init];
        self.textView.delegate                  = self;
        self.textView.backgroundColor           = [UIColor clearColor];
        self.textView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.textView.textContainer.lineFragmentPadding = 0;
        self.textView.textContainerInset = UIEdgeInsetsZero;
        
        [self addSubview:self.tailImageView];
        [self.outterTextView addSubview:self.textView];
        [self addSubview:self.outterTextView];
        [self sendSubviewToBack:self.outterTextView];
        
        self.needsConstraintsSetup = YES;
    }
    
    return self;
}

#pragma mark Drawing
- (void)setupConstraints{
    [self.outterTextView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.textView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.tailImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.tailImageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.tailImageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    NSArray* constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[textView]|"
                                                                   options:0
                                                                   metrics:@{@"margin": @(ZNGMargin)}
                                                                     views:@{@"textView": self.textView}];
    [self.outterTextView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[textView]-margin-|"
                                                          options:0
                                                          metrics:@{@"margin": @(ZNGMargin)}
                                                            views:@{@"textView": self.textView}];
    [self.outterTextView addConstraints:constraints];
    
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textOutterView]|"
                                                          options:0
                                                          metrics:nil
                                                            views:@{@"textOutterView": self.outterTextView}];
    [self addConstraints:constraints];
    
    [self setupTailConstraints];
    self.needsConstraintsSetup = NO;
}

- (void)setupTailConstraints{
    
    NSArray* constraints;
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textOutterView]-tailInset-[tailView]|"
                                                          options:0
                                                          metrics:@{@"tailInset": @(-ZNGTailViewInset)}
                                                            views:@{@"textOutterView": self.outterTextView, @"tailView": self.tailImageView}];
    [self addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[tailView]-tailVerticalAdjustment-|"
                                                          options:0
                                                          metrics:@{@"tailVerticalAdjustment": @(-.5)}
                                                            views:@{@"tailView": self.tailImageView}];
    [self addConstraints:constraints];
}

#pragma mark Overrides
- (void)updateConstraints{
    if(self.needsConstraintsSetup){
        [self setupConstraints];
    }
    
    [super updateConstraints];
}

- (CGSize)sizeThatFits:(CGSize)size{
    CGFloat fixedWidth  = size.width - self.tailImageView.frame.size.width + ZNGTailViewInset - ZNGMargin * 2;
    
    //Fit to textView
    CGSize newSize = [self.textView sizeThatFits:CGSizeMake(fixedWidth, size.height)];
    //Pad for outter view
    newSize = CGSizeMake(newSize.width, newSize.height + ZNGMargin * 2);
    return newSize;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView{
    if(self.delegate){
        [self.delegate messageEntryTextDidChange:self];
    }
}
@end
