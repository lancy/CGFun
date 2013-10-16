//
//  CYImageManager.h
//  CGFun
//
//  Created by Lancy on 15/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYImageManager : NSObject

- (instancetype)initWithImage:(UIImage *)image;
- (UIImage *)floodFillAtPoint:(CGPoint)point; 

@end
