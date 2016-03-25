//
//  ZNGPagedArray.h
//  Pods
//
//  Created by Ryan Farley on 3/25/16.
//
//

#import <Foundation/Foundation.h>

@protocol ZNGPagedArrayDelegate;

/**
 * This class acts as a proxy for NSArray, when data is loaded in batches, called "pages".
 * @discussion The recommendation is to use this class in conjunction with a data controller class which populates the paged array with pages of data, while casting the paged array back as an NSArray to its owner.
 * 
 * This class is inspired by NSFetchRequest's batching mechanism which returns a custom NSArray subclass.
 * @see NSFetchRequest fetchBatchSize
 */
@interface ZNGPagedArray : NSProxy

/**
 * The designated initializer for this class
 * Note that the parameters are part of immutable state
 */
- (instancetype)initWithCount:(NSUInteger)count objectsPerPage:(NSUInteger)objectsPerPage initialPageIndex:(NSInteger)initialPageIndex;

/**
 * Convenience initializer with initialPageIndex = 1
 */
- (instancetype)initWithCount:(NSUInteger)count objectsPerPage:(NSUInteger)objectsPerPage;

/**
 * Sets objects for a specific page in the array
 * @param objects The objects in the page
 * @param page The page which these objects should be set for, pages start with index 1
 * @throws ZNGPagedArrayObjectsPerPageMismatchException when page size mismatch the initialized objectsPerPage property
 * for any page other than the last.
 */
- (void)setObjects:(NSArray *)objects forPage:(NSUInteger)page;

- (NSUInteger)pageForIndex:(NSUInteger)index;
- (NSIndexSet *)indexSetForPage:(NSUInteger)page;

@property (nonatomic, readonly) NSUInteger objectsPerPage;
@property (nonatomic, readonly) NSUInteger numberOfPages;
@property (nonatomic, readonly) NSInteger initialPageIndex;

/**
 * Contains NSArray instances of pages, backing the data
 */
@property (nonatomic, readonly) NSDictionary *pages;

@property (nonatomic, weak) id<ZNGPagedArrayDelegate> delegate;

@end


@protocol ZNGPagedArrayDelegate <NSObject>

/**
 * Called when the an object is accessed by index
 *
 * @param pagedArray the paged array being accessed
 * @param index the index in the paged array
 * @param returnObject an id pointer to the object which will be returned to the receiver of the accessor being called.
 *
 * @discussion This delegate method is only called when the paged array is accessed by the objectAtIndex: method or by subscripting.
 * The returnObject pointer can be changed in order to change which object will be returned.
 */
- (void)pagedArray:(ZNGPagedArray *)pagedArray willAccessIndex:(NSUInteger)index returnObject:(__autoreleasing id *)returnObject;

@end
