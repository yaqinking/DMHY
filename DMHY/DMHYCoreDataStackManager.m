//
//  DMHYCoreDataStackManager.m
//  DMHY
//
//  Created by 小笠原やきん on 9/22/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "DMHYCoreDataStackManager.h"

NSString *const ApplicationDocumentsDirectoryName = @"com.yaqinking.DMHY";
NSString *const MainStoreFileName                 = @"DMHY.storedata";
NSString *const ErrorDomain                       = @"CoreDataStackManager";

@implementation DMHYCoreDataStackManager

#pragma mark - synthesize

@synthesize managedObjectModel            = _managedObjectModel;
@synthesize persistentStoreCoordinator    = _persistentStoreCoordinator;
@synthesize applicationDocumentsDirectory = _applicationDocumentsDirectory;
@synthesize storeURL                      = _storeURL;

+ (instancetype)sharedManager {
    static DMHYCoreDataStackManager *shareManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[self alloc] init];
    });
    
    return shareManager;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DMHY"
                                              withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return _managedObjectModel;
}

- (NSURL *)applicationDocumentsDirectory {
    if (!_applicationDocumentsDirectory) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *URLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                            inDomains:NSUserDomainMask];
        NSURL *URL = URLs[URLs.count - 1];
        URL = [URL URLByAppendingPathComponent:ApplicationDocumentsDirectoryName];
        NSError *error = nil;
        NSDictionary *properties = [URL resourceValuesForKeys:@[NSURLIsDirectoryKey]
                                                        error:&error];
        if (properties) {
            NSNumber *isDirectoryNumber = properties[NSURLIsDirectoryKey];
            if (isDirectoryNumber && !isDirectoryNumber.boolValue) {
                NSString *description = NSLocalizedString(@"Could not access the application folder...", @"Failed to initialize applicationSupportDirectory >_<");
                NSString *reason = NSLocalizedString(@"Found a file in its place.", @"Failed to initialize applicationSupportDirectory");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description,
                                           NSLocalizedFailureReasonErrorKey : reason};
                error = [NSError errorWithDomain:ErrorDomain
                                            code:101
                                        userInfo:userInfo];
                [NSApp presentError:error];
                return nil;
            }
        } else {
            if (error.code == NSFileReadNoSuchFileError) {
                BOOL ok = [fileManager createDirectoryAtPath:URL.path
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error];
                if (!ok) {
                    [NSApp presentError:error];
                    return nil;
                }
            }
        }
        _applicationDocumentsDirectory = URL;
    }
    return _applicationDocumentsDirectory;
}

- (NSURL *)storeURL {
    if (!_storeURL) {
        _storeURL = [self.applicationDocumentsDirectory URLByAppendingPathComponent:MainStoreFileName];
    }
    return _storeURL;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    NSURL *url = self.storeURL;
    if (!url) {
        return nil;
    }
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @(YES),
                              NSInferMappingModelAutomaticallyOption : @(YES),
                              };
    NSError *error;
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:url
                                 options:options
                                   error:&error]) {
        [NSApp presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = psc;
    return _persistentStoreCoordinator;
}

- (BOOL)resetDatabase {
    NSURL *storedURL = [self storeURL];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:storedURL.path]) {
        if (![fileManager removeItemAtURL:storedURL error:&error]) {
            [NSApp presentError:error];
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

@end
