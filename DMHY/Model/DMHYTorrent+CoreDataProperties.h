//
//  DMHYTorrent+CoreDataProperties.h
//  DMHY
//
//  Created by 小笠原やきん on 16/2/28.
//  Copyright © 2016年 yaqinking. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DMHYTorrent.h"

NS_ASSUME_NONNULL_BEGIN

@interface DMHYTorrent (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *author;
@property (nullable, nonatomic, retain) NSString *category;
@property (nullable, nonatomic, retain) NSNumber *isDownloaded;
@property (nullable, nonatomic, retain) NSNumber *isNewTorrent;
@property (nullable, nonatomic, retain) NSString *link;
@property (nullable, nonatomic, retain) NSString *magnet;
@property (nullable, nonatomic, retain) NSDate *pubDate;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) DMHYKeyword *keyword;

@end

NS_ASSUME_NONNULL_END
