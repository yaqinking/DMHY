//
//  DMHYSiteChecker.h
//  DMHY
//
//  Created by 小笠原やきん on 7/16/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  检查站点数据是否有更新
 */
@interface DMHYSiteChecker : NSObject

- (void)invalidateTimer;
- (void)startWitchCheckInterval:(NSTimeInterval )checkInterval;
- (void)automaticDownloadTorrent;

@end
