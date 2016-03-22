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


@end
