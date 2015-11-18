//
//  YKSRecommenViewController.m
//  YKSDrugPushing
//
//  Created by TT on 15/10/25.
//  Copyright © 2015年 Saintly. All rights reserved.
//

#import "YKSRecommenViewController.h"
#import "YKSReleaseButtonCell.h"
#import "YKSAddressListViewController.h"
#import "YKSDetails.h"
#import "EachGroupDetail.h"
#import "YKSUserModel.h"
#import "YKSPlanCell.h"
#import "YKSAddAddressVC.h"
#import "YKSPlanDisPlayCell.h"
#import "GZBaseRequest.h"
#import "YKSFormViewCell.h"
#import "YKSOneBuyCell.h"
#import "YKSShoppingCartVC.h"
#import "YKSDrugDetailViewController.h"

@interface YKSRecommenViewController ()<YKSReleaseButtonCellDelegate,YKSOneBuyCellDelegate>
//判断展开状态
@property (nonatomic,strong) NSMutableArray *indexArray;
@property (assign, nonatomic) CGFloat totalPrice;


@end

@implementation YKSRecommenViewController

//表头数据
- (YKSFormInformation *)formInformation
{
    if (!_formInformation) {
        _formInformation = [[YKSFormInformation alloc] init];
        _formInformation.symptomName = @"症状名称:";
        _formInformation.symptomInformationName = @"临床症状:";
        _formInformation.doctorKeepPushingName = @"药师推荐药品:";
    }
    return _formInformation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置当前页面背景为白色
    self.view.backgroundColor = [UIColor whiteColor];
    //创建表头 在init方法赋值
    YKSFormViewCell *headerView = [[YKSFormViewCell alloc] initWithFormHeadFram:CGRectMake(0, 0, 320, 200) andSymptomName:self.formInformation.symptomName andSymptom:self.formInformation.symptom andSymptomInformationName:self.formInformation.symptomInformationName andSymptomInformation:self.formInformation.symptomInformation andDoctorKeepPushingName:self.formInformation.doctorKeepPushingName];
    //给表头赋值视图
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = [[UIView alloc]init];
    [self requestSubSpecialList];
    //设置记录变量初值
    self.indexArray = [NSMutableArray array];
}

//一键加入购物车 代理方法
- (void)addShopping:(UIButton *)addButton
{
    if (self.datas.count==0) {
        [self showToastMessage:@"没有商品可以加入购物车！！！"];
        return;
    }
    
    [self jumpAddCard];
    
}

- (void)jumpAddCard
{
    //这里已经加载网络.拉倒当前地址了
    NSDictionary *currentAddr = [UIViewController selectedAddressUnArchiver];
    
    
    //显示判断登陆没有,请登陆
    if (![YKSUserModel isLogin]) {
        [self showToastMessage:@"请登陆"];
        [YKSTools login:self];
        return;
    }
    
    //如果列表为空,什么地址都没有,去添加地址控制器
    if (!currentAddr[@"express_mobilephone"]) {
        //这里要默认点击那个地址button所以也要加记录
        //默认让点击这个地址列表
        [UIViewController selectedAddressButtonArchiver:1];
        self.tabBarController.selectedIndex = 0;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle:[NSBundle mainBundle]];
        YKSAddressListViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YKSAddressListViewController"];
        vc.callback = ^(NSDictionary *info){
            
            [YKSUserModel shareInstance].currentSelectAddress = info;
            
        };
        [self.navigationController pushViewController:vc animated:YES];
        
        // [self.navigationController popToRootViewControllerAnimated:NO];
        return;
    }
    
    //不支持配送
    if ([currentAddr[@"sendable"] integerValue] == 0) {
        [self showToastMessage:@"暂不支持配送您选择的区域，我们会尽快开通"];
        return;
    }
    
    //号码不为空,能送达
    if (currentAddr[@"express_mobilephone"] && ([currentAddr[@"sendable"] integerValue] != 0)) {
        
        if (![YKSUserModel shareInstance].addressLists) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                                 bundle:[NSBundle mainBundle]];
            YKSAddAddressVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"YKSAddAddressVC"];
            vc.callback = ^{
                [self showProgress];
                [GZBaseRequest addressListCallback:^(id responseObject, NSError *error) {
                    [self hideProgress];
                    if (error) {
                        [self showToastMessage:@"网络加载失败"];
                        return ;
                    }
                    if (ServerSuccess(responseObject)) {
//                        NSLog(@"responseObject = %@", responseObject);
                        NSDictionary *dic = responseObject[@"data"];
                        if ([dic isKindOfClass:[NSDictionary class]] && dic[@"addresslist"]) {
                            [YKSUserModel shareInstance].addressLists = _datas;
                        }
                    } else {
                        [self showToastMessage:responseObject[@"msg"]];
                    }
                }];
            };
            
            [self.navigationController pushViewController:vc animated:YES];
            return ;
        }
        
        
        if (![YKSUserModel shareInstance].currentSelectAddress) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main"
                                                                 bundle:[NSBundle mainBundle]];
            YKSAddressListViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"YKSAddressListViewController"];
            vc.callback = ^(NSDictionary *info){
                [YKSUserModel shareInstance].currentSelectAddress = info;
            };
            [self.navigationController pushViewController:vc animated:YES];
            return ;
        }
        
        
        [self showProgress];
        
        __block NSMutableArray *gcontrasts = [NSMutableArray new];
        __block NSMutableArray *gids = [NSMutableArray new];
        [_datas enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dic = @{@"gid": obj[@"gid"],
                                  @"gcount": @(1),
                                  @"gtag": obj[@"gtag"],
                                  @"banners": obj[@"banners"],
                                  @"gtitle": obj[@"gtitle"],
                                  @"gprice": obj[@"gprice"],
                                  @"gpricemart": obj[@"gpricemart"],
                                  @"glogo": obj[@"glogo"],
                                  @"gdec": obj[@"gdec"],
                                  @"purchase": obj[@"purchase"],
                                  @"gstandard": obj[@"gstandard"],
                                  @"vendor": obj[@"vendor"],
                                  @"iscollect": obj[@"iscollect"],
                                  @"gmanual": obj[@"gmanual"],
                                  @"name":obj[@"drugstore"][@"name"],
                                  @"id":obj[@"drugstore"][@"id"],
                                  @"address":obj[@"drugstore"][@"address"]
                                  };
            [gcontrasts addObject:dic];
            [gids addObject:obj[@"gid"]];
        }];

        [GZBaseRequest addToShoppingcartParams:gcontrasts
                                          gids:[gids componentsJoinedByString:@","]
                                      callback:^(id responseObject, NSError *error) {
                                          [self hideProgress];
                                          if (error) {
                                              [self showToastMessage:@"网络加载失败"];
                                              return ;
                                          }
                                          if (ServerSuccess(responseObject)) {
                                              [self showToastMessage:@"加入购物车成功"];
                                              UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                                              YKSShoppingCartVC *shopVC = [storyboard instantiateViewControllerWithIdentifier:@"YKSShoppingCartVC"];
                                              [self.navigationController pushViewController:shopVC animated:YES];
                                              
                                          } else {
                                              [self showToastMessage:responseObject[@"msg"]];
                                          }
                                      }];
        
    }
}



- (void)requestSubSpecialList {
  
        if (!self.specialId) {
            return ;
        }
        [self showProgress];
        [GZBaseRequest subSpecialDetailBy:self.specialId
                                 callback:^(id responseObject, NSError *error) {
                                     [self handleResult:responseObject error:error];
                                 }];
    }



- (void)handleResult:(id)responseObject error:(NSError *)error {
    [self hideProgress];
    if (error) {
        [self showToastMessage:@"网络加载失败"];
        return ;
    }
    if (ServerSuccess(responseObject)) {
        //获取服务器数据
        NSDictionary *dic = responseObject[@"data"];
        if ([dic isKindOfClass:[NSDictionary class]] && dic[@"glist"]) {
            _datas = responseObject[@"data"][@"glist"];
            
            NSArray *totalPrices = [_datas valueForKeyPath:@"gprice"];
            if (totalPrices) {
                _totalPrice = [[totalPrices valueForKeyPath:@"@sum.floatValue"] floatValue];
            }

        }
        [self.tableView reloadData];
    } else {
        [self showToastMessage:responseObject[@"msg"]];
    }
}





#pragma mark - Table view data source

//返回分区
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}
//返回row项
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    //当记录变量数据中 包含 当前点击的分区值 表示展开状态
    NSString *str = [NSString stringWithFormat:@"%ld",section];
    if ([self.indexArray containsObject:str]){
        return self.datas.count;
    }
    //未点击按钮返回1个cell
    return 1;
}
//设置分区头的高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
//设置单元格cell的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}
//设置分区尾的高度
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //当记录数组中 包含 当前点击的分区 表示展开状态
    NSString *str = [NSString stringWithFormat:@"%ld",section];
    if ([self.indexArray containsObject:str]){
        //展开返回40点高度的表尾
        return 40;
    }
    //未点击不返回高度 0有默认高度 设置为0.1
    return 0.1;
}

//添加cell单元格
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //数组中 包含表示点击了按钮  返回自定义的cell
    NSString *str = [NSString stringWithFormat:@"%ld",indexPath.section];
    if ([self.indexArray containsObject:str])
    {
       //获取点击的这一行的数据并赋值到cell
        YKSPlanDisPlayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DisPlayCell"];
        if (!cell) {
            cell = [[YKSPlanDisPlayCell alloc] init];
        }
        cell.drugInfo = self.datas[indexPath.row];
        return cell;
    }else{
        //未点击按钮状态下返回的自定义cell
        YKSPlanCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlanCell"];
        if (!cell) {
            cell = [[YKSPlanCell alloc] init];
        }
        cell.datas = [_datas copy];
        //单元格不可点击
        cell.userInteractionEnabled = NO;
        return cell;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    YKSReleaseButtonCell *releaseButtonView = [[YKSReleaseButtonCell alloc] initWithPrice:self.totalPrice andSection:@"方案一" andFrame:(CGRectMake(0, 0, self.view.bounds.size.width, 28.0f))];
    //给创建出来的每一个视图View中的按钮tag值赋值当行的分区
    releaseButtonView.clickButton.tag = section;
    //数组中 包含表示点击了
    NSString *str = [NSString stringWithFormat:@"%ld",section];
    if ([self.indexArray containsObject:str])
     {
        //显示覆盖在按钮上的向上视图
        releaseButtonView.selectedImage.image = [UIImage imageNamed:@"zhankai"];
        //设置label的不可显示状态
        releaseButtonView.priceLabel.hidden = YES;
    }else
    {
        releaseButtonView.selectedImage.image = [UIImage imageNamed:@"shouqi"];
        releaseButtonView.priceLabel.hidden = NO;
    }
    //设置为代理
    releaseButtonView.delegate = self;
    return releaseButtonView;
}

//添加表尾视图
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    //相等 表示点击了按钮
    NSString *str = [NSString stringWithFormat:@"%ld",section];
    if ([self.indexArray containsObject:str])
    {
        YKSOneBuyCell *buyView = [[YKSOneBuyCell alloc] initWithPrice:self.totalPrice andViewFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
        //返回视图
        buyView.delegate = self;
        return buyView;
    }else
    {
        //未展开状态返回一个空视图
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        return view;
    }
    
}
//按钮点击的代理方法
- (void)clickButton:(UIButton *)button
{
    //记录当前点击的按钮的tag值
    NSString *str = [NSString stringWithFormat:@"%ld",button.tag];
    if ([self.indexArray containsObject:str]) {
        [self.indexArray removeObject:str];
    }else{
        [self.indexArray addObject:str];
    }
    //刷新cell
    [self.tableView reloadData];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *str = [NSString stringWithFormat:@"%ld",indexPath.section];
    if ([self.indexArray containsObject:str])
    {
        UIStoryboard* mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        YKSDrugDetailViewController *drugDetail = [mainStoryboard instantiateViewControllerWithIdentifier:@"YKSDrugDetailViewController"];
        drugDetail.drugInfo = self.datas[indexPath.row];
        [self.navigationController pushViewController:drugDetail animated:YES];
    }
}


@end
