//
//  DMHYXMLDataManager.m
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYXMLDataManager.h"
#import "AFNetworking.h"
#import "AFOnoResponseSerializer.h"
#import "Ono.h"
#import "TorrentItem.h"
#import "DMHYTool.h"
#import "DMHYNotification.h"
#import "PreferenceController.h"

NSString * const DMHYXMLDataLoadCompletedNotification = @"DMHYXMLDataLoadCompletedNotification";
NSString * const DMHYXMLDataLoadErrorNotification = @"DMHYXMLDataLoadErrorNotification";

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

- (void)GET:(NSString *)urlString fromSite:(NSString *)siteName {
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"url -> %@",url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    op.responseSerializer.acceptableContentTypes = self.accepableContentTypes;
    
    __block NSMutableArray *torrents = [NSMutableArray new];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
        
        [xmlDoc enumerateElementsWithXPath:kXPathItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            TorrentItem *item = [[TorrentItem alloc] init];
            NSString *dateString = [[element firstChildWithTag:pubDateKey] stringValue];
            item.pubDate         = [[DMHYTool tool] formatedDateStringFromDMHYDateString:dateString];
            item.title           = [[element firstChildWithTag:titleKey] stringValue];
            item.link            = [NSURL URLWithString:[[element firstChildWithTag:linkKey] stringValue]];
            NSString *author = [[element firstChildWithTag:authorKey] stringValue];
            item.author          = author == nil ? @"" : author;
            NSString *magnetXPath = [NSString stringWithFormat:@"//item[%lu]//enclosure/@url", (idx+1)];
            NSString *magStr     = [[element firstChildWithXPath:magnetXPath] stringValue];
            item.magnet          = [NSURL URLWithString:magStr];
            [torrents addObject:item];
        }];
        [DMHYNotification postNotificationName:DMHYXMLDataLoadCompletedNotification object:torrents];
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        
        NSLog(@"Error %@",[error localizedDescription]);
        NSString *acceptableContentTypeError = [error localizedDescription];
        if ([acceptableContentTypeError containsString:@"application/rss+xml"]) {
            self.accepableContentTypes = [NSSet setWithObject:@"application/rss+xml"];
        }
        if ([acceptableContentTypeError containsString:@"text/xml"]) {
           self.accepableContentTypes = [NSSet setWithObject:@"text/xml"];
        }
        NSNumber *statusCode = [NSNumber numberWithInteger:operation.response.statusCode];
        [DMHYNotification postNotificationName:DMHYXMLDataLoadErrorNotification object:statusCode];
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}

@end
