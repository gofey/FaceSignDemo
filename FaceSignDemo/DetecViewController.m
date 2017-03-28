//
//  DetecViewController.m
//  FaceSignDemo
//
//  Created by 厉国辉 on 2017/3/3.
//  Copyright © 2017年 Xschool. All rights reserved.
//
#define kDeviceHeight [UIScreen mainScreen].bounds.size.height
#define kDeviceWidth [UIScreen mainScreen].bounds.size.width
#import "DetecViewController.h"
#import "DetectorView.h"
#import "ViewController.h"



@interface DetecViewController ()
{
    NSTimer *timer;
    NSInteger timeCount;
    
}
@property(nonatomic,strong)DetectorView *detector;
@property(nonatomic,strong)UIImageView *frontImageView;
@property(nonatomic,strong)UIImageView *showImageView;
@property(nonatomic,strong)UILabel *timeLabel;



@end

@implementation DetecViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /********动态人脸检测必须在AppDelegate执行配置方法*********/
    /*
     
     点击拍照
     
     
     由于我做的是自动拍照。可能有的朋友是需要自己去点击的，
     请参考 DetectorViewT
     
     但是获取图片要执行getImageBlock
     self.detectorView.takePhotoBlock();
     self.detectorView.getImageBlock = ^(UIImage *image){
     
     UIImage* upLoadImage = [[image fixOrientation] compressedImage];//将图片压缩以上传服务器
     weakSelf.uploadImage = upLoadImage;
     
     };
     
     */
    
    /********改变居中的蓝色框*********/
    /*
     DetectorView.m中已经用param标注
     改变相应宽高
     
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
     
     在这个方法中
     - (BOOL)identifyYourFaceLeft:(CGFloat)left right:(CGFloat)right top:(CGFloat)top bottom:(CGFloat)bottom
     写蓝色边框和黄色的差距 以及 反馈的字典
     
     
     */
    
    
    DetectorView *detector = [[DetectorView alloc] initWithFrame:CGRectMake((kDeviceWidth - 360) / 2, 94, 360, 480)];
    [self.view addSubview:detector];
    self.detector = detector;

    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:cancelBtn];
    cancelBtn.frame = CGRectMake(CGRectGetMaxX(detector.frame) - 80, CGRectGetMaxY(detector.frame) + 15, 80, 30);
    [cancelBtn setTitle:@"清除" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    cancelBtn.backgroundColor = [UIColor yellowColor];
    [cancelBtn addTarget:self action:@selector(cancelPhoto) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *showImageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, CGRectGetMaxY(cancelBtn.frame) + 15, 100, 100)];
    [self.view addSubview:showImageView];
    showImageView.clipsToBounds = YES;
    self.showImageView = showImageView;
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 50, CGRectGetMaxY(self.showImageView.frame), 100, 30)];
    [self.view addSubview:tipLabel];
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 100, CGRectGetMaxY(tipLabel.frame) + 15, 200, 30)];
    [self.view addSubview:timeLabel];
    self.timeLabel = timeLabel;
    
    
    //    self.interfaceOrientation;
    self.detector.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    
    __weak typeof(self) weakSelf = self;
    
    self.detector.getStringBlock = ^(NSDictionary *resultDict){
        
        if ([[resultDict objectForKey:@"result"] boolValue]) {
            
            [weakSelf timeBegin];
        }
        else{
            
            [weakSelf releaseTimer];
        }
        tipLabel.text = resultDict[@"desc"];
    };
    
    
}
#pragma mark - 强制改屏幕
- (void)timeBegin{
    if (timer) {
        return;
    }
    timeCount = 3;
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeCalculate:) userInfo:nil repeats:YES];
    
    self.timeLabel.text = [NSString stringWithFormat:@"%ld s后拍照...", (long)timeCount];
}
- (void)releaseTimer{
    if (timer) {
        [timer invalidate];
        timer = nil;
        self.timeLabel.text = @"";
    }
}
- (void)timeCalculate:(NSTimer *)theTimer{
    timeCount --;
    if(timeCount >= 1)
    {
        self.timeLabel.text = [NSString  stringWithFormat:@"%ld s后拍照...",(long)timeCount];
    }
    else
    {
        [theTimer invalidate];
        theTimer=nil;
        if (self.detector.takePhotoBlock) {
            self.detector.takePhotoBlock(self.showImageView);
        }
        
    }
}
- (void)cancelPhoto{
    if (self.detector.cancelPhotoBlock) {
        self.detector.cancelPhotoBlock();
    }else{
        NSLog(@"22");
    }
    
    self.showImageView.image = nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
