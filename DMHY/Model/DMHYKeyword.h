//
//  DMHYKeyword.h
//  DMHY
//
//  Created by 小笠原やきん on 9/23/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DMHYTorrent;
@class DMHYSite;

NS_ASSUME_NONNULL_BEGIN

@interface DMHYKeyword : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

+ (DMHYKeyword *)entityForKeywordName:(NSString *)name isSubKeyword:(NSNumber *)subKeyword inManagedObjectContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END

#import "DMHYKeyword+CoreDataProperties.h"
