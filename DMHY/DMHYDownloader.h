//
//  DMHYDownloader.h
//  DMHY
//
//  Created by 小笠原やきん on 3/24/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMHYAPI.h"
#import "DMHYNotification.h"
#import "AFNetworking.h"
#import "PreferenceController.h"
#import "Ono.h"

/**
 *  下载给定链接的种子
 */
@interface DMHYDownloader : NSObject

+ (DMHYDownloader *)downloader;

/**
 * Download torrent with given url and push a local notification to notify use downloaded
 *
 *  @param url Download file url
 */
- (void)downloadTorrentWithURL:(NSURL *)url;
/**
 *  Download torrent from share.dmhy.org torrent description page
 *  1. Exract torrent download url
 *  @param url dmhy bangumi description page
 */
- (void)downloadTorrentFromPageURLString:(NSString *)urlString;

- (void)downloadTorrentFromPageURLString:(NSString *)urlString willStartBlock:(void(^)()) startBlock success:(void(^)()) successHandler failure:(void(^)(NSError *error)) failureHandler;

@end
