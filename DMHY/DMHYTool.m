//
//  DMHYTool.m
//  DMHY
//
//  Created by 小笠原やきん on 16/1/21.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "DMHYTool.h"

@interface DMHYTool ()

@property (nonatomic, strong) NSDateFormatter *dateFormater;

@end

@implementation DMHYTool

+ (DMHYTool *)tool {
    static DMHYTool *tool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[DMHYTool alloc] init];
    });
    return tool;
}

+ (NSString *) cn_weekdayFromWeekdayCode:(NSInteger )weekday {
    switch (weekday) {
        case 1:
            return @"周日";
        case 2:
            return @"周一";
        case 3:
            return @"周二";
        case 4:
            return @"周三";
        case 5:
            return @"周四";
        case 6:
            return @"周五";
        case 7:
            return @"周六";
        // for bgmlist 6 代表周六 但 JP 上映时间是 晚上 0000 之前的话，CN 则是 周日，然后取出值之后 ＋2 则是通用从 bgmlist 周几转到 dmhy 周几的 code。所以周六 bgmlist code 6 而 ＋2 之后是 8 但是是周日中国上映，8 在 KeywordViewController 里的bgmlist weekdaycode 中代表是 周日。
        case 8:
            return @"周日";
        // for yesterday and day before yesterday 1-1=0 1-2=-1 2-2=0;
        case 0:
            return @"周六";
        case -1:
            return @"周五";
        default:
            break;
    }
    return @"";
}

+ (NSURL *)convertToURLWithURLString:(NSString *)urlString {
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *escapedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:set];
    return [NSURL URLWithString:escapedString];
}

+ (NSString *)bangumiSeasonOfMonth:(NSInteger )month {
    switch (month) {
        case 1:
        case 2:
        case 3:
            return @"01";
        case 4:
        case 5:
        case 6:
            return @"04";
        case 7:
        case 8:
        case 9:
            return @"07";
        case 10:
        case 11:
        case 12:
            return @"10";
        default:
            break;
    }
    return @"";
}

- (NSString *)formatedDateStringFromDMHYDateString:(NSString *)dateString {
    //    NSLog(@"dateFormater %@",self.dateFormater);
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate             = [self.dateFormater dateFromString:dateString];
    self.dateFormater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:longDate];
    
}

- (NSDate *)formatedDateFromDMHYDateString:(NSString *)dateString {
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate             = [self.dateFormater dateFromString:dateString];
    return longDate;
}

- (NSString *)stringFromSavedDate:(NSDate *)date {
    self.dateFormater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:date];
}

- (NSString *)infoDateStringFromDate:(NSDate *)date {
    self.dateFormater.dateFormat = @"MM月dd日 HH:mm:ss";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:date];
}

- (NSDateFormatter *)dateFormater {
    if (!_dateFormater) {
        _dateFormater = [[NSDateFormatter alloc] init];
    }
    return _dateFormater;
}

@end
