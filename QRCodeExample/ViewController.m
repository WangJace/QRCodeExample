//
//  ViewController.m
//  QRCodeExample
//
//  Created by 王傲云 on 16/4/25.
//  Copyright © 2016年 王傲云. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+MDQRCode.h"

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UITextFieldDelegate>
{
    NSTimer *_lineTimer;
    CALayer *_scanLineLayer;
    NSString *qrStr;
}
@property (weak, nonatomic) IBOutlet UIView *qrBackgroundView;
@property (weak, nonatomic) IBOutlet UITextView *qrStrTextView;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
//捕捉会话
@property (strong, nonatomic) AVCaptureSession *captureSession;
//展示layer
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!_captureSession) {
        //1.初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error;
        //2.用captureDevice创建输入流
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        if (!input) {
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
        //3.创建媒体数据输出流
        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        //4.实例化捕捉会话
        _captureSession = [[AVCaptureSession alloc] init];
        //4.1.将输入流添加到会话
        [_captureSession addInput:input];
        //4.2.将媒体输出流添加到会话中
        [_captureSession addOutput:output];
        //5.创建串行队列，并加媒体输出流添加到队列当中
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("myQueue", nil);
        //5.1.设置代理
        [output setMetadataObjectsDelegate:self queue:dispatchQueue];
        //5.2.设置输出媒体数据类型为QRCode
        [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
        //6.实例化预览图层
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        //7.设置预览图层填充方式
        [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        //8.设置图层的frame
        [_videoPreviewLayer setFrame:_qrBackgroundView.layer.bounds];
        //9.将图层添加到预览view的图层上
        [_qrBackgroundView.layer addSublayer:_videoPreviewLayer];
        //10.设置扫描范围
        output.rectOfInterest = CGRectMake(0.2, 0.2, 0.8, 0.8);
    }
    
}

- (void)moveLineLayer
{
    CGRect frame = _scanLineLayer.frame;
    CGFloat y;
    static BOOL flag = YES;
    if (frame.origin.y <= CGRectGetHeight(_qrBackgroundView.frame) && frame.origin.y >= 0 && flag) {
        y = frame.origin.y+5;
    }
    else {
        flag = NO;
        y = frame.origin.y - 5;
        if (y < 5) {
            y = 0;
            flag = YES;
        }
    }
    [UIView animateWithDuration:0.01 animations:^{
        _scanLineLayer.frame = CGRectMake(0, y, CGRectGetWidth(frame), 1);
    }];
}
- (IBAction)startScanAction:(UIButton *)sender {
    if (![_captureSession isRunning]) {
        [_captureSession startRunning];
        [self setAnimation];
    }
}

- (IBAction)stopScanAction:(UIButton *)sender {
    if ([_captureSession isRunning]) {
        //停止扫描
        [_captureSession stopRunning];
        [_lineTimer invalidate];
        _lineTimer = nil;
        [_scanLineLayer removeFromSuperlayer];
        _scanLineLayer = nil;
    }
}

- (IBAction)generalQRImageAction:(UIButton *)sender {
    _qrImageView.image = [UIImage mdQRCodeForString:_urlTextField.text size:CGRectGetWidth(_qrImageView.frame) fillColor:[UIColor grayColor]];
}

- (void)setAnimation
{
    if (!_scanLineLayer) {
        _scanLineLayer = [[CALayer alloc] init];
        _scanLineLayer.frame = CGRectMake(0, 0, CGRectGetWidth(_qrBackgroundView.frame), 1);
        _scanLineLayer.backgroundColor = [UIColor greenColor].CGColor;
        [_qrBackgroundView.layer addSublayer:_scanLineLayer];
    }
    
    if (!_lineTimer) {
        _lineTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(moveLineLayer) userInfo:nil repeats:YES];
        [_lineTimer fire];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadateObj = [metadataObjects firstObject];
        if ([[metadateObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            //二维码对应的字符串
            _qrStrTextView.text = [metadateObj stringValue];
            //停止扫描
            [_captureSession stopRunning];
            [_lineTimer invalidate];
            _lineTimer = nil;
            [_scanLineLayer removeFromSuperlayer];
            _scanLineLayer = nil;
        }
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([_urlTextField isFirstResponder]) {
        [_urlTextField resignFirstResponder];
    }
}

@end
