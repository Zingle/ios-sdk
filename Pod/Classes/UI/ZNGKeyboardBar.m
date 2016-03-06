//
//  ZNGKeyboardBar.m
//  Pods
//
//  Created by Ryan Farley on 3/4/16.
//
//

#import "ZNGKeyboardBar.h"

@implementation ZNGKeyboardBar

- (id)init {
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(0,0, CGRectGetWidth(screen), 40);
    self = [self initWithFrame:frame];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if(self) {
        
        self.backgroundColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
        
        self.textView = [[UITextView alloc]initWithFrame:CGRectInset(frame, 10, 5)];
        self.textView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        [self addSubview:self.textView];
    }
    return self;
}

@end