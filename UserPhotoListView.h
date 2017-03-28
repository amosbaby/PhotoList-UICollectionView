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
 用户id
 */
@property (nonatomic, assign) NSInteger userId;


/**
 是否是编辑状态 -- 默认是编辑状态
 */
@property (nonatomic, assign) BOOL isEditPage;


/**
 更新相册高度回调
 */
@property (nonatomic, copy) void (^changePhotoListHeightBlock)(float height);


-(void)setPhotolist:(id)data;
@end
