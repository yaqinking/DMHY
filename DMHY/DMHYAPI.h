//
//  DMHYAPI.h
//  DMHY
//
//  Created by 小笠原やきん on 15/8/31.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#ifndef DMHYAPI_h
#define DMHYAPI_h

#define kXpathTorrentDownloadShortURL   @"//div[@class='dis ui-tabs-panel ui-widget-content ui-corner-bottom']/a/@href"
#define kXpathTorrentDirectDownloadLink @"//div[@class='dis']//p//a//@href"

#define kXPathTorrentItem @"//item"
#define kDownloadLinkType @"DownloadLinkType"
#define kDownloadSite     @"DownloadSite"
#define kSavePath         @"SavePath"
#define kFileWatchPath @"FileWatchPath"
#define kSelectKeyword    @"SelectKeyword"
#define kSelectKeywordIsSubKeyword @"SelectKeywordIsSubKeyword"
#define kWeekdayOther @"其他"
#define kMainViewRowStyle @"MainViewRowStyle"
#define kMainTableViewRowStyle @"MainTableViewRowStyle"
#define kDoubleAction @"DoubleAction"

#define DMHYMainTableViewRowStyleChangedNotification @"DMHYMainTableViewRowStyleChangedNotification"
#define DMHYDoubleActionChangedNotification @"DMHYDoubleActionChangedNotification"
#define kFetchInterval            @"FetchInterval"
#define kFetchIntervalMinimum     300                  //5 minutes
#define kFetchIntervalMaximun     43200               //12 hours

#define kFileWatchInterval        @"FileWatchInterval"
#define kFileWatchIntervalMinimum 60                  //1 minutes
#define kFileWatchIntervalMaximum 43200

#define DMHYThemeChangedNotification                 @"DMHYThemeChangedNotification"
#define DMHYSavePathChangedNotification              @"DMHYSavaPathChangedNotification"
#define DMHYFileWatchPathChangedNotification @"DMHYFileWatchPathChangedNotification"
#define DMHYDatabaseChangedNotification              @"DMHYDatabaseChangedNotification"
#define DMHYDownloadLinkTypeNotification             @"DMHYDownloadLinkTypeNotification"
#define DMHYAutoDownloadSiteChangedNotification      @"DMHYAutoDownloadSiteChangedNotification"
#define DMHYDoubleActionChangedNotification          @"DMHYDoubleActionChangedNotification"
#define DMHYSelectKeywordChangedNotification         @"DMHYSelectKeywordChangedNotification"
#define DMHYFetchIntervalChangedNotification         @"DMHYFetchIntervalChangedNotification"

#define DMHYMainTableViewRowStyleChangedNotification @"DMHYMainTableViewRowStyleChangedNotification"
#define DMHYFileWatchIntervalChangedNotification @"DMHYFileWatchIntervalChangedNotification"

#define DMHYThemeKey @"ThemeType"

typedef NS_ENUM(NSInteger, DMHYThemeType) {
    DMHYThemeLight,
    DMHYThemeDark
};

typedef NS_ENUM(NSInteger, DMHYSiteType) {
    DMHYSiteDefault,
    DMHYSiteDandanplay,
    DMHYSiteACGGG,
    DMHYSiteBangumiMoe
};

static NSString * const AppDomain = @"com.yaqinking.DMHY";

static NSString * const DMHYSiteEntityKey = @"Site";
static NSString * const DMHYKeywordEntityKey = @"Keyword";
static NSString * const DMHYTorrentEntityKey = @"Torrent";

static NSString * const DMHYSiteNameKey = @"site_name";
static NSString * const DMHYSiteMainURLKey = @"main_url";
static NSString * const DMHYSiteSearchURLKey = @"search_url";
static NSString * const DMHYSiteFliterKey = @"fliter_site";
static NSString * const DMHYSiteAutoDLKey = @"auto_download";
static NSString * const DMHYSiteDLTypeKey = @"download_type";
static NSString * const DMHYSiteDLFinKey = @"download_fin";
static NSString * const DMHYSiteResponseTypeKey = @"response_type";
static NSString * const DMHYSiteCurrentUseKey = @"current_use";
static NSString * const DMHYSiteKeywordsKey = @"keywords";

static NSString * const DMHYKeywordAddedNotification = @"moe.yaqinking.dmhy.added.keyword.notification";
static NSString * const DMHYSearchSiteChangedNotification = @"moe.yaqinking.dmhy.search.site.changed.notification";
static NSString * const DMHYSiteAddedNotification = @"moe.yaqinking.dmhy.site.added.notification";
static NSString * const DMHYKeywordCheckedNotification = @"moe.yaqinking.dmhy.keyword.checked.notification";

#import "DMHYTool.h"
#import "DMHYNotification.h"
#import "DMHYDownloader.h"

#endif /* DMHYAPI_h */
