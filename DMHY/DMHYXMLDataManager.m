//
//  DMHYXMLDataManager.m
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYXMLDataManager.h"
#import "AFNetworking.h"
#import "Ono.h"
#import "TorrentItem.h"
#import "DMHYTool.h"

NSString * const pubDateKey           = @"pubDate";
NSString * const titleKey             = @"title";
NSString * const linkKey              = @"link";
NSString * const authorKey            = @"author";

NSString * const kXPathItem           = @"//item";

@interface DMHYXMLDataManager()

@property (nonatomic, strong) NSSet *accepableContentTypes;

@end

@implementation DMHYXMLDataManager

+ (DMHYXMLDataManager *)manager {
    static DMHYXMLDataManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[DMHYXMLDataManager alloc] init];
    });
    return sharedManager;
}
- (void)GET:(NSString *)urlString success:(DMHYXMLDataFetchSuccessBlock)successBlock failure:(DMHYXMLDataFetchFailureBlock)failureBlock {
    _successBlock = successBlock;
    _failureBlock = failureBlock;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFXMLDocumentResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = self.accepableContentTypes;
    __block NSMutableArray *torrents = [NSMutableArray new];
    
    [manager GET:urlString parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        ONOXMLDocument *xmlDoc = [ONOXMLDocument XMLDocumentWithString:[responseObject description] encoding:NSUTF8StringEncoding error:nil];
        [xmlDoc enumerateElementsWithXPath:kXPathItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            TorrentItem *item = [[TorrentItem alloc] init];
            NSString *dateString = [[element firstChildWithTag:pubDateKey] stringValue];
            NSString *pubDate = [[DMHYTool tool] formatedDateStringFromDMHYDateString:dateString];
            item.pubDate         = pubDate ? pubDate : @"";
            item.title           = [[element firstChildWithTag:titleKey] stringValue];
            item.link            = [NSURL URLWithString:[[element firstChildWithTag:linkKey] stringValue]];
            NSString *author = [[element firstChildWithTag:authorKey] stringValue];
            item.author          = author ? author : @"";
            NSString *magnetXPath = [NSString stringWithFormat:@"//item[%lu]//enclosure/@url", (idx+1)];
            NSString *magStr     = [[element firstChildWithXPath:magnetXPath] stringValue];
            item.magnet          = [NSURL URLWithString:magStr];
            [torrents addObject:item];
        }];
        _successBlock(torrents);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        _failureBlock(error);
    }];
}

- (NSSet *)accepableContentTypes {
    if (!_accepableContentTypes) {
        _accepableContentTypes = [NSSet setWithObjects:@"application/rss+xml",@"text/xml", nil];
    }
    return _accepableContentTypes;
}

@end
