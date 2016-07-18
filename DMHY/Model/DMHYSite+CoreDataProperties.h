//
//  DMHYSite+CoreDataProperties.h
//  DMHY
//
//  Created by 小笠原やきん on 7/16/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DMHYSite.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHYSite (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *mainURL;
@property (nullable, nonatomic, retain) NSString *searchURL;
@property (nullable, nonatomic, retain) NSNumber *isAutoDownload;
@property (nullable, nonatomic, retain) NSString *downloadType;
@property (nullable, nonatomic, retain) NSNumber *isDownloadFin;
@property (nullable, nonatomic, retain) NSNumber *isCurrentUse;
@property (nullable, nonatomic, retain) NSNumber *isFliterSite;
@property (nullable, nonatomic, retain) NSDate *createDate;
@property (nullable, nonatomic, retain) NSString *responseType;
@property (nullable, nonatomic, retain) NSSet<DMHYKeyword *> *keywords;

@end

@interface DMHYSite (CoreDataGeneratedAccessors)

- (void)addKeywordsObject:(DMHYKeyword *)value;
- (void)removeKeywordsObject:(DMHYKeyword *)value;
- (void)addKeywords:(NSSet<DMHYKeyword *> *)values;
- (void)removeKeywords:(NSSet<DMHYKeyword *> *)values;

@end

NS_ASSUME_NONNULL_END
