//
//  DMHYAPI.h
//  DMHY
//
//  Created by 小笠原やきん on 15/8/31.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#ifndef DMHYAPI_h
#define DMHYAPI_h

#define IS_DEBUG_MODE 0

#define DMHYRSS                       @"https://share.dmhy.org/topics/rss/rss.xml"
#define DMHYSearchByKeyword           @"https://share.dmhy.org/topics/rss/rss.xml?keyword=%@"

#define DMHYdandanplayRSS             @"http://dmhy.dandanplay.com/topics/rss/rss.xml"
#define DMHYdandanplaySearchByKeyword @"http://dmhy.dandanplay.com/topics/rss/rss.xml?keyword=%@"

#define DMHYACGGGRSS                  @"http://bt.acg.gg/rss.xml"
#define DMHYACGGGSearchByKeyword      @"http://bt.acg.gg/rss.xml?keyword=%@"

// BangumiMoe return JSON data. Also can set placeholder to [page][limit].
#define DMHYBangumiMoeRSS             @"https://bangumi.moe/api/v2/torrent/page/1?limit=50"
#define DMHYBangumiMoeSearchByKeyword @"https://bangumi.moe/api/v2/torrent/search?limit=50&p=1&query=%@"

#define kXpathTorrentDownloadShortURL   @"//div[@class='dis ui-tabs-panel ui-widget-content ui-corner-bottom']/a/@href"
#define kTest                           @"//div[@class='dis']//p//a//@href"

#define DMHYURLPrefixFormat             @"https:%@"
#define DMHYDandanplayURLPrefixFormat   @"http:%@"

#define DMHYBangumiMoeAPITorrentPagePrefixFormat  @"https://bangumi.moe/api/v2/torrent/%@"
#define DMHYBangumiMoeOpenTorrentPagePrefixFormat @"https://bangumi.moe/torrent/%@"

#define kXPathTorrentItem @"//item"
#define kDownloadLinkType @"DownloadLinkType"
#define kDownloadSite     @"DownloadSite"
#define kSavePath         @"SavePath"
#define kSelectKeyword    @"SelectKeyword"
#define kFetchInterval    @"FetchInterval"
#define kSelectKeywordIsSubKeyword @"SelectKeywordIsSubKeyword"

#define kFetchIntervalMinimum 30   //5 minutes
#define kFetchIntervalMaximun 43200 //12 hours

#define DMHYDownloadLinkTypeNotification       @"DMHYDownloadLinkTypeNotification"
#define DMHYSavePathChangedNotification        @"DMHYSavaPathChangedNotification"
#define DMHYSelectKeywordChangedNotification   @"DMHYSelectKeywordChangedNotification"
#define DMHYInitialWeekdayCompleteNotification @"DMHYInitialWeekdayCompleteNotification"
#define DMHYFetchIntervalChangedNotification   @"DMHYFetchIntervalChangedNotification"
#define DMHYThemeChangedNotification           @"DMHYThemeChangedNotification"
#define DMHYDownloadSiteChangedNotification    @"DMHYDownloadSiteChangedNotification"

#define DMHYKeywordEntityKey @"Keyword"
#define DMHYTorrentEntityKey @"Torrent"

#define DMHYThemeKey @"ThemeType"

typedef NS_ENUM(NSInteger, DMHYThemeType) {
    DMHYThemeLight,
    DMHYThemeDark
};

typedef NS_ENUM(NSInteger, DMHYSite) {
    DMHYSiteDefault,
    DMHYSiteDandanplay,
    DMHYSiteACGGG,
    DMHYSiteBangumiMoe
};

#endif /* DMHYAPI_h */
