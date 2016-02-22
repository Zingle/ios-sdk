//
//  ZNGMessageEntryView.h
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGMessageEntryView;
@protocol ZNGMessageEntryDelegate <NSObject>

- (void)messageEntryTextDidChange:(ZNGMessageEntryView*)messageEntryView;

@end

@interface ZNGMessageEntryView : UIView

@property (copy, nonatomic) NSString* text;
@property (strong, nonatomic) UITextView* textView;
@property (weak, nonatomic) id<ZNGMessageEntryDelegate> delegate;

@end
