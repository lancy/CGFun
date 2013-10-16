//
//  CGFunTests.m
//  CGFunTests
//
//  Created by Lancy on 15/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CYImageManager.h"

@interface CGFunTests : XCTestCase


@end

@implementation CGFunTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testExample
{
    CGFloat h;
    CGFloat s;
    CGFloat b;
    [CYImageManager red:120 green:132 blue:111 toHue:&h saturation:&s brightness:&b];
    NSLog(@"%f,%f,%f", h, s, b);
    
}

@end
