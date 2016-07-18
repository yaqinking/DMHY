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
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

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

- (void)fetchFromSite:(DMHYSite *)site queryKeyword:(DMHYKeyword *)keyword fetchedNew:(DMHYXMLDataFetchedNewTorrentBlock)block completion:(DMHYXMLDataFetchCompletionBlock)completionHandler failure:(DMHYXMLDataFetchFailureBlock)failureHandler {
    NSString *url = [[NSString stringWithFormat:site.searchURL, keyword.keyword] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"AutoDL URL %@", url);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFXMLDocumentResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = self.accepableContentTypes;
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        ONOXMLDocument *xmlDoc = [ONOXMLDocument XMLDocumentWithString:[responseObject description] encoding:NSUTF8StringEncoding error:nil];
        [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            NSString *title                     = [[element firstChildWithTag:@"title"] stringValue];
            /*
            if (self.dontDownloadCollection) {
                if ([title containsString:@"合集"] ||
                    [title containsString:@"全集"]) {
                    return;
                }
            }
            NSString *fliter = [[NSUserDefaults standardUserDefaults] stringForKey:FliterKeywordKey];
            
            if (![fliter isEqualToString:@""] && (fliter.length != 0)) {
                __block NSMutableString *containFliterResult = [NSMutableString new];
                NSArray *flites = [fliter componentsSeparatedByString:@" "];
                [flites enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([title containsString:obj]) {
                        [containFliterResult appendString:@"1"];
                    } else {
                        [containFliterResult appendString:@"0"];
                    }
                }];
                if ([containFliterResult containsString:@"0"]) {
                    return ;
                }
            }
            */
            NSFetchRequest *requestExistTorrent = [NSFetchRequest fetchRequestWithEntityName:@"Torrent"];
            requestExistTorrent.predicate       = [NSPredicate predicateWithFormat:@"keyword == %@ AND title == %@",keyword ,title];
            NSArray *existsTorrents = [self.managedObjectContext executeFetchRequest:requestExistTorrent
                                                                               error:NULL];
            if (!existsTorrents.count) {
//                NSLog(@"Didn't exist %@",title);
                DMHYTorrent *item = [NSEntityDescription insertNewObjectForEntityForName:@"Torrent"
                                                                  inManagedObjectContext:self.managedObjectContext];
                NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
                item.pubDate = [[DMHYTool tool] formatedDateFromDMHYDateString:dateString];
                item.title = [[element firstChildWithTag:@"title"] stringValue];
                item.link = [[element firstChildWithTag:@"link"] stringValue];
                item.author = [[element firstChildWithTag:@"author"] stringValue];
                NSString *magnetXPath = [NSString stringWithFormat:@"//item[%lu]//enclosure/@url", (idx+1)];
                NSString *magStr     = [[element firstChildWithXPath:magnetXPath] stringValue];
                item.magnet = magStr;
                item.isNewTorrent = @YES;
                item.isDownloaded = @NO;
                item.keyword = keyword;
//                NSLog(@"[New %@]",item.title);
                block(item);
            } else {
//                NSLog(@"Exist %@", title);
                *stop = 1;
            }
        }];
//        NSLog(@"XML Document Enumerate Completed inform completion block");
        completionHandler();
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureHandler(error);
    }];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = [[DMHYCoreDataStackManager sharedManager] managedObjectContext];
    }
    return _managedObjectContext;
}

- (NSSet *)accepableContentTypes {
    if (!_accepableContentTypes) {
        _accepableContentTypes = [NSSet setWithObjects:@"application/rss+xml",@"text/xml",@"application/xml", nil];
    }
    return _accepableContentTypes;
}

@end
