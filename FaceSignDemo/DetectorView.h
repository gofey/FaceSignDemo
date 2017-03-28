//
//  DetectorView.h
//  FaceSignDemo
//
//  Created by 厉国辉 on 2017/3/1.
//  Copyright © 2017年 Xschool. All rights reserved.
//

#import <UIKit/UIKit.h>
//定义block
typedef void(^TakeBlock)(UIImageView *showImageView);

typedef void(^PhotoBlcok)();


typedef void(^StringBlcok)(NSDictionary *resultDict);

@interface DetectorView : UIView

//进行拍照
@property(nonatomic,copy)TakeBlock takePhotoBlock;

@property (nonatomic) UIInterfaceOrientation interfaceOrientation;//方向
//取消拍照状态，重新拍
@property(nonatomic,copy)PhotoBlcok cancelPhotoBlock;
//获取信息反馈
@property(nonatomic,copy)StringBlcok getStringBlock;

//@property(nonatomic,copy)NSString *resultString;

@end
