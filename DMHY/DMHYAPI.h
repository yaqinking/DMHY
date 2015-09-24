//
//  DMHYAPI.h
//  DMHY
//
//  Created by 小笠原やきん on 15/8/31.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#ifndef DMHYAPI_h
#define DMHYAPI_h

#define DMHYRSS             @"https://share.dmhy.org/topics/rss/rss.xml"
#define DMHYSearchByKeyword @"https://share.dmhy.org/topics/rss/rss.xml?keyword=%@"

#define kXpathTorrentDownloadShortURL @"//div[@class='dis ui-tabs-panel ui-widget-content ui-corner-bottom']/a/@href"
#define kTest @"//div[@class='dis']//p//a//@href"
#define DMHYURLPrefixFormat          @"https:%@"

#define kXPathTorrentItem @"//item"
#define kDownloadLinkType @"DownloadLinkType"
#define kSavePath         @"SavePath"
#define kSelectKeyword    @"SelectKeyword"

#define kSelectKeywordIsSubKeyword @"SelectKeywordIsSubKeyword"

#define DMHYDownloadLinkTypeNotification       @"DMHYDownloadLinkTypeNotification"
#define DMHYSavePathChangedNotification        @"DMHYSavaPathChangedNotification"
#define DMHYSelectKeywordChangedNotification   @"DMHYSelectKeywordChangedNotification"
#define DMHYInitialWeekdayCompleteNotification @"DMHYInitialWeekdayCompleteNotification"

#define DMHYKeywordEntityKey @"Keyword"

#endif /* DMHYAPI_h */
