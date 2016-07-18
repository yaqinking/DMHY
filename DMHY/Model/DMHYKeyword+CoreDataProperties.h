//
//  DMHYKeyword+CoreDataProperties.h
//  DMHY
//
//  Created by 小笠原やきん on 7/16/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DMHYKeyword.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHYKeyword (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createDate;
@property (nullable, nonatomic, retain) NSNumber *isSubKeyword;
@property (nullable, nonatomic, retain) NSString *keyword;
@property (nullable, nonatomic, retain) NSSet<DMHYKeyword *> *subKeywords;
@property (nullable, nonatomic, retain) NSSet<DMHYTorrent *> *torrents;
@property (nullable, nonatomic, retain) DMHYSite *site;

@end

@interface DMHYKeyword (CoreDataGeneratedAccessors)

- (void)addSubKeywordsObject:(DMHYKeyword *)value;
- (void)removeSubKeywordsObject:(DMHYKeyword *)value;
- (void)addSubKeywords:(NSSet<DMHYKeyword *> *)values;
- (void)removeSubKeywords:(NSSet<DMHYKeyword *> *)values;

- (void)addTorrentsObject:(DMHYTorrent *)value;
- (void)removeTorrentsObject:(DMHYTorrent *)value;
- (void)addTorrents:(NSSet<DMHYTorrent *> *)values;
- (void)removeTorrents:(NSSet<DMHYTorrent *> *)values;

@end

NS_ASSUME_NONNULL_END
