//
//  LoginVC.m
//  Weibo
//
//  Created by qingyun on 16/6/6.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import "LoginVC.h"
#import "Common.h"
#import "QYAccessToken.h"

static NSString *APPKEY = @"3677849117";
static NSString *DIRPATH = @"http://www.hnqingyun.com";
static NSString *APPSECRET = @"f35f4b244082ef07e4c33edb92d8da79";

@interface LoginVC ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *myWeb;

@end

@implementation LoginVC
//请求用户授权Token
-(void)getUserTempToken{
#if 1
    //1.合并URL路径
    NSURL *url = [NSURL URLWithString:[BASEURL stringByAppendingPathComponent:AUTHORIZEPATH]];
    //2.设置请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    //设置body    http    默认多个参数用&符号连接
    request.HTTPBody = [[NSString stringWithFormat:@"client_id=%@&redirect_uri=%@",APPKEY,DIRPATH] dataUsingEncoding:NSUTF8StringEncoding];
    //webView请求
    [_myWeb loadRequest:request];
#else
#endif
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    //获取URL
    NSURL *url=[request URL];
    //转换成string
    NSString*strUrl=[url absoluteString];
    //判断回调地址是否以回调地址开头http://www.hnqingyun.co如果是,从链接地址获取code的值 code主要用于获取access_token
    if([strUrl hasPrefix:DIRPATH]){
        //http://www.hnqingyun.com/?code=0b8783f611bb06b9958f1f7198449235
        //该方法是以"="为分割点,截取字符串,最终放在数组里
        NSArray *arr=[strUrl componentsSeparatedByString:@"="];
        NSString *code=[arr lastObject];
//        NSLog(@"======%@",code);
        //code获取完毕后,请求换取Acces_token
        [self getAccessToken:code];
        return NO;
    }
    return YES;
}

-(void)getAccessToken:(NSString *)code{
#if 0
    //1.URL封装
    NSURL *url = [NSURL URLWithString:[BASEURL stringByAppendingPathComponent:GETACCESSTOKENPATH]];
    //2.设置请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //请求参数
    /**
                    必选	类型及范围       说明
     client_id      true        string      申请应用时分配的AppKey。
     client_secret	true        string	申请应用时分配的AppSecret。
     grant_type     true        string	请求的类型，填写authorization_code
                grant_type为authorization_code时
                必选	类型及范围	说明
     code       true        string	调用authorize获得的code值。
     redirect_uri	true        string	回调地址，需需与注册应用里的回调地址一致。
     */
    request.HTTPBody = [[NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=authorization_code&code=%@&redirect_uri=%@",APPKEY,APPSECRET,code,DIRPATH] dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session = [NSURLSession sharedSession];
    //task
    __weak LoginVC *weakSelf = self;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"===%@",error);
        }
        //判断请求状态
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            //解析数据，获取AccessToken
            NSLog(@"==%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            //将JSONdata转换成字典
            NSDictionary *pras = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            //字典转模型
            //获取单例对象
            QYAccessToken *token = [QYAccessToken shareHandel];
            //用kvc进行赋值操作
            [token setValuesForKeysWithDictionary:pras];
            //出栈回到上一个页面
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
        }
    }];
    //启动请求
    [task resume];
#else
    //1.创建Manager对象
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //2.设置参数
    NSDictionary *pars = @{@"client_id":APPKEY,@"client_secret":APPSECRET,@"grant_type":@"authorization_code",@"code":code,@"redirect_uri":DIRPATH};
    //2.1设置响应接收类型
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    //3.POST请求
    __weak LoginVC *weakSelf = self;
    [manager POST:[BASEURL stringByAppendingPathComponent:GETACCESSTOKENPATH] parameters:pars progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //3.1请求成功处理
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 200) {
//            NSLog(@"response = %@",responseObject);
            //3.2字典数据转mode
            QYAccessToken *token = [QYAccessToken shareHandel];
            [token setValuesForKeysWithDictionary:responseObject];
            //3.3返回主页面
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error = %@",error);
    }];
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getUserTempToken];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
