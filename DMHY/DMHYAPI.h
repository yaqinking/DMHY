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

// bgmlist GitHub raw json file
#define BGMListYearSeasonFormat @"https://raw.githubusercontent.com/wxt2005/bangumi-list/master/json/bangumi-%@%@.json"

#define kXPathTorrentItem @"//item"
#define kDownloadLinkType @"DownloadLinkType"
#define kDownloadSite     @"DownloadSite"
#define kSavePath         @"SavePath"
#define kSelectKeyword    @"SelectKeyword"
#define kFetchInterval    @"FetchInterval"
#define kSelectKeywordIsSubKeyword @"SelectKeywordIsSubKeyword"
#define kWeekdayOther    @"其他"
#define kFetchIntervalMinimum 30   //5 minutes
#define kFetchIntervalMaximun 43200 //12 hours

#define DMHYDownloadLinkTypeNotification       @"DMHYDownloadLinkTypeNotification"
#define DMHYSavePathChangedNotification        @"DMHYSavaPathChangedNotification"
#define DMHYSelectKeywordChangedNotification   @"DMHYSelectKeywordChangedNotification"
#define DMHYInitialWeekdayCompleteNotification @"DMHYInitialWeekdayCompleteNotification"
#define DMHYFetchIntervalChangedNotification   @"DMHYFetchIntervalChangedNotification"
#define DMHYThemeChangedNotification           @"DMHYThemeChangedNotification"
#define DMHYDownloadSiteChangedNotification    @"DMHYDownloadSiteChangedNotification"
#define DMHYSearsonKeywordAddedNotification    @"DMHYSearsonKeywordAddedNotification"
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

#endif /* DMHYAPI_h */
