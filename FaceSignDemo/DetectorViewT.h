//
//  DetectorView.h
//  FaceSignDemo
//
//  Created by 厉国辉 on 2017/3/1.
//  Copyright © 2017年 Xschool. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PhotoBlcok)();

typedef void(^ImageBlock)(UIImage *image);

typedef void(^StringBlcok)(NSDictionary *resultDict);

@interface DetectorViewT : UIView

@property(nonatomic,copy)PhotoBlcok takePhotoBlock;
@property(nonatomic,copy)PhotoBlcok cancelPhotoBlock;
@property(nonatomic,copy)StringBlcok getStringBlock;
@property(nonatomic,copy)ImageBlock getImageBlock;

@end
