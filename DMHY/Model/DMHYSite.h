//
//  DMHYSite.h
//  DMHY
//
//  Created by 小笠原やきん on 7/16/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DMHYKeyword;

NS_ASSUME_NONNULL_BEGIN

@interface DMHYSite : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

+ (DMHYSite *)entityFormDictionary:(NSDictionary *)site inManagedObjectContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END

#import "DMHYSite+CoreDataProperties.h"
