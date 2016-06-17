//
//  DMHYJSONManager.m
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYJSONDataManager.h"
#import "AFNetworking.h"
#import "TorrentItem.h"

NSString * const DMHYBangumiMoeOpenTorrentPagePrefixFormat = @"https://bangumi.moe/torrent/%@";
NSString * const publishTimeKey                            = @"publish_time";
NSString * const idKey                                     = @"_id";
NSString * const teamNameKeyPath                           = @"team.name";
NSString * const uploaderUserNameKeyPath                   = @"uploader.username";
NSString * const magnetKey                                 = @"magnet";

@interface DMHYJSONDataManager()

@property (nonatomic, strong) AFHTTPSessionManager *httpManager;

@end

@implementation DMHYJSONDataManager

+ (DMHYJSONDataManager *)manager {
    static DMHYJSONDataManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[DMHYJSONDataManager alloc] init];
    });
    return sharedManager;

}

- (void)GET:(NSString *)urlString success:(DMHYJSONDataFetchSuccessBlock)successBlock failure:(DMHYJSONDataFetchFailureBlock)failureBlock {
    [self.httpManager GET:urlString
               parameters:nil progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                      NSArray *torrentsArray = [responseObject valueForKey:@"torrents"];
                      NSMutableArray *data = [NSMutableArray new];
                      for (NSDictionary *element in torrentsArray) {
                          TorrentItem *item = [[TorrentItem alloc] init];
                          NSString *pubDate = element[publishTimeKey];
                          NSString *link = element[idKey];
                          NSString *team_name = [element valueForKeyPath:teamNameKeyPath];
                          if (!team_name) {
                              team_name = [element valueForKeyPath:uploaderUserNameKeyPath];
                          }
                          item.title   = element[@"title"];
                          item.magnet  = [NSURL URLWithString:element[magnetKey]];
                          item.link    = [NSURL URLWithString:[NSString stringWithFormat:DMHYBangumiMoeOpenTorrentPagePrefixFormat,link]]; //如果返回的 URL 里没有前缀的话，在这里也要处理
                          item.pubDate = pubDate;
                          item.author  = team_name;
                          [data addObject:item];
                      }
                      successBlock(data);
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
                      NSLog(@"Error %@",[error localizedDescription]);
                      NSNumber *statusCode = [NSNumber numberWithInteger:httpResponse.statusCode];
                      failureBlock(error);
                  }];
}

- (AFHTTPSessionManager *)httpManager {
    if (!_httpManager) {
        _httpManager = [AFHTTPSessionManager manager];
        _httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return _httpManager;
}

@end
