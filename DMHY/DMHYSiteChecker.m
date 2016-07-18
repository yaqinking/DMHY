//
//  DMHYSiteChecker.m
//  DMHY
//
//  Created by 小笠原やきん on 7/16/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYSiteChecker.h"
#import "DMHYTool.h"
#import "DMHYAPI.h"
#import "DMHYCoreDataStackManager.h"
#import "AFNetworking.h"
#import "Ono.h"
#import "DMHYXMLDataManager.h"
#import "DMHYJSONDataManager.h"

@interface DMHYSiteChecker()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *today;
@property (nonatomic, strong) NSDateFormatter *dateFormater;

@property (nonatomic) BOOL isMagnetLink;
@property (nonatomic) BOOL dontDownloadCollection;

@end

@implementation DMHYSiteChecker

- (void)invalidateTimer {
    [self.timer invalidate];
    self.timer = nil;
}


- (void)startWitchCheckInterval:(NSTimeInterval)checkInterval {
    if (checkInterval >= 300) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:checkInterval
                                                      target:self
                                                    selector:@selector(automaticDownloadTorrent)
                                                    userInfo:nil
                                                     repeats:YES];
    } else {
        NSString *reason = [NSString stringWithFormat:@"\nFetch interval value is invalid. Current %li", (long)checkInterval];
        NSString *suggestion = [NSString stringWithFormat:@"You can open Terminal.app type\n\ndefaults write %@ FetchInterval 300\n\nThen press Enter key.\nRestart app to fix it.", AppDomain];
        NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey : reason,
                                    NSLocalizedRecoverySuggestionErrorKey : suggestion};
        NSError *error = [NSError errorWithDomain:AppDomain code:4444 userInfo:userInfo];
        [NSApp presentError:error];
        [NSApp terminate:self];
    }
}

/**
 *  Check wheather today has new torrent. 其它分类下的每次都 fetch。
 *  Then invoke downloadNewTorrents:
 *  @param weekday today string
 */
- (void)automaticDownloadTorrent {
    NSDate *now            = [NSDate new];
    NSCalendar* cal        = [NSCalendar currentCalendar];
    NSDateComponents *com  = [cal components:NSCalendarUnitWeekday fromDate:now];
    NSInteger weekdayToday = [com weekday];// 1 = Sunday, 2 = Monday, etc.
    self.today              = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday];
    
    NSArray<DMHYSite *> *sites = [[DMHYCoreDataStackManager sharedManager] autoDownloadSites];
    [sites enumerateObjectsUsingBlock:^(DMHYSite * _Nonnull site, NSUInteger idx, BOOL * _Nonnull stop) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyword == %@ OR keyword == %@", self.today, kWeekdayOther];
        NSArray<DMHYKeyword *> *flitedKeywords = [[site.keywords allObjects] filteredArrayUsingPredicate:predicate];
        [flitedKeywords enumerateObjectsUsingBlock:^(DMHYKeyword * _Nonnull parentKeyword, NSUInteger idx, BOOL * _Nonnull stop) {
            [parentKeyword.subKeywords enumerateObjectsUsingBlock:^(DMHYKeyword * _Nonnull keyword, BOOL * _Nonnull stop) {
                if ([site.responseType isEqualToString:@"xml"]) {
                    [[DMHYXMLDataManager manager] fetchFromSite:site queryKeyword:keyword fetchedNew:^(DMHYTorrent *torrent) {
                        if ([site.name isEqualToString:@"dmhy"]) {
                            [[DMHYDownloader downloader] downloadTorrentFromPageURLString:torrent.link];
                        } else {
                            NSURL *url = [NSURL URLWithString:torrent.magnet];
                            // acg.rip contains .torrent bt.acg.gg contains down.php
                            if ([torrent.magnet containsString:@".torrent"] ||
                                [torrent.magnet containsString:@"down.php"]) {
                                [[DMHYDownloader downloader] downloadTorrentWithURL:url];
                                // Think this wil place to downloader completion handler?
                                torrent.isDownloaded = @YES;
                                torrent.isNewTorrent = @NO;
                            }
                            if ([torrent.magnet containsString:@"magnet:?xt=urn:btih:"]) {
                                [[NSWorkspace sharedWorkspace] openURL:url];
                                torrent.isDownloaded = @YES;
                                torrent.isNewTorrent = @NO;
                            }
                        }
                    } completion:^{
                        NSLog(@"Site %@ Keyword %@ Check completed.", site.name, keyword.keyword);
                        // When all task complated save changes.
                        [[DMHYCoreDataStackManager sharedManager] saveContext];
                        [DMHYNotification postNotificationName:DMHYKeywordCheckedNotification userInfo:@{@"site": site.name,
                                                                                                         @"keyword": keyword.keyword}];
                    } failure:^(NSError *error) {
                        NSLog(@"Site %@ Keyword %@ Check error %@", site.name, keyword.keyword, [error localizedDescription]);
                    }];
                }
                if ([site.responseType isEqualToString:@"json"]) {
                   
                }
            }];
        }];
    }];
}


#pragma mark - Download

- (void)openMagnetWith:(NSURL *)magnet {
    [[NSWorkspace sharedWorkspace] openURL:magnet];
}

@end
