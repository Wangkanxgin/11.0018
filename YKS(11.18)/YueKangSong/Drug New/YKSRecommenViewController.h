//
//  YKSRecommenViewController.h
//  YKSDrugPushing
//
//  Created by TT on 15/10/25.
//  Copyright © 2015年 Saintly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YKSFormInformation.h"


@interface YKSRecommenViewController : UITableViewController
@property (strong, nonatomic) NSString *specialId;
//每一个当前页面的"症状名称""临床症状""药师推荐"
@property (nonatomic,strong) YKSFormInformation *formInformation;
//@property (assign, nonatomic) YKSDrugListType1 drugListType;
@property (strong, nonatomic) NSArray *datas;
@end
