//
//  ViewController.m
//  FaceSignDemo
//
//  Created by 厉国辉 on 17/2/8.
//  Copyright © 2017年 Xschool. All rights reserved.
//

#define USER_APPID           @"5895385f"
#define kDeviceHeight [UIScreen mainScreen].bounds.size.height
#define kDeviceWidth [UIScreen mainScreen].bounds.size.width

#import "ViewController.h"

#import "UIImage+Extensions.h"
#import "UIImage+compress.h"
#import "PermissionDetector.h"
#import "iflyMSC/IFlyFaceSDK.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "IFlyFaceResultKeys.h"
@interface ViewController ()<IFlyFaceRequestDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic,retain) IFlyFaceRequest * iFlySpFaceRequest;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,strong) NSString *resultStings;
@property (nonatomic,strong) UILabel *labelView;
@property (nonatomic,strong) UIImageView *showImageView;
@property (nonatomic,strong) UILabel *gidsLabel;
@property (nonatomic,strong) UITextField *auth_idTextField;

@end

@implementation ViewController
{
    int _flag;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _flag = 0;
    self.resultStings  = [NSString string];
//    self.gids = [NSString string];
    self.iFlySpFaceRequest = [IFlyFaceRequest sharedInstance];
    self.iFlySpFaceRequest.delegate = self;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 15, kDeviceHeight / 2 - 15, 30, 30)];
    [self.view addSubview:self.activityIndicator];
    
    self.labelView = [[UILabel alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 50, 20, 100, 30)];
    [self.view addSubview:self.labelView];
    self.labelView.text = @"注册与验证";
    UIButton *regBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:regBtn];
    [regBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [regBtn setTitle:@"注册" forState:UIControlStateNormal];
    regBtn.frame = CGRectMake(kDeviceWidth / 2 - 50, 200, 100, 45);
    [regBtn addTarget:self action:@selector(regBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *vefBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [vefBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:vefBtn];
    vefBtn.frame = CGRectMake(kDeviceWidth / 2 - 50, CGRectGetMaxY(regBtn.frame) + 15, 100, 45);
    [vefBtn setTitle:@"验证" forState:UIControlStateNormal];
    
    [vefBtn addTarget:self action:@selector(vefBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    self.showImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 200, CGRectGetMaxY(vefBtn.frame) + 30, 400, 400)];
    [self.view addSubview:self.showImageView];
    self.showImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.showImageView.backgroundColor = [UIColor blackColor];
    
    UILabel *gidsLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 300, CGRectGetMaxY(self.showImageView.frame) + 15, 600, 40)];
    [self.view addSubview:gidsLabel];
    self.gidsLabel = gidsLabel;
    gidsLabel.textAlignment = NSTextAlignmentCenter;
    gidsLabel.backgroundColor = [UIColor lightGrayColor];
    gidsLabel.font = [UIFont systemFontOfSize:24];
    gidsLabel.textColor = [UIColor blackColor];
    self.gidsLabel.text = @"23456789034567894578dhkjjkfhsjkdfkashfkjfasdfadsfdsg";
    UITextField *auth_idTextField = [[UITextField alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 50, CGRectGetMaxY(self.labelView.frame) + 15, 100, 30)];
    [self.view addSubview:auth_idTextField];
    self.auth_idTextField = auth_idTextField;
    auth_idTextField.backgroundColor = [UIColor lightGrayColor];
//    UILabel * auth_idLabel = [[UILabel alloc] initWithFrame:CGRectMake(kDeviceWidth / 2 - 50, CGRectGetMaxY(self.gidsLabel.frame) + 5, 100, 30)];
//    [self.view addSubview:auth_idLabel];
//    self.auth_idLabel = auth_idLabel;
    
}
- (void)regBtnTouchUpInside:(UIButton *)sender{
    
    _flag = 0;
    
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"图片获取方式" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //相机
        if(![PermissionDetector isCapturePermissionGranted]){
            NSString* info=@"没有相机权限";
            NSLog(@"%@",info);
            return;
        }
        _labelView.text=@"";
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.modalPresentationStyle = UIModalPresentationFullScreen;
            if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]){
                picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            
            picker.mediaTypes = @[(NSString*)kUTTypeImage];
            picker.allowsEditing = NO;//设置可编辑
            picker.delegate = self;
            
            //            [self performSelector:@selector(presentImagePicker:) withObject:picker afterDelay:1.0f];
            [self presentViewController:picker animated:YES completion:nil];
        }else{
            NSLog(@"设备不可用");
        }
        
    }];
    [alertVC addAction:cameraAction];
    
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //相册
        if(![PermissionDetector isAssetsLibraryPermissionGranted]){
            NSString* info=@"没有相册权限";
            //            [self showAlert:info];
            NSLog(@"%@",info);
            return;
        }
        
        //        _backBtn.enabled=NO;
        //        _imgSelectBtn.enabled=NO;
        //        _settingBtn.enabled=NO;
        //        _funcSelectBtn.enabled=NO;
        _labelView.text=@"";
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.modalPresentationStyle = UIModalPresentationCurrentContext;
        if([UIImagePickerController isSourceTypeAvailable: picker.sourceType ]) {
            picker.mediaTypes = @[(NSString*)kUTTypeImage];
            picker.delegate = self;
            picker.allowsEditing = NO;
        }
        [self presentViewController:picker animated:YES completion:nil];
        //        [self performSelector:@selector(presentImagePicker:) withObject:picker afterDelay:1.0f];
    }];
    [alertVC addAction:photoAction];
    alertVC.popoverPresentationController.sourceView = self.view;
    alertVC.popoverPresentationController.sourceRect = sender.frame;
    [self presentViewController:alertVC animated:YES completion:^{
        
    }];
    
    
}
- (void)vefBtnTouchUpInside:(UIButton *)sender{
    
    
    _flag = 1;
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"图片获取方式" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //相机
        if(![PermissionDetector isCapturePermissionGranted]){
            NSString* info=@"没有相机权限";
            NSLog(@"%@",info);
            return;
        }
        _labelView.text=@"";
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.modalPresentationStyle = UIModalPresentationFullScreen;
            if([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]){
                picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            
            picker.mediaTypes = @[(NSString*)kUTTypeImage];
            picker.allowsEditing = NO;//设置可编辑
            picker.delegate = self;
            
            //            [self performSelector:@selector(presentImagePicker:) withObject:picker afterDelay:1.0f];
            [self presentViewController:picker animated:YES completion:nil];
        }else{
            NSLog(@"设备不可用");
        }
        
    }];
    [alertVC addAction:cameraAction];
    
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //相册
        if(![PermissionDetector isAssetsLibraryPermissionGranted]){
            NSString* info=@"没有相册权限";
            //            [self showAlert:info];
            NSLog(@"%@",info);
            return;
        }
        _labelView.text=@"";
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.modalPresentationStyle = UIModalPresentationCurrentContext;
        if([UIImagePickerController isSourceTypeAvailable: picker.sourceType ]) {
            picker.mediaTypes = @[(NSString*)kUTTypeImage];
            picker.delegate = self;
            picker.allowsEditing = NO;
        }
        [self presentViewController:picker animated:YES completion:nil];
        //        [self performSelector:@selector(presentImagePicker:) withObject:picker afterDelay:1.0f];
    }];
    [alertVC addAction:photoAction];
    alertVC.popoverPresentationController.sourceView = self.view;
    alertVC.popoverPresentationController.sourceRect = sender.frame;
    [self presentViewController:alertVC animated:YES completion:^{
        
    }];
    
    
}


- (void)presentImagePicker:(UIImagePickerController* )picker{
    //    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
    //        if(self.popover){
    //            self.popover=nil;
    //        }
    //        self.popover=[[UIPopoverController alloc] initWithContentViewController:picker];
    //        self.popover.delegate=self;
    //        [self.popover presentPopoverFromBarButtonItem: self.imgSelectBtn
    //                             permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    //    }
    //    else
    {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    
    //    if(_imgToUseCoverLayer){
    //        _imgToUseCoverLayer.sublayers=nil;
    //        [_imgToUseCoverLayer removeFromSuperlayer];
    //        _imgToUseCoverLayer=nil;
    //    }
    //
    UIImage* image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
//    if (image) {
//        NSLog(@"ok");
//    }else{
//        NSLog(@"no ok ");
//    }
    
    UIImage* upLoadImage = [[image fixOrientation] compressedImage];//将图片压缩以上传服务器
    self.showImageView.image = upLoadImage;
    
    //压缩图片大小
    NSData* imgData = [upLoadImage compressedData];
    NSLog(@"reg image data length: %lu",(unsigned long)[imgData length]);
    if (_flag == 0) {
        //注册
        [self.iFlySpFaceRequest setParameter:[IFlySpeechConstant FACE_REG] forKey:[IFlySpeechConstant FACE_SST]];
        [self.iFlySpFaceRequest setParameter:USER_APPID forKey:[IFlySpeechConstant APPID]];
        [self.iFlySpFaceRequest setParameter:self.auth_idTextField.text forKey:[IFlySpeechConstant FACE_AUTH_ID]];
        
//        self.auth_idLabel.text = self.auth_idTextField.text ;
        [self.iFlySpFaceRequest setParameter:@"del" forKey:@"property"];
        
        [self.iFlySpFaceRequest sendRequest:imgData];
        
    }else{
        //验证
        [self.iFlySpFaceRequest setParameter:[IFlySpeechConstant FACE_VERIFY] forKey:[IFlySpeechConstant FACE_SST]];
        [self.iFlySpFaceRequest setParameter:USER_APPID forKey:[IFlySpeechConstant APPID]];
        [self.iFlySpFaceRequest setParameter:self.auth_idTextField.text  forKey:@"auth_id"];
        NSUserDefaults* userDefaults=[NSUserDefaults standardUserDefaults];
        NSString* gid = [userDefaults objectForKey:self.auth_idTextField.text];
        
        [self.iFlySpFaceRequest setParameter:gid forKey:[IFlySpeechConstant FACE_GID]];
        [self.iFlySpFaceRequest setParameter:@"2000" forKey:@"wait_time"];
        //  压缩图片大小
        NSData* imgData=[upLoadImage compressedData];
        NSLog(@"verify image data length: %lu",(unsigned long)[imgData length]);
        [self.iFlySpFaceRequest sendRequest:imgData];
        
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Data Parser

-(void)praseRegResult:(NSString*)result{
    NSString *resultInfo = @"";
    NSString *resultInfoForLabel = @"";
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        
        if(dic){
            NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
            NSLog(@"%@",dic);
            
            //注册
            if([strSessionType isEqualToString:KCIFlyFaceResultReg]){
                NSString* rst=[dic objectForKey:KCIFlyFaceResultRST];
                NSString* ret=[dic objectForKey:KCIFlyFaceResultRet];
                if([ret integerValue]!=0){
                    resultInfo=[resultInfo stringByAppendingFormat:@"注册错误\n错误码：%@",ret];
                }else{
                    if(rst && [rst isEqualToString:KCIFlyFaceResultSuccess]){
                        NSString* gid=[dic objectForKey:KCIFlyFaceResultGID];
                        resultInfo=[resultInfo stringByAppendingString:@"检测到人脸\n注册成功！"];
                        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
                        [defaults setObject:gid forKey:self.auth_idTextField.text];
                        resultInfoForLabel=[resultInfoForLabel stringByAppendingFormat:@"gid:%@\n",gid];
//                        self.gids = [self.gids stringByAppendingFormat:@"gid:%@\n",gid];
                        self.gidsLabel.text = resultInfoForLabel;
                        
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"未检测到人脸\n注册失败！"];
                    }
                }
            }
            _labelView.text=resultInfoForLabel;
            _labelView.textColor=[UIColor redColor];
            _labelView.hidden=NO;
            [_activityIndicator stopAnimating];
            [_activityIndicator setHidden:YES];

            [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:resultInfo waitUntilDone:NO];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
    
    
}

-(void)praseVerifyResult:(NSString*)result{
    NSString *resultInfo = @"";
    NSString *resultInfoForLabel = @"";
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        
        if(dic){
            NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
            
            if([strSessionType isEqualToString:KCIFlyFaceResultVerify]){
                NSLog(@"%@",dic);
                
                
                NSString* rst=[dic objectForKey:KCIFlyFaceResultRST];
                NSString* ret=[dic objectForKey:KCIFlyFaceResultRet];
                if([ret integerValue]!=0){
                    resultInfo=[resultInfo stringByAppendingFormat:@"验证错误\n错误码：%@",ret];
                }else{
                    
                    if([rst isEqualToString:KCIFlyFaceResultSuccess]){
                        resultInfo=[resultInfo stringByAppendingString:@"检测到人脸\n"];
                    }else{
                        resultInfo=[resultInfo stringByAppendingString:@"未检测到人脸\n"];
                    }
                    
                    NSString* verf=[dic objectForKey:KCIFlyFaceResultVerf];
                    NSString* score=[dic objectForKey:KCIFlyFaceResultScore];
                    
                    
                    
                    if([verf boolValue]){
                        resultInfoForLabel=[resultInfoForLabel stringByAppendingFormat:@"score:%@\n",score];
                        resultInfo=[resultInfo stringByAppendingString:@"验证结果:验证成功!"];
                    }else{
                        
                        NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
                        NSString* gid=[defaults objectForKey:KCIFlyFaceResultGID];
                        resultInfoForLabel=[resultInfoForLabel stringByAppendingFormat:@"last reg gid:%@\n",gid];
                        resultInfo=[resultInfo stringByAppendingString:@"验证结果:验证失败!"];
                    }
                }
                
            }
            
            _labelView.text=resultInfoForLabel;
            _labelView.textColor=[UIColor redColor];
            _labelView.hidden=NO;
            [_activityIndicator stopAnimating];
            [_activityIndicator setHidden:YES];
            //            _backBtn.enabled=YES;
            //            _imgSelectBtn.enabled=YES;
            //            _settingBtn.enabled=YES;
            //            _funcSelectBtn.enabled=YES;
            
            if([resultInfo length]<1){
                resultInfo=@"结果异常";
            }
            
            [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:resultInfo waitUntilDone:NO];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
        
    }
    
    
}

#pragma mark - Perform results On UI

-(void)updateFaceImage:(NSString*)result{
    
    
    NSLog(@"%@",result);
    NSError* error;
    NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSDictionary* dic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@",dic);
    
    if(dic){
        
        
        NSString* strSessionType=[dic objectForKey:KCIFlyFaceResultSST];
        
        //注册
        if([strSessionType isEqualToString:KCIFlyFaceResultReg]){
            [self praseRegResult:result];
        }
        
        //验证
        if([strSessionType isEqualToString:KCIFlyFaceResultVerify]){
            [self praseVerifyResult:result];
        }
        
        
    }
}

-(void)showResultInfo:(NSString*)resultInfo{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"结果" message:resultInfo delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    alert=nil;
}



#pragma mark - IFlyFaceRequestDelegate


/**
 * 消息回调
 * @param eventType 消息类型
 * @param params 消息数据对象
 */
- (void) onEvent:(int) eventType WithBundle:(NSString*) params{
    NSLog(@"onEvent | params:%@",params);
    
}

/**
 * 数据回调，可能调用多次，也可能一次不调用
 * @param data 服务端返回的二进制数据
 */
- (void) onData:(NSData* )data{
    
    NSLog(@"onData | ");
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"result:%@",result);
    
    if (result) {
//        self.resultStings = @"";
//        self.resultStings=[self.resultStings stringByAppendingString:result];
        self.resultStings = result;
        NSLog(@"self.resultStings:%@",self.resultStings);
        
        
    }
    
}

/**
 * 结束回调，没有错误时，error为null
 * @param error 错误类型
 */
- (void) onCompleted:(IFlySpeechError*) error{
    [_activityIndicator stopAnimating];
    [_activityIndicator setHidden:YES];
    //    _backBtn.enabled=YES;
    //    _imgSelectBtn.enabled=YES;
    //    _settingBtn.enabled=YES;
    //    _funcSelectBtn.enabled=YES;
    NSLog(@"onCompleted | error:%@",[error errorDesc]);
    NSString* errorInfo=[NSString stringWithFormat:@"错误码：%d\n 错误描述：%@",[error errorCode],[error errorDesc]];
    if(0!=[error errorCode]){
        [self performSelectorOnMainThread:@selector(showResultInfo:) withObject:errorInfo waitUntilDone:NO];
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateFaceImage:self.resultStings];
        });
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
