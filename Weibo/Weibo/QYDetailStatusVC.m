//
//  QYDetailStatusVC.m
//  Weibo
//
//  Created by qingyun on 16/5/28.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import "QYDetailStatusVC.h"
#import "QYStatusCell.h"
#import "QYDetailSectionHeaderView.h"
#import "QYCommentCell.h"
#import "QYComment.h"
#import "AFNetworking.h"
#import "QYAccessToken.h"
#import "Common.h"
#import "QYStatus.h"

@interface QYDetailStatusVC ()

@property (nonatomic, strong) NSArray *commentArray;    //评论array
@property (nonatomic, strong) NSArray *otherArray;     //其他(转发/赞)

@property (nonatomic, strong) NSArray *showDatas;       //第一个section显示的数据

@property (nonatomic)         NSInteger selectedIndexOfSectionBtns;    //保存当前sectionHeaderView选中的btn的tag值
@end

@implementation QYDetailStatusVC
static NSString *statusCellIdentifier = @"statusCell";
static NSString *headerIdentifier = @"headerView";
static NSString *commentCellIdentifier = @"commentCell";
//懒加载commentArray
-(NSArray *)commentArray{
    if (_commentArray == nil) {
        if ([QYAccessToken shareHandel].access_token) {
            //网络请求数据
            [self requestHomeList];
        }else{
            NSString *path = [[NSBundle mainBundle] pathForResource:@"comments" ofType:@"plist"];
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
            
            NSArray *comments = dict[@"comments"];
            
            NSMutableArray *models = [NSMutableArray array];
            for (NSDictionary *commentDict in comments) {
                QYComment *comment = [QYComment commentWithDictionary:commentDict];
                [models addObject:comment];
            }
            _commentArray = models;
        }
    }
    return _commentArray;
}

-(NSArray *)otherArray{
    if (_otherArray == nil) {
        _otherArray = @[];
    }
    return _otherArray;
}

//获取评论的网络列表
-(void)requestHomeList{
    //网络请求数据
    //1.创建Manager对象
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //2.设置参数
    NSDictionary *pars = @{@"access_token":[QYAccessToken shareHandel].access_token,@"id":self.cellStatus.idstr};
    //3.POST请求
    __weak QYDetailStatusVC *weakSelf = self;
    [manager GET:[BASEURL stringByAppendingPathComponent:GETCOMMENTS] parameters:pars progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode == 200) {
            //            NSLog(@"responseObject = %@",responseObject);
            //2.3字典转mode
            NSArray *statusArr = responseObject[@"comments"];
            NSMutableArray *models = [NSMutableArray array];
            for (NSDictionary *statusDict in statusArr) {
                QYComment *status = [QYComment commentWithDictionary:statusDict];
                [models addObject:status];
            }
            weakSelf.commentArray = models;
            //2.4刷新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error = %@",error);
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //判断授权码accesstoken
    if ([QYAccessToken shareHandel].access_token) {
        //网络请求数据
        [self requestHomeList];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 120;
    
    //注册第0个section中的单元格
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([QYStatusCell class]) bundle:nil] forCellReuseIdentifier:statusCellIdentifier];
    
    //注册第一个section中的单元格
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([QYCommentCell class]) bundle:nil] forCellReuseIdentifier:commentCellIdentifier];
    
    self.showDatas = self.commentArray;
    self.selectedIndexOfSectionBtns = 102;
    
    [self addObserver:self forKeyPath:@"commentArray" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - 监听方法
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"commentArray"]) {
        self.showDatas = self.commentArray;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section ? self.showDatas.count : 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        QYStatusCell *statusCell = [tableView dequeueReusableCellWithIdentifier:statusCellIdentifier forIndexPath:indexPath];
        
        statusCell.statusModel = self.cellStatus;
        
        return statusCell;
    }else if (indexPath.section == 1){
        QYCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:commentCellIdentifier forIndexPath:indexPath];
        
        QYComment *comment = self.showDatas[indexPath.row];
        
        commentCell.commentModel = comment;
        
        return commentCell;
    }
    
    // Configure the cell...
    
    return nil;
}


//设置section的header的高度
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 1) {
        return 30.0;
    }
    return 0.1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 0) {
        return 10;
    }
    return 0.1;
}

//设置section的headerView
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (section == 0) {
        return nil;
    }
    //获取headerView
    QYDetailSectionHeaderView *headerView = [QYDetailSectionHeaderView sectionHeaderViewForTableView:tableView WithSelectedTag:self.selectedIndexOfSectionBtns];
    //设置headerStatus
    headerView.headerStatus = self.cellStatus;
    
    __weak QYDetailStatusVC *weakSelf = self;
    headerView.changedSelectedBtn = ^(NSInteger tag){
        [weakSelf changedUI:tag];
    };
    
    return headerView;
}

//更改UI界面
-(void)changedUI:(NSInteger)selectedTag{
    
    if (selectedTag == 101 || selectedTag == 103) {
        _showDatas = self.otherArray;
    }else if (selectedTag == 102){
        _showDatas = self.commentArray;
    }
    
    //刷新第一个section
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    
    self.selectedIndexOfSectionBtns = selectedTag;
    QYDetailSectionHeaderView *headerView = (QYDetailSectionHeaderView *)[self.tableView headerViewForSection:1];
    headerView.selectedTagOfBtns = selectedTag;
    
}

-(void)dealloc{
    [self removeObserver:self forKeyPath:@"commentArray"];
}
@end
