//
//  ZNGComposerTextView.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//
#import <UIKit/UIKit.h>

@class ZNGComposerTextView;

/**
 *  A delegate object used to notify the receiver of paste events from a `ZNGComposerTextView`.
 */
@protocol ZNGComposerTextViewPasteDelegate <NSObject>

/**
 *  Asks the delegate whether or not the `textView` should use the original implementation of `-[UITextView paste]`.
 *
 *  @discussion Use this delegate method to implement custom pasting behavior. 
 *  You should return `NO` when you want to handle pasting. 
 *  Return `YES` to defer functionality to the `textView`.
 */
- (BOOL)composerTextView:(ZNGComposerTextView *)textView shouldPasteWithSender:(id)sender;

@end

/**
 *  An instance of `ZNGComposerTextView` is a subclass of `UITextView` that is styled and used 
 *  for composing messages in a `ZNGBaseViewController`. It is a subview of a `ZNGToolbarContentView`.
 */
@interface ZNGComposerTextView : UITextView

/**
 *  The text to be displayed when the text view is empty. The default value is `nil`.
 */
@property (copy, nonatomic) NSString *placeHolder;

/**
 *  The color of the place holder text. The default value is `[UIColor lightGrayColor]`.
 */
@property (strong, nonatomic) UIColor *placeHolderTextColor;

/**
 *  The object that acts as the paste delegate of the text view.
 */
@property (weak, nonatomic) id<ZNGComposerTextViewPasteDelegate> pasteDelegate;

/**
 *  Determines whether or not the text view contains text after trimming white space 
 *  from the front and back of its string.
 *
 *  @return `YES` if the text view contains text, `NO` otherwise.
 */
- (BOOL)hasText;

@end
