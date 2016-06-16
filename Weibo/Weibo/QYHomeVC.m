//
//  QYHomeVC.m
//  Weibo
//
//  Created by qingyun on 16/5/14.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import "QYHomeVC.h"
#import "QYStatus.h"
#import "QYStatusCell.h"
#import "QYStatusFooterView.h"
#import "QYDetailStatusVC.h"
#import "Common.h"
#import "QYAccessToken.h"

@interface QYHomeVC ()
@property (nonatomic, strong) NSArray *statusArray;
@end

@implementation QYHomeVC
static NSString *cellIdentifier = @"statusCell";
static NSString *footerIdentifier = @"statusFooter";
//懒加载微博首页数据
-(NSArray *)statusArray{
    if (_statusArray == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"temp" ofType:@"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        
        NSArray *statusArr = dict[@"statuses"];
        NSMutableArray *models = [NSMutableArray array];
        for (NSDictionary *statusDict in statusArr) {
            QYStatus *status = [QYStatus statusWithDictionary:statusDict];
            [models addObject:status];
        }
        _statusArray = models;
    }
    return _statusArray;
}

//网络请求数据
-(void)requestHomeList{
#if 0
    //1.创建url
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?access_token=%@",BASEURL,GETHOMELISTPATH,[QYAccessToken shareHandel].access_token]];//URLString在？后面的内容必须使用字典的表示方法即“key=%@&key=%@”
    //2.请求数据
    NSURLSession *session = [NSURLSession sharedSession];
    __weak QYHomeVC *weakSelf = self;
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //2.1判断请求成功
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            //2.2data 转换成字典 JSON解析
            //解析数据，获取AccessToken
            NSLog(@"==%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            //将JSONdata转换成字典
            NSDictionary *pras = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            //字典转模型
            if (pras) {
                //2.3字典转mode
                NSArray *statusArr = pras[@"statuses"];
                NSMutableArray *models = [NSMutableArray array];
                for (NSDictionary *statusDict in statusArr) {
                    QYStatus *status = [QYStatus statusWithDictionary:statusDict];
                    [models addObject:status];
                }
                weakSelf.statusArray = models;
                //2.4刷新UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                });
            }
        }
    }];
    //3.启动
    [task resume];
#else
    //1.创建Manager对象
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //2.设置参数
    NSDictionary *pars = @{@"access_token":[QYAccessToken shareHandel].access_token};
    //3.POST请求
    __weak QYHomeVC *weakSelf = self;
    [manager GET:[BASEURL stringByAppendingPathComponent:GETHOMELISTPATH] parameters:pars progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 200) {
//            NSLog(@"responseObject = %@",responseObject);
            //2.3字典转mode
            NSArray *statusArr = responseObject[@"statuses"];
            NSMutableArray *models = [NSMutableArray array];
            for (NSDictionary *statusDict in statusArr) {
                QYStatus *status = [QYStatus statusWithDictionary:statusDict];
                [models addObject:status];
            }
            weakSelf.statusArray = models;
            //2.4刷新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error = %@",error);
    }];
#endif
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //判断授权码accesstoken
    if ([QYAccessToken shareHandel].access_token) {
        //网络请求数据
        [self requestHomeList];
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //注册单元格
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([QYStatusCell class]) bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    //注册sectionFooterView
    [self.tableView registerClass:[QYStatusFooterView class] forHeaderFooterViewReuseIdentifier:footerIdentifier];
    
    //设置tableView的预估高度
    self.tableView.estimatedRowHeight = 120;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.statusArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QYStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //获取当前section的模型
    QYStatus *cellStatus = self.statusArray[indexPath.section];
    cell.statusModel = cellStatus;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0.1;
    }else{
        return 10;
    }
}

//设置sectionFooterView的高度
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 30;
}

//设置sectionFooterView
-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    QYStatusFooterView *footerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:footerIdentifier];
    
    //获取当前section的模型
    QYStatus *status = self.statusArray[section];
    footerView.footerStatus = status;
    
    return footerView;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //获取详情视图控制器
    QYDetailStatusVC *detailStatusVC = [self.storyboard instantiateViewControllerWithIdentifier:@"detailVC"];
    QYStatus *selectedStatus = self.statusArray[indexPath.section];
    detailStatusVC.cellStatus = selectedStatus;

    [self.navigationController pushViewController:detailStatusVC animated:YES];
}

@end
