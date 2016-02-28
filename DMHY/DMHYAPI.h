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
#define DMHYRSS             @"https://share.dmhy.org/topics/rss/rss.xml"
#define DMHYSearchByKeyword @"https://share.dmhy.org/topics/rss/rss.xml?keyword=%@"

#define kXpathTorrentDownloadShortURL @"//div[@class='dis ui-tabs-panel ui-widget-content ui-corner-bottom']/a/@href"
#define kTest @"//div[@class='dis']//p//a//@href"
#define DMHYURLPrefixFormat          @"https:%@"

#define kXPathTorrentItem @"//item"
#define kDownloadLinkType @"DownloadLinkType"
#define kSavePath         @"SavePath"
#define kSelectKeyword    @"SelectKeyword"
#define kFetchInterval    @"FetchInterval"
#define kSelectKeywordIsSubKeyword @"SelectKeywordIsSubKeyword"
#define kFetchIntervalMinimum 300   //5 minutes
#define kFetchIntervalMaximun 43200 //12 hours
#define DMHYDownloadLinkTypeNotification       @"DMHYDownloadLinkTypeNotification"
#define DMHYSavePathChangedNotification        @"DMHYSavaPathChangedNotification"
#define DMHYSelectKeywordChangedNotification   @"DMHYSelectKeywordChangedNotification"
#define DMHYInitialWeekdayCompleteNotification @"DMHYInitialWeekdayCompleteNotification"
#define DMHYFetchIntervalChangedNotification   @"DMHYFetchIntervalChangedNotification"

#define DMHYKeywordEntityKey @"Keyword"
#define DMHYTorrentEntityKey @"Torrent"

#endif /* DMHYAPI_h */
