//
//  CYViewController.m
//  CGFun
//
//  Created by Lancy on 15/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import "CYViewController.h"
#import "CYImageManager.h"
#import "UIImageView+GeometryConversion.h"

@interface CYViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) CYImageManager *imageManager;
@property (strong, nonatomic) UIImage *originImage;
@end

@implementation CYViewController
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapImageView:)];
    [self.imageView addGestureRecognizer:tapRecognizer];
    [self.imageView setUserInteractionEnabled:YES];
}

- (void)handleTapImageView:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:self.view];
        CGPoint pointInImage = [self.imageView convertPointFromView:location];
        UIImage *processedImage = [self.imageManager floodFillAtPoint:pointInImage];
        [self.imageView setImage:processedImage];
    }
}
- (IBAction)didTapOriginImageButton:(id)sender {
    [self.imageView setImage:self.originImage];
    self.imageManager = [[CYImageManager alloc] initWithImage:self.originImage];
}

- (IBAction)didTapPickImageButton:(id)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originImage = info[UIImagePickerControllerOriginalImage];
    self.originImage = originImage;
    self.imageManager = [[CYImageManager alloc] initWithImage:self.originImage];
    [self.imageView setImage:originImage];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
