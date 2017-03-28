//
//  CustomCollectionCell.m
//  loxer
//
//  Created by amos on 16/5/28.
//  Copyright © 2016年 zoneol. All rights reserved.
//

#import "CustomCollectionCell.h"
#import "JKImagePickerController.h"
#import "QiNiuPhotoURLHandle.h"
@interface CustomCollectionCell ()

/**
 *  删除按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *delteBtn;


@end

@implementation CustomCollectionCell

+(instancetype)customCell{
    return[[NSBundle mainBundle] loadNibNamed:@"CustomCollectionCell" owner:nil options:nil].firstObject;
}


-(instancetype)initWithFrame:(CGRect)frame{

    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        
    }
    return self;
}

-(void)setupUI{
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.isHeadIcon = NO;
    //创建图片视图
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    self.imageView = imageView;
    [self.contentView addSubview:imageView];

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(self.contentView);
    }];
}


- (void)delBtnClicked:(id)sender {
    
    if (self.deleteCellBlock) {
        self.deleteCellBlock(self.model);
    }
}

-(void)setShowDeleteBtn:(BOOL)showDeleteBtn{
    _showDeleteBtn = showDeleteBtn;
    
    self.delteBtn.hidden = !showDeleteBtn;
}

-(void)setModel:(id)model{
    _model = model;
    
    if (!model) {
        _imageView.image = [UIImage imageNamed:@"icon_bianjiziliao_img_add"];
        return;
    }
    
    if ([model isKindOfClass:[NSString class]]) {
        //此时用的是七牛上传的，也可以直接换成图片 url
        NSURL *url = [QiNiuPhotoURLHandle getURLWithQNFormatWithPath:model paramStr:@[THUMBNAIL_SHORT_EDGE_150, CROP_CENTER_150]];
        if (url) {
            [_imageView sd_setImageWithURL:url];
        }else{
            _imageView.image = [UIImage imageNamed:model];
        }
        
        
    }else if([model isKindOfClass:[JKAssets class]]){
        JKAssets *asset = model;
        //获取原始图片
        ALAssetsLibrary  *lib = [[ALAssetsLibrary alloc] init];
        [lib assetForURL:asset.assetPropertyURL resultBlock:^(ALAsset *asset) {
            if (asset) {
                self.imageView.image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
            }
        } failureBlock:^(NSError *error) {
            
        }];
    }

}

@end
