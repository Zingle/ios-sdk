//
//  ZNGLabel.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNGLabel : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong, nullable) NSString* labelId;
@property(nonatomic, strong, nullable) NSString* displayName;
@property(nonatomic, strong, nullable) NSString* backgroundColor;
@property(nonatomic, strong, nullable) NSString* textColor;
@property(nonatomic) BOOL isGlobal;

- (UIColor *)textUIColor;
- (UIColor *)backgroundUIColor;

- (BOOL) matchesSearchTerm:(NSString *)term;

NS_ASSUME_NONNULL_END

@end
