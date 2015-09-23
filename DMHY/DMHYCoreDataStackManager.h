//
//  DMHYCoreDataStackManager.h
//  DMHY
//
//  Created by 小笠原やきん on 9/22/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Cocoa;

@interface DMHYCoreDataStackManager : NSObject

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly) NSURL *storeURL;
@property (nonatomic, readonly) NSURL *applicationDocumentsDirectory;

+ (instancetype)sharedManager;

@end
