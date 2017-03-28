//
//  UserPhotoListView.h
//  loxer
//
//  Created by amos on 2016/12/15.
//  Copyright © 2016年 zoneol. All rights reserved.
//
#define PHOTOVIEW_H ((SCREENWIDTH - 30) / 4) + 20

#import <UIKit/UIKit.h>

@interface UserPhotoListView : UICollectionView

/**
 父控制器
 */
@property (nonatomic, weak) UIViewController * fatherVC;

/**
 用户id
 */
@property (nonatomic, assign) NSInteger userId;


/**
 是否是编辑状态 -- 默认是编辑状态
 */
@property (nonatomic, assign) BOOL isEditPage;


/**
 是否有更改
 */
@property (nonatomic, assign) BOOL hasChanges;

/**
  更新相册完成回调
 */
@property (nonatomic, copy) void (^updatePhotoListComplete)();

/**
 更新相册高度回调
 */
@property (nonatomic, copy) void (^changePhotoListHeightBlock)(float height);

/**
 设置头像回调
 */
@property (nonatomic, copy) void (^setHeaderIconHandler)(id iamge);

/**
 上传或者删除图片，更新到服务器
 */
-(void)updatePhotoList;


-(void)reloadDataFromServer;


-(void)setPhotolist:(id)data;
@end
