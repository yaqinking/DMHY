//
//  TorrentItem.h
//  DMHY
//
//  Created by 小笠原やきん on 15/8/31.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TorrentItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL    *link;
@property (nonatomic, strong) NSString   *pubDate;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *category;

@end
