//
//  UserPhotoListView.m
//  loxer
//
//  Created by amos on 2016/12/15.
//  Copyright © 2016年 zoneol. All rights reserved.
//
#define MAX_PHOTO 16
#import "UserPhotoListView.h"
#import "JKImagePickerController.h"
#import "MWPhotoBrowser.h"
#import "CustomCollectionCell.h"

#import "QiniuSDK.h"
#import "PhotoModel.h"
#import "QiniuTokenResponseModel.h"
#import "QiniuTokenModel.h"
#import "AssetsUtil.h"
#import "QiNiuPhotoURLHandle.h"
@interface UserPhotoListView ()<UICollectionViewDelegate,UICollectionViewDataSource,JKImagePickerControllerDelegate,MWPhotoBrowserDelegate,UIAlertViewDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>


/**
 *  编辑界面中选中的照片位置
 */
@property(nonatomic, strong) NSIndexPath *seletedIndexPath;


/**
 *  要删除的相片
 */
@property(nonatomic, strong) NSMutableArray * deletePhotoList;


/**
 *  要增加的相片
 */
@property(nonatomic, strong) NSMutableArray * addPhotoList;

/**
 *  用户相册
 */
@property(nonatomic, strong) NSMutableArray *albumList;


/**
 *  用户相册
 */
@property(nonatomic, strong) NSMutableArray *currentPhotoList;
/**
 *  最近动态图片列表
 */
@property(nonatomic, strong) NSArray *lastDynamicPhotoList;

/**
 *  相册的layout
 */
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *layout;

/**
 *  添加的图片地址
 */
@property(nonatomic, strong) NSMutableArray *addImageUrlArr;

/**
 添加照片的技术
 */
@property (nonatomic, assign) int addCount;

/**
 背景图片，当相册在非编辑状态，且无照片时
 */
@property (nonatomic, weak) UIImageView * bgView;

/**
 相册高度
 */
@property (nonatomic, assign) float listHeight;
@end

@implementation UserPhotoListView


-(void)reloadDataFromServer{
    [self getPhotoList];
}

-(instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout{
    
    self.layout = ( UICollectionViewFlowLayout *)layout;
    
    self =  [super initWithFrame:frame collectionViewLayout:layout];
    
    
    if (self) {
        [self setup];
    }
    
    
    return self;
}


-(void)setup{
    self.listHeight = PHOTOVIEW_H;
    self.delegate = self;
    self.dataSource = self;
    self.scrollEnabled = NO;
    self.isEditPage = YES;
    self.backgroundColor = [UIColor whiteColor];
    //注册相册的cell

     [self registerClass:[CustomCollectionCell class] forCellWithReuseIdentifier:@"CustomCollectionCell"];
    
    self.addCount = 0;
    
    self.height = self.listHeight;
}

/**
 更新相册高度
 */
-(void)updateListViewHeight{
    
    int row = ((int)[self.albumList count] + 1) / 4;
    row += ([self.albumList count] + 1) % 4 > 0 ? 1 : 0;
    
    
    if (row == 5) {
        row = 4;
    }
    
    self.listHeight = row * PHOTOVIEW_H;
    self.height = self.listHeight;
    
    
    if (self.changePhotoListHeightBlock) {
        self.changePhotoListHeightBlock(self.listHeight);
    }
    
}

-(UIImageView *)bgView{
    
    if (!_bgView) {
        UIImageView *bgView = [[UIImageView alloc] init];
        
        bgView.image = [UIImage imageNamed:@"img_fujin_bierenziliao_photo"];
        
        [self addSubview:bgView];
        
        [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(self);
            make.width.mas_equalTo(100);
            make.height.mas_equalTo(80);
        }];
        
        _bgView = bgView;
    }
    return _bgView;
}


-(BOOL)hasChanges{
    return  self.addCount > 0 || self.deletePhotoList.count > 0;
}

-(instancetype)initWithFrame:(CGRect)frame{

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    return [self initWithFrame:frame collectionViewLayout:layout];

}

-(NSMutableArray *)addImageUrlArr{
    if (!_addImageUrlArr) {
        _addImageUrlArr = [NSMutableArray array];
    }
    return _addImageUrlArr;
}

-(NSMutableArray *)addPhotoList{
    if (!_addPhotoList) {
        _addPhotoList = [NSMutableArray array];
    }
    return _addPhotoList;
}

-(NSMutableArray *)deletePhotoList{
    
    if (!_deletePhotoList) {
        _deletePhotoList = [NSMutableArray array];
    }
    
    return _deletePhotoList;
}

-(NSMutableArray *)albumList{
    if (!_albumList) {
        _albumList = [NSMutableArray array];
        
    }
    return _albumList;
}

-(NSArray *)lastDynamicPhotoList{
    if (!_lastDynamicPhotoList) {
        _lastDynamicPhotoList = [NSArray array];
    }
    
    return _lastDynamicPhotoList;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat width = (SCREENWIDTH - 30) / 4;
    
    self.layout.itemSize = CGSizeMake(width, width);
    
    self.contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
    
    self.layout.minimumInteritemSpacing = 5;
    
    self.layout.minimumLineSpacing = 5;
}

-(void)setUserId:(NSInteger)userId{
    _userId = userId;
    
    [self getPhotoList];
}

/**
 *  获取个人相册
 */
-(void)getPhotoList{
    //获取用户相册
    
    AMWeakSelf(self)
    
    [[UserManager manager] getUserPhotoListWithUserId:self.userId pageNo:1 pageSize:8 finishedBlock:^(id data, NSError *error) {
        AMStrongSelf(self)
        
        [self setPhotolist:data];

    }];
}

-(void)setPhotolist:(id)data{
    AMWeakSelf(self)
    //先清空
    [self.albumList removeAllObjects];
    
    if ([data isKindOfClass:[NSArray class]]) {
        
        self.currentPhotoList = data;
        
        [data enumerateObjectsUsingBlock:^(PhotoModel* photo, NSUInteger idx, BOOL * _Nonnull stop) {
            AMStrongSelf(self)
            [self.albumList addObject:photo.imgUrl];
        }];
        
        [self.currentPhotoList sortUsingComparator:^NSComparisonResult(PhotoModel* obj1, PhotoModel* obj2) {
            return obj1.createdTime < obj2.createdTime;
        }];
        
        if ( !self.isEditPage) {
            self.bgView.hidden = !([(NSArray*)data count] == 0);
        }
        
    }else{
        if ( !self.isEditPage) {
            self.bgView.hidden = NO;
        }
    }
    [self updateListViewHeight];
    [self reloadData];
}

#pragma mark - 代理和数据源
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    //如果相册没有照片，而且点击了编辑按钮
    if (self.isEditPage) {
        return self.albumList.count + 1;
    }
    
    return self.albumList.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CustomCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CustomCollectionCell" forIndexPath:indexPath];
    
    cell.showDeleteBtn = NO;
    if (indexPath.item == MAX_PHOTO) {
        cell.hidden = YES;
    }else{
        cell.hidden = NO;
    }
    
    AMWeakSelf(self)
    
    //如果在编辑状态，最后一个应该是 + 号
    if (self.albumList.count == indexPath.item){
        
        cell.model = nil;
        
    }else{
        //获取照片模型
        id photo = self.albumList[indexPath.item];
        cell.imageView.layer.cornerRadius = 5;
        cell.imageView.layer.masksToBounds = YES;
        if ([photo isKindOfClass:[JKAssets class]]) {
            cell.model = photo;
            
            //删除从相册选择的图片操作
            [cell setDeleteCellBlock:^(id data) {
                
                AMStrongSelf(self)
                
                //先获取该图片在相册中的位置，再删除指定位置，否则有可能会崩溃
                NSInteger index = [self.albumList indexOfObject:data];
                [self.albumList removeObject:data];
                //删除指定的行
                [self deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:indexPath.section]]];
            }];
            
        }else{
            cell.model = photo;
            [cell setDeleteCellBlock:^(id data) {
               AMStrongSelf(self)
                [self.currentPhotoList enumerateObjectsUsingBlock:^(PhotoModel* photo, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if ([photo.imgUrl isEqualToString:data]) {
                        //放在删除相片数组中
                        [self.deletePhotoList addObject:photo.photoId];
                        *stop = YES;
                    }
                }];
                //先获取该图片在相册中的位置，再删除指定位置，否则有可能会崩溃
                NSInteger index = [self.albumList indexOfObject:data];
                
                [self.albumList removeObject:data];
                
                [self deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:indexPath.section]]];
            }];
        }
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    /**
     *  如果选择的是最后一个
     */
    if (self.albumList.count == indexPath.item){
        [self selectPhotoFromAlbum:0];
    }else{
        
        if (self.isEditPage) {
            self.seletedIndexPath = indexPath;
            //弹出功能选择框
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"拍照" otherButtonTitles:@"从图库中选",@"设为头像",@"删除", nil];
            actionSheet.destructiveButtonIndex = 3;
            [actionSheet showInView:self.fatherVC.view];
        }else{
            //获取模型
            MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
            browser.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            browser.enableSwipeToDismiss = YES;
            [browser showNextPhotoAnimated:YES];
            [browser showPreviousPhotoAnimated:YES];
            [browser setCurrentPhotoIndex:indexPath.item];
            self.fatherVC.hidesBottomBarWhenPushed = YES;
            [self.fatherVC presentViewController:browser animated:YES completion:nil];
            
        }
    }
}


#pragma mark - 点击照片

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    CustomCollectionCell *cell = (CustomCollectionCell *)[self cellForItemAtIndexPath:self.seletedIndexPath];
    switch (buttonIndex) {
        case 3:
            //删除
            [cell delBtnClicked:nil];
            self.seletedIndexPath = nil;
            break;
        case 2:
            [self setPhotoAsHeaderIcon:cell];
            break;
        case 1:
            //从相册中选择
            [self selectPhotoFromAlbum:1];
            break;
        case 0:
            [self takePhoto];
            break;
        default:
            break;
    }
    
}

-(void)setPhotoAsHeaderIcon:(CustomCollectionCell *)cell{
    //上传图片到七牛服务器
    if (self.setHeaderIconHandler) {
        self.setHeaderIconHandler(cell.imageView.image);
    }
}

-(void)takePhoto{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *pickerController = [[UIImagePickerController alloc]init];
        pickerController.delegate = self;
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerController.allowsEditing = YES;
        pickerController.showsCameraControls = YES;
        
        
        [self.fatherVC presentViewController:pickerController animated:YES completion:^{
        }];
    }
}

/**
 *  从相册中选择照片
 */
-(void)selectPhotoFromAlbum:(NSInteger) maxNum{
    
    if (maxNum == 0) {
        maxNum = MAX_PHOTO - self.albumList.count;
    }
    
    
    JKImagePickerController *imagePickerController = [[JKImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.showsCancelButton = YES;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.minimumNumberOfSelection = 1;
    imagePickerController.maximumNumberOfSelection = maxNum;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
    
    
    [self.fatherVC presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - 图片浏览器的代理事件
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    //获取模型个数
    return self.albumList.count;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index{
    
    
    NSString *thumnailFormatter = [NSString stringWithFormat:@"/thumbnail/%dx%d",(int)SCREENWIDTH,(int)SCREENHEIGHT];
    
    MWPhoto *photo = [MWPhoto photoWithURL:[QiNiuPhotoURLHandle getURLWithQNFormatWithPath:self.albumList[index] paramStr:@[thumnailFormatter]]];
    
    return photo;
    
}

#pragma mark - JKImagePickerControllerDelegate
- (void)imagePickerController:(JKImagePickerController *)imagePicker didSelectAsset:(JKAssets *)asset isSource:(BOOL)source
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(JKImagePickerController *)imagePicker didSelectAssets:(NSArray *)assets isSource:(BOOL)source
{
    
    if (self.seletedIndexPath) {
        
        id image = self.albumList[self.seletedIndexPath.row];
        
        if ([image isKindOfClass:[NSString class]]) {
            
            AMWeakSelf(self)
            
            [self.currentPhotoList enumerateObjectsUsingBlock:^(PhotoModel* photo, NSUInteger idx, BOOL * _Nonnull stop) {
                AMStrongSelf(self)
                if ([photo.imgUrl isEqualToString:image]) {
                    //放在删除相片数组中
                    [self.deletePhotoList addObject:photo.photoId];
                    *stop = YES;
                }
            }];
        }
        //先获取该图片在相册中的位置，再删除指定位置，否则有可能会崩溃
        NSInteger index = [self.albumList indexOfObject:image];
        
        [self.albumList replaceObjectAtIndex:index withObject:assets.lastObject];
        
        [self reloadItemsAtIndexPaths:@[self.seletedIndexPath]];
        self.seletedIndexPath = nil;
        
        
    }else{
        self.addCount += 1;
        
        if ([self.albumList count] > 0) {
            AMWeakSelf(self)
            [assets enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                AMStrongSelf(self)
                [self.albumList insertObject:obj atIndex:0];
                
                 [self insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
            }];
        }else{
            [self.albumList addObjectsFromArray:assets];
           
            [UIView performWithoutAnimation:^{
                 [self reloadData];
            }];
            
        }
        
        //更新想的高度
        [self updateListViewHeight];
    }
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)dealloc{
    NSLog(@"UserPhotoListView dealloc");
}

- (void)imagePickerControllerDidCancel:(JKImagePickerController *)imagePicker
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage] ;
    
    AMWeakSelf(self)

    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        
        [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            AMStrongSelf(self)
            if (asset) {
                
                JKAssets *jkAsset = [[JKAssets alloc] init];
                NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                
                jkAsset.assetPropertyURL = assetURL;
                
                if (self.seletedIndexPath) {
                    
                    id image = self.albumList[self.seletedIndexPath.row];
                    
                    if ([image isKindOfClass:[NSString class]]) {
                        [self.currentPhotoList enumerateObjectsUsingBlock:^(PhotoModel* photo, NSUInteger idx, BOOL * _Nonnull stop) {
                            
                            if ([photo.imgUrl isEqualToString:image]) {
                                //放在删除相片数组中
                                [self.deletePhotoList addObject:photo.photoId];
                                *stop = YES;
                            }
                        }];
                    }
                    
                    //先获取该图片在相册中的位置，再删除指定位置，否则有可能会崩溃
                    NSInteger index = [self.albumList indexOfObject:image];
                    
                    
                    [self.albumList replaceObjectAtIndex:index withObject:jkAsset];
                    
                    
                    [self reloadItemsAtIndexPaths:@[self.seletedIndexPath]];
                    
                    self.seletedIndexPath = nil;
                }
                
            }
        } failureBlock:^(NSError *error) {
            
        }];
    }];
    
    
    [picker dismissViewControllerAnimated:NO completion:^{}];
    
    
}

-(void)updatePhotoList{
    
    AMWeakSelf(self)
    
    [self.albumList enumerateObjectsUsingBlock:^(id  _Nonnull photo, NSUInteger idx, BOOL * _Nonnull stop) {
        AMStrongSelf(self)
        //如果是从本地相册选择的图片，那么需要上传
        if ([photo isKindOfClass:[JKAssets class]]){
            
            [self.addPhotoList addObject:photo];
            
        }
        
    }];
    
    //如果删除或者添加列表中任何一个有值
    if (self.deletePhotoList.count > 0 || self.addPhotoList.count > 0) {
        //如果两个都有值，那么就调用批量修改
        if (self.deletePhotoList.count > 0 && self.addPhotoList.count > 0) {
            
            [self addPhoto];
            
        }else if (self.deletePhotoList.count > 0){
            
            if (self.deletePhotoList.count == 1) {
                [self deletePhoto];
            }else{
                [self updatePhoto];
            }
            
        }else{
            [self addPhoto];
        }
        
    }else{
        //如果没有那么久直接返回个人信息界面
        [self.fatherVC.navigationController popViewControllerAnimated:YES];
    }
    
}

/**
 *  删除照片
 */
-(void)deletePhoto{
    //提交删除相片
    AMWeakSelf(self)
    if (self.deletePhotoList.count > 0) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.fatherVC.view animated:YES];
        hud.labelText = @"正在更新...";
        
        
        [[UserManager manager] deletePhoto:self.deletePhotoList finishedBlock:^(id data, id error) {
            [MBProgressHUD hideHUDForView:self.fatherVC.view animated:YES];
            AMStrongSelf(self)
            if (!error) {
                //删除成功后清空删除相片数组缓存
                if ([data integerValue]== ResultCode_HTTP_SUCCESS) {
                    [self.deletePhotoList removeAllObjects];
                    
                    
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_PHOTOLIST object:nil];
                    [self.fatherVC.navigationController popViewControllerAnimated:YES];
                    
                }else{
                    [AlertUtil alterViewShow:@"删除照片失败!" withTitle:@""];
                }
            }else{
                
                switch ([error integerValue]) {
                    case ResultCode_HTTP_UNKNOW_ERROR:
                        [AlertUtil alterViewShow:@"服务器错误！" withTitle:@""];
                        break;
                    case ResultCode_HTTP_OFFLINE_ERROR:
                        [AlertUtil alterViewShow:@"没有网络！" withTitle:@""];
                        break;
                        
                    default:
                        break;
                }
                
            }
            
            
            
        }];
        
    }
}

-(void)addPhoto{
    
    if (self.addPhotoList.count > 0) {
        //先获取七牛token
        __block NSString *baseUrl = nil;
        
        AMWeakSelf(self)
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.fatherVC.view animated:YES];
        hud.labelText = @"正在上传...";
        [[UserManager manager] getQiNiuTokenType:QiniuTokenTypeAlbum count:self.addPhotoList.count finishedBlock:^(id data, id error) {
            AMStrongSelf(self)
            if (!error) {
                
                QiniuTokenResponseModel *model = data;
                
                
                baseUrl = [NSString stringWithFormat:@"%@/",model.url];
                
                
                //遍历token，依次上传到七牛上
                [model.tokens enumerateObjectsUsingBlock:^(QiniuTokenModel*token, NSUInteger index, BOOL * _Nonnull stop) {
                    
                    BOOL finished = (index == self.addPhotoList.count - 1);
                    
                    [AssetsUtil getImageFromAsset:self.addPhotoList[index] compressedRate:0.3 finishedBlock:^(id image) {
                        //每次上传一张
                        [self uploadQinNiuToken:token.token data:image type:QiniuTokenTypeAlbum fileName:token.fileName baseUrl:baseUrl uploadAll:finished count:self.addPhotoList.count];
                    }];
                    
                }];
                
            }else{
                [MBProgressHUD hideHUDForView:self.fatherVC.view animated:YES];
                
                switch ([error integerValue]) {
                    case ResultCode_HTTP_UNKNOW_ERROR:
                        [AlertUtil alterViewShow:@"服务器错误！" withTitle:@""];
                        break;
                    case ResultCode_HTTP_OFFLINE_ERROR:
                        [AlertUtil alterViewShow:@"没有网络！" withTitle:@""];
                        break;
                        
                    default:
                        break;
                }
                
            }
            
        }];
    }
}

-(void) uploadQinNiuToken:(NSString *) token data:(NSData *) nsData type:(QiniuTokenType) type  fileName:(NSString*)fileName baseUrl:(NSString*)baseUrl uploadAll:(BOOL)uploadFinished count:(NSInteger)count{
    
    QNUploadManager *upManager = [[QNUploadManager alloc] init];
    
    AMWeakSelf(self)
    
    [upManager putData:nsData key:fileName token:token
              complete: ^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                  if (resp) {
                      
                      AMStrongSelf(self)
                      NSString * keyResult = [resp objectForKey:@"key"] ;
                      //   NSLog(@"返回数据：%@" , keyResult) ;
                      
                      NSString*imageUrl =  [baseUrl stringByAppendingString:keyResult];
                      
                      [self.addImageUrlArr addObject:imageUrl];
                      
                      if (self.addImageUrlArr.count == count) {
                          //如果只有一张，那么调用普通添加
                          if (count == 1 && self.deletePhotoList.count == 0) {
                              //上传到公司服务器
                              [[UserManager manager] addPhoto:imageUrl finishedBlock:^(id data, NSError *error) {
                                  
                                  [MBProgressHUD hideHUDForView:self.fatherVC.view animated:YES];
                                  if ([data integerValue] == ResultCode_HTTP_SUCCESS) {
                                      
                                      // NSLog(@"上传照片完成");
                                      //上传完成后清空添加相片的数组
                                      [self.addPhotoList removeAllObjects];
                                      
                                      [self reloadData];
                                      [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_PHOTOLIST object:nil];
                                      [self.fatherVC.navigationController popViewControllerAnimated:YES];
                                  }
                              }];
                              
                          }else{
                              
                              [self updatePhoto];
                          }
                          
                      }
                      
                  }
                  
              } option:nil];
}



-(void)updatePhoto{
    
    AMWeakSelf(self)
    
    //如果有多张
    [[UserManager manager] updatePhoto:self.addImageUrlArr deleteList:self.deletePhotoList finishedBlock:^(id data, id error) {
        AMStrongSelf(self)
        [MBProgressHUD hideHUDForView:self.fatherVC.view animated:YES];
        
        if (!error) {
            if ([data integerValue] == ResultCode_HTTP_SUCCESS) {
                [self.addImageUrlArr removeAllObjects];
                //NSLog(@"上传照片完成");
                //上传完成后清空添加相片的数组
                [self.addPhotoList removeAllObjects];
                
                [self reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_PHOTOLIST object:nil];
//                [self.fatherVC.navigationController popViewControllerAnimated:YES];
                
                if (self.updatePhotoListComplete) {
                    self.updatePhotoListComplete();
                }
            }
        }else{
            
            switch ([error integerValue]) {
                case ResultCode_HTTP_UNKNOW_ERROR:
                    [AlertUtil alterViewShow:@"服务器错误！" withTitle:@""];
                    break;
                case ResultCode_HTTP_OFFLINE_ERROR:
                    [AlertUtil alterViewShow:@"没有网络！" withTitle:@""];
                    break;
                    
                default:
                    break;
            }
        }
    }];
}

@end
