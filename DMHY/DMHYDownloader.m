//
//  DMHYDownloader.m
//  DMHY
//
//  Created by 小笠原やきん on 3/24/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYDownloader.h"

@interface DMHYDownloader()

@property (nonatomic, strong) AFURLSessionManager *manager;

@end

@implementation DMHYDownloader

+ (DMHYDownloader *)downloader {
    static DMHYDownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[DMHYDownloader alloc] init];
    });
    return downloader;
}

- (void)downloadTorrentWithURL:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request
                                                                          progress:nil
                                                                       destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                            NSURL *savePath = [PreferenceController preferenceSavePath];
                                                                           return [savePath URLByAppendingPathComponent:[response suggestedFilename]];
                                                                           
                                                                       } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nonnull filePath, NSError * _Nonnull error) {
                                                                           //NSLog(@"Download to : %@",filePath);
                                                                           NSString *fileName = [response suggestedFilename];
                                                                           [self postUserNotificationWithFileName:fileName];
                                                                           
                                                                       }];
    [downloadTask resume];
}

#pragma mark - LocalNotification

- (void)postUserNotificationWithFileName:(NSString *)fileName {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"下载完成";
    notification.informativeText = fileName;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (AFURLSessionManager *)manager {
    if (!_manager) {
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        _manager                        = [[AFURLSessionManager alloc] initWithSessionConfiguration:conf];
    }
    return _manager;
}

@end
