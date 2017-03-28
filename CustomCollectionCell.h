//
//  CustomCollectionCell.h
//  loxer
//
//  Created by amos on 16/5/28.
//  Copyright © 2016年 zoneol. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface CustomCollectionCell : UICollectionViewCell

/**
 *  图片
 */
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

/**
 是否是头像
 */
@property (nonatomic, assign) BOOL isHeadIcon;

/**
 图片地址或者链接
 */
@property(nonatomic, strong) id model;

/**
 *  删除按钮回调
 */
@property(nonatomic, copy) void (^deleteCellBlock)(id param);

/**
 *  是否显示删除按钮
 */
@property(nonatomic, assign) BOOL showDeleteBtn;

/**
 快捷创建 cell

 @return 
 */
+(instancetype) customCell;

/**
 点击了删除按钮

 @param sender
 */
- (void)delBtnClicked:(id)sender;
@end
