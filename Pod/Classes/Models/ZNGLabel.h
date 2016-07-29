//
//  ZNGLabel.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGLabel : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* labelId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* backgroundColor;
@property(nonatomic, strong) NSString* textColor;
@property(nonatomic) BOOL isGlobal;

- (UIColor *)textUIColor;
- (UIColor *)backgroundUIColor;

- (BOOL) matchesSearchTerm:(NSString *)term;

@end
