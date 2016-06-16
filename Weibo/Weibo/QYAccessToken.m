//
//  QYAccessToken.m
//  Weibo
//
//  Created by qingyun on 16/6/7.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import "QYAccessToken.h"
//声明一个静态变量
static QYAccessToken *accessToken;

@implementation QYAccessToken

+(instancetype)shareHandel{
    //判断accessToken是否为nil
    if (!accessToken) {
        //初始化accessToken
        accessToken = [[QYAccessToken alloc] init];
    }
    return accessToken;
}
@end
