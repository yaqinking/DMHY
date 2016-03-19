//
//  Bangumi.h
//  DMHY
//
//  Created by 小笠原やきん on 3/20/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Bangumi : NSObject

@property (nonatomic, strong) NSString *titleCN;
@property (nonatomic, strong) NSString *titleCNFull;
@property (nonatomic, strong) NSString *titleJP;
@property (nonatomic, strong) NSString *titleEN;
@property (nonatomic, strong) NSString *weekDayJP;
@property (nonatomic, strong) NSString *weekDayCN;
@property (nonatomic, strong) NSString *timeJP;
@property (nonatomic, strong) NSString *timeCN;
@property (nonatomic, strong) NSString *showDate;
@property (nonatomic, strong) NSString *officalSite;
@property (nonatomic, strong) NSString *subGroup;

@property (nonatomic, assign, getter=isNewBgm) BOOL newBgm;

@end
