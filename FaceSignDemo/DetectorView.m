//
//  DetectorView.m
//  FaceSignDemo
//
//  Created by 厉国辉 on 2017/3/1.
//  Copyright © 2017年 Xschool. All rights reserved.
//

#import "DetectorView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "PermissionDetector.h"
#import "UIImage+Extensions.h"
#import "UIImage+compress.h"
#import "iflyMSC/IFlyFaceSDK.h"
#import "CaptureManager.h"
#import "CanvasView.h"
#import "CalculatorTools.h"
#import "UIImage+Extensions.h"
#import "IFlyFaceImage.h"
#import "IFlyFaceResultKeys.h"

typedef UIImage *(^ImageBlock)(UIImageView *showImageView);

@interface DetectorView()<CaptureManagerDelegate,CaptureNowImageDelegate>
{
    CGFloat _leftEage;
    CGFloat _rightEage;
    CGFloat _topEage;
    CGFloat _bottomEage;
    
    
}
@property (nonatomic, retain ) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain ) CaptureManager *captureManager;

@property (nonatomic, retain ) IFlyFaceDetector           *faceDetector;
@property (nonatomic, strong ) CanvasView                 *viewCanvas;

@property(nonatomic,copy)PhotoBlcok setPhotoDelegateBlock;

@property(nonatomic,copy)ImageBlock getImageBlock;
@end

@implementation DetectorView
@synthesize captureManager;
#pragma mark - View lifecycle
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        dispatch_queue_t q = dispatch_get_global_queue(0, 0);
        dispatch_async(q, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        });
        
        self.faceDetector = [IFlyFaceDetector sharedInstance];
        
        //初始化 CaptureSessionManager
        self.captureManager = [[CaptureManager alloc] init];
        self.captureManager.delegate=self;
        
        self.previewLayer = self.captureManager.previewLayer;
        
        self.captureManager.previewLayer.frame = self.bounds;
        self.captureManager.interfaceOrientation = self.interfaceOrientation;
        self.captureManager.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.layer addSublayer:self.captureManager.previewLayer];
        
        self.viewCanvas = [[CanvasView alloc] initWithFrame:self.captureManager.previewLayer.frame] ;
        [self addSubview:self.viewCanvas] ;
        self.viewCanvas.center = self.captureManager.previewLayer.position;
        self.viewCanvas.backgroundColor = [UIColor clearColor] ;
        
#pragma mark - 中间锁定框
        CGFloat width = 240;//居中框宽
        CGFloat height = 320;//居中框高
        NSString *str = [NSString stringWithFormat:@"{{%f, %f}, {%f, %f}}",(frame.size.width - width)/2,(frame.size.height - height)/2 + 15,width,height];
        _leftEage = (frame.size.width - width) / 2;
        _rightEage = (frame.size.width - width) / 2 + width;
        _topEage = (frame.size.height - height)/2 + 15;
        _bottomEage = (frame.size.height - height)/2 + 15 + height;
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
        [dic setObject:str forKey:@"RECT_KEY"];
        [dic setObject:@"1" forKey:@"RECT_ORI"];
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        [arr addObject:dic];
        self.viewCanvas.arrFixed = arr;
        __weak __typeof(self) weakSelf = self;
        self.setPhotoDelegateBlock = ^(void){
            
            weakSelf.captureManager.nowImageDelegate = weakSelf;
        };
        self.cancelPhotoBlock = ^(){
            [weakSelf.previewLayer.session startRunning];
        };
        
        self.takePhotoBlock = ^(UIImageView *showImageView){
            
            if (weakSelf.setPhotoDelegateBlock) {
                weakSelf.setPhotoDelegateBlock();
            }
            
            //延时操作
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //取得的静态影像
                if (weakSelf.getImageBlock) {
                    weakSelf.getImageBlock(showImageView);
                }
                
            });
            
        };
        [self.captureManager setup];
        [self.captureManager addObserver];
        //    NSLog(@"");
        //开启人脸检索
        [self.faceDetector setParameter:@"1" forKey:@"detect"];
        [self.faceDetector setParameter:@"1" forKey:@"align"];
        
        
//        self.layer.affineTransform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return self;
}
- (UIInterfaceOrientation)interfaceOrientation{
    if (!_interfaceOrientation) {
        _interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    return _interfaceOrientation;
}
-(void)dealloc{
    self.captureManager=nil;
    self.viewCanvas=nil;
}
- (void)willRemoveSubview:(UIView *)subview{
    [super willRemoveSubview:subview];
    
    [self.captureManager removeObserver];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    [self.captureManager observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Data Parser

- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons{
    if (self.viewCanvas.hidden) {
        self.viewCanvas.hidden = NO ;
    }
    self.viewCanvas.arrPersons = arrPersons ;
    [self.viewCanvas setNeedsDisplay] ;
}

- (void) hideFace {
    if (!self.viewCanvas.hidden) {
        self.viewCanvas.hidden = YES ;
    }
}
#pragma mark --- 脸部框识别
-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!positionDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera=self.captureManager.videoDeviceInput.device.position==AVCaptureDevicePositionFront;
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.previewLayer.frame.size.height / faceImg.width;
    
    CGFloat bottom =[[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top = [[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left = [[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right = [[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    
    
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace=rSwap(rectFace);
        rectFace=rRotate90(rectFace, faceImg.height, faceImg.width);
    }
    
    

    
    rectFace = rScale(rectFace, widthScaleBy, heightScaleBy);
    
    [self identifyYourFaceLeft:CGRectGetMinX(rectFace) right:CGRectGetMaxX(rectFace) top:CGRectGetMinY(rectFace) bottom:CGRectGetMaxY(rectFace)];
    return NSStringFromCGRect(rectFace);
    
}
#pragma mark --- 脸部部位识别
-(NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg{
    if(!landmarkDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera=self.captureManager.videoDeviceInput.device.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.previewLayer.frame.size.height / faceImg.width;
    
    NSMutableArray *arrStrPoints = [NSMutableArray array] ;
    NSEnumerator* keys=[landmarkDic keyEnumerator];
    for(id key in keys){
        id attr=[landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr=[landmarkDic objectForKey:key];
            CGFloat x=[[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y=[[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            
            CGPoint p = CGPointMake(y,x);
            
            if(!isFrontCamera){
                p=pSwap(p);
                p=pRotate90(p, faceImg.height, faceImg.width);
            }
            
            p=pScale(p, widthScaleBy, heightScaleBy);
            
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
            
        }
    }
    return arrStrPoints;
    
}
#pragma mark --- 判断位置
- (BOOL)identifyYourFaceLeft:(CGFloat)left right:(CGFloat)right top:(CGFloat)top bottom:(CGFloat)bottom
{

    NSLog(@"left = %f,right = %f,top = %f,bottom = %f,_leftEage = %f,_rightEage = %f,_topEage = %f,_bottomEage = %f",left,right,top,bottom,_leftEage,_rightEage,_topEage,_bottomEage);
    
    if (right - left <= 240 && bottom < _bottomEage && left > _leftEage && right < _rightEage && top > _topEage) {
        if (self.getStringBlock ) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:@1 forKey:@"result"];
            [dict setObject:@"三秒后拍照啦" forKey:@"desc"];
            self.getStringBlock(dict);
        }
        return YES;
    }else{
        if (self.getStringBlock ) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:@0 forKey:@"result"];
            [dict setObject:@"出界啦" forKey:@"desc"];
            self.getStringBlock(dict);
        }
        return YES;
    }
    return NO;
}

#pragma mark - CaptureNowImageDelegate

-(void)returnNowShowImage:(UIImage *)image
{
    //停止摄像
    [self.previewLayer.session stopRunning];
    //取得的静态影像
    
    self.getImageBlock = ^(UIImageView *showImageView){
        
        showImageView.image = image;
        showImageView.contentMode = UIViewContentModeScaleAspectFill;
        return image;
        
    };
    self.captureManager.nowImageDelegate=nil;
//    //延时操作
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //取得的静态影像
//        
//        self.getImageBlock = ^(void){
//            NSLog(@"sssss");
//            return image;
//        };
//        self.captureManager.nowImageDelegate=nil;
//    });
    
}

-(void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!result){
        return;
    }
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData=nil;
        if(!faceDic){
            return;
        }
        
        NSString* faceRet = [faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray* faceArray = [faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic = nil;
        
        int ret = 0;
        if(faceRet){
            ret = [faceRet intValue];
        }
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count]<1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideFace];
                [self identifyYourFaceLeft:0 right:0 top:0 bottom:0];
            } ) ;
            return;
        }
        
        //检测到人脸
        
        NSMutableArray *arrPersons = [NSMutableArray array] ;
        
        for(id faceInArr in faceArray){
            
            if(faceInArr && [faceInArr isKindOfClass:[NSDictionary class]]){
                
                NSDictionary* positionDic=[faceInArr objectForKey:KCIFlyFaceResultPosition];
                NSString* rectString=[self praseDetect:positionDic OrignImage: faceImg];
                positionDic=nil;
                
                NSDictionary* landmarkDic=[faceInArr objectForKey:KCIFlyFaceResultLandmark];
                NSMutableArray* strPoints=[self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic=nil;
                
                
                NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
                if(rectString){
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                    
                    
                    
//                    NSLog(@"rect = %@",rectString);
                    
//                    CGRect rect=CGRectFromString([dicPerson objectForKey:RECT_KEY]);
                    
                    
                    
                }
                if(strPoints){
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                    
                    
                }
                
                strPoints=nil;
                
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson] ;
                
                dicPerson=nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
                } ) ;
            }
        }
        faceArray=nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
    
}

#pragma mark - CaptureManagerDelegate

-(void)onOutputFaceImage:(IFlyFaceImage*)faceImg{
    
    NSString* strResult=[self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
    
    //NSLog(@"result:%@",strResult);
    //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用。
    faceImg.data=nil;
    
    NSMethodSignature *sig = [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
    if (!sig) return;
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
    [invocation setArgument:&strResult atIndex:2];
    [invocation setArgument:&faceImg atIndex:3];
    [invocation retainArguments];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
    faceImg = nil;
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
