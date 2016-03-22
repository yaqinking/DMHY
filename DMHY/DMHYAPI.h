//
//  DMHYAPI.h
//  DMHY
//
//  Created by 小笠原やきん on 15/8/31.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#ifndef DMHYAPI_h
#define DMHYAPI_h

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
#define kXpathTorrentDirectDownloadLink @"//div[@class='dis']//p//a//@href"

#define DMHYURLPrefixFormat             @"https:%@"
#define DMHYDandanplayURLPrefixFormat   @"http:%@"

#define DMHYBangumiMoeAPITorrentPagePrefixFormat  @"https://bangumi.moe/api/v2/torrent/%@"
#define DMHYBangumiMoeOpenTorrentPagePrefixFormat @"https://bangumi.moe/torrent/%@"

#define DMHY       @"share.dmhy.org"
#define Dandanplay @"dmhy.dandanplay.com"
#define ACGGG      @"bt.acg.gg"
#define BangumiMoe @"bangumi.moe"

// bgmlist GitHub raw json file
#define BGMListYearSeasonFormat @"https://raw.githubusercontent.com/wxt2005/bangumi-list/master/json/bangumi-%@%@.json"

#define kXPathTorrentItem @"//item"
#define kDownloadLinkType @"DownloadLinkType"
#define kDownloadSite     @"DownloadSite"
#define kSavePath         @"SavePath"
#define kFileWatchPath @"FileWatchPath"
#define kSelectKeyword    @"SelectKeyword"
#define kSelectKeywordIsSubKeyword @"SelectKeywordIsSubKeyword"
#define kWeekdayOther @"其他"
#define kSupportSite  @"SupportSite"
#define SiteNameKey   @"siteName"
#define SiteMainKey   @"siteMain"
#define SiteSearchKey @"siteSearch"
#define kCurrentSite  @"CurrentSite"
#define SiteResponseType @"SiteResponseType"
#define kMainViewRowStyle @"MainViewRowStyle"

#define kFetchInterval            @"FetchInterval"
#define kFetchIntervalMinimum     30                  //5 minutes
#define kFetchIntervalMaximun     43200               //12 hours

#define kFileWatchInterval        @"FileWatchInterval"
#define kFileWatchIntervalMinimum 60                  //1 minutes
#define kFileWatchIntervalMaximum 43200

#define DMHYThemeChangedNotification                 @"DMHYThemeChangedNotification"
#define DMHYSavePathChangedNotification              @"DMHYSavaPathChangedNotification"
#define DMHYFileWatchPathChangedNotification @"DMHYFileWatchPathChangedNotification"
#define DMHYDatabaseChangedNotification              @"DMHYDatabaseChangedNotification"
#define DMHYDownloadLinkTypeNotification             @"DMHYDownloadLinkTypeNotification"
#define DMHYDownloadSiteChangedNotification          @"DMHYDownloadSiteChangedNotification"
#define DMHYSearsonKeywordAddedNotification          @"DMHYSearsonKeywordAddedNotification"
#define DMHYDoubleActionChangedNotification          @"DMHYDoubleActionChangedNotification"
#define DMHYSelectKeywordChangedNotification         @"DMHYSelectKeywordChangedNotification"
#define DMHYFetchIntervalChangedNotification         @"DMHYFetchIntervalChangedNotification"
#define DMHYInitialWeekdayCompleteNotification       @"DMHYInitialWeekdayCompleteNotification"
#define DMHYDefaultSitesSetupComplatedNotification   @"DMHYDefaultSitesSetupComplatedNotification"
#define DMHYMainTableViewRowStyleChangedNotification @"DMHYMainTableViewRowStyleChangedNotification"
#define DMHYFileWatchIntervalChangedNotification @"DMHYFileWatchIntervalChangedNotification"

#define DMHYKeywordEntityKey @"Keyword"
#define DMHYTorrentEntityKey @"Torrent"

#define DMHYThemeKey @"ThemeType"

// bgmlist entity key
#define BangumiTitleCNKey     @"titleCN"
#define BangumiTitleJPKey     @"titleJP"
#define BangumiTitleENKey     @"titleEN"

#define BangumiWeekDayJPKey   @"weekDayJP"
#define BangumiWeekDayCNKey   @"weekDayCN"

#define BangumiTimeJPKey      @"timeJP"
#define BangumiTimeCNKey      @"timeCN"

#define BangumiNewBGMKey      @"newBgm" // 这个可以来做［只添加当季度新番］

#define BangumiShowDateKey    @"showDate"
#define BangumiOfficalSiteKey @"officalSite"
/*********************************************
 * bgmlist example bangumi
 *********************************************
 "1601_21": {
 "titleCN": "红壳的潘多拉",
 "titleJP": "紅殻のパンドラ",
 "titleEN": "",
 "officalSite": "http://k-pandora.com/",
 "weekDayJP": 5,
 "weekDayCN": 6,
 "timeJP": "2200",
 "timeCN": "0040",
 "onAirSite": [
 "http://www.bilibili.com/bangumi/i/3114/"
 ],
 "newBgm": true,
 "showDate": "2016-01-08",
 "bgmId": 159269
 }
 */
//#define BangumiDownloadKeywordKey @"downloadKeyword" 并没有卯月还要根据字幕组更新速度自己筛选 poi

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

#import "DMHYTool.h"
#import "DMHYNotification.h"
#import "DMHYDownloader.h"

#endif /* DMHYAPI_h */
