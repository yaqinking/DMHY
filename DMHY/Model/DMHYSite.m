//
//  DMHYSite.m
//  DMHY
//
//  Created by 小笠原やきん on 7/16/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYSite.h"
#import "DMHYKeyword.h"
#import "DMHYAPI.h"

@implementation DMHYSite

// Insert code here to add functionality to your managed object subclass

+ (DMHYSite *)entityFormDictionary:(NSDictionary *)site inManagedObjectContext:(NSManagedObjectContext *)context {
    DMHYSite *siteEntity = [NSEntityDescription insertNewObjectForEntityForName:DMHYSiteEntityKey inManagedObjectContext:context];
    siteEntity.name = site[DMHYSiteNameKey];
    siteEntity.mainURL = site[DMHYSiteMainURLKey];
    siteEntity.searchURL = site[DMHYSiteSearchURLKey];
    siteEntity.isFliterSite = site[DMHYSiteFliterKey];
    siteEntity.isAutoDownload = site[DMHYSiteAutoDLKey];
    siteEntity.downloadType = site[DMHYSiteDLTypeKey];
    siteEntity.isDownloadFin = site[DMHYSiteDLFinKey];
    siteEntity.responseType = site[DMHYSiteResponseTypeKey];
    siteEntity.isCurrentUse = site[DMHYSiteCurrentUseKey];
    siteEntity.createDate = [NSDate new];
    return siteEntity;
}

@end
