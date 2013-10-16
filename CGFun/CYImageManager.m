//
//  CYImageManager.m
//  CGFun
//
//  Created by Lancy on 15/10/13.
//  Copyright (c) 2013 GraceLancy. All rights reserved.
//

#import "CYImageManager.h"

@implementation CYImageManager {
    BOOL *_flagPixel;
    UIImage *_image;
}

const int RED = 0;
const int GREEN = 1;
const int BLUE = 2;
const int ALPHA = 3;

static CGPoint offset[4] = {
    {-1, 0},
    {0, -1},
    {1, 0},
    {0, 1}
};

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _image = image;
    }
    return self;
}

- (UIImage *)floodFillAtPoint:(CGPoint)point; 
{
    CGImageRef originImageRef = _image.CGImage;
    CGRect imageRect = CGRectMake(0, 0, _image.size.width * _image.scale, _image.size.height * _image.scale);
    NSInteger width = imageRect.size.width;
    NSInteger height = imageRect.size.height;
    
    // pixels is the raw data in context
    UInt32 *pixels = (UInt32 *)malloc(width * height * sizeof(UInt32));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(UInt32), colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, imageRect, originImageRef);
    
    
    // get the point color
    NSInteger pointX = point.x;
    NSInteger pointY = point.y;
    NSInteger pointIndex = pointY * width + pointX;
    UInt8 *pointRgbaPixel = (UInt8 *)&pixels[pointIndex];
    
    // fist traversal, calc the color different
    if (_flagPixel == NULL) {
        _flagPixel = calloc(width * height, sizeof(BOOL));
    }
    BOOL *visitedPixel = calloc(width * height, sizeof(BOOL));
    NSInteger *deque = malloc(width * height * sizeof(NSInteger));
    NSInteger head = 0;
    NSInteger tail = 1;
    deque[head] = pointIndex;
    visitedPixel[pointIndex] = YES;
    _flagPixel[pointIndex] = YES;
    while (head < tail) {
        NSInteger currentPixelIndex = deque[head];
        NSInteger currentY = currentPixelIndex / width;
        NSInteger currentX = currentPixelIndex % width;
        for (NSInteger i = 0; i < 4; i++) {
            NSInteger nextY = currentY + offset[i].y;
            NSInteger nextX = currentX + offset[i].x;
            if (0 <= nextX && nextX < width
                && 0 <= nextY && nextY < height) {
                NSInteger nextIndex = nextY * width + nextX;
                BOOL isNextVisited = visitedPixel[nextIndex];
                BOOL isFlag = _flagPixel[nextIndex];
                if (!isNextVisited && !isFlag) {
                    visitedPixel[nextIndex] = YES;
                    UInt8 *rgbaPixel = (UInt8 *)&pixels[nextIndex];
                    CGFloat colorDifferent = [CYImageManager colorDifferentBetweenRGBAPixel:pointRgbaPixel andRGBAPixel:rgbaPixel withTolerance:0.3];
                    if (colorDifferent != -1) {
                        _flagPixel[nextIndex] = YES;
                        deque[tail] = nextIndex;
                        tail++;
                    }
                }
            }
        }
        head++;
    }
    
    // second traversal, clean up the smaller pixel block.
    memset(visitedPixel, 0, width * height * sizeof(BOOL));
    NSInteger maxNumberOfPixelBlock = 0;
    NSInteger *pixelsOfMaxBlock = malloc(width * height * sizeof(NSInteger));
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            BOOL isVisited = visitedPixel[y * width + x];
            BOOL isFlag = _flagPixel[y * width + x];
            
            // if it's not visited and is not flag, begin floor fill, calc the number of the pixels
            if (!isVisited & !isFlag) {
                // init data
                NSInteger head = 0;
                NSInteger tail = 0;
                // insert state pixel
                deque[head] = y * width + x;
                visitedPixel[y * width + x] = YES;
                tail = 1;
                while (head < tail) {
                    NSInteger currentPixelIndex = deque[head];
                    NSInteger currentY = currentPixelIndex / width;
                    NSInteger currentX = currentPixelIndex % width;
                    for (NSInteger i = 0; i < 4; i++) {
                        NSInteger nextY = currentY + offset[i].y;
                        NSInteger nextX = currentX + offset[i].x;
                        if (0 <= nextX && nextX < width
                            && 0 <= nextY && nextY < height) {
                            NSInteger nextIndex = nextY * width + nextX;
                            BOOL isNextVisited = visitedPixel[nextIndex];
                            BOOL isNextFlag = _flagPixel[nextIndex];
                            if (!isNextVisited && !isNextFlag) {
                                visitedPixel[nextIndex] = YES;
                                deque[tail] = nextIndex;
                                tail++;
                            }
                        }
                    }
                    head++;
                }
                
                if (tail < maxNumberOfPixelBlock) {
                    for (NSInteger i = 0; i < tail; i++) {
                        NSInteger currentPixelIndex = deque[i];
                        _flagPixel[currentPixelIndex] = YES;
                    }
                } else {
                    for (NSInteger i = 0; i < maxNumberOfPixelBlock; i++) {
                        NSInteger currentPixelIndex = pixelsOfMaxBlock[i];
                        _flagPixel[currentPixelIndex] = YES;
                    }
                    maxNumberOfPixelBlock = tail;
                    memcpy(pixelsOfMaxBlock, deque, maxNumberOfPixelBlock * sizeof(NSInteger));
                }
            }
        }
    }
    free(pixelsOfMaxBlock);
    free(deque);
    free(visitedPixel);
    
    // third traversal, make flag pixels blue
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            BOOL isFlag = _flagPixel[y * width + x];
            if (isFlag) {
                UInt8 *rgbaPixel = (UInt8 *)&pixels[y * width + x];
                rgbaPixel[RED] = 0;
                rgbaPixel[GREEN] = 0;
                rgbaPixel[BLUE] = 0;
                rgbaPixel[ALPHA] = 0;
            }
        }
    }
    
    // create a new CGImageRef
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    UIImage *processedImage = [UIImage imageWithCGImage:image scale:_image.scale orientation:UIImageOrientationUp];
    _image = processedImage;
    CGImageRelease(image);
    return processedImage;
}

/// http://read.pudn.com/downloads123/doc/523014/一种基于HSV空间的颜色相似度计算方法.pdf
+ (CGFloat)colorDifferentBetweenRGBAPixel:(UInt8 *)pixel0 andRGBAPixel:(UInt8 *)pixel1 withTolerance:(CGFloat)tolerance
{
    CGFloat colorDifferent = 0;
    CGFloat r0, g0, b0;
    CGFloat r1, g1, b1;
    CGFloat h0, s0, v0;
    CGFloat h1, s1, v1;
    
    r0 = pixel0[RED];
    g0 = pixel0[GREEN];
    b0 = pixel0[BLUE];
    
    r1 = pixel1[RED];
    g1 = pixel1[GREEN];
    b1 = pixel1[BLUE];
    
    RGB2HSL(r0, g0, b0, &h0, &s0, &v0);
    RGB2HSL(r1, g1, b1, &h1, &s1, &v1);
    
    CGFloat colorDistance = [self colorDistanceBetweenH:h0 S:s0 V:v0
                                                   andH:h1 S:s1 V:v1];
    if (colorDistance > tolerance) {
        colorDifferent = -1;
    } else {
        colorDifferent = colorDistance;
    }
    return colorDifferent;
}

+ (CGFloat)colorDistanceBetweenH:(CGFloat)h0 S:(CGFloat)s0 V:(CGFloat)v0
                            andH:(CGFloat)h1 S:(CGFloat)s1 V:(CGFloat)v1
{
    CGFloat colorDistance = sqrt(pow(h0 - h1, 2) + pow(s0 - s1, 2) + pow(v0 - v1, 2));
    return colorDistance;
}

+ (void)hue:(CGFloat)h saturation:(CGFloat)s brightness:(CGFloat)v toRed:(CGFloat *)pR green:(CGFloat *)pG blue:(CGFloat *)pB
{
	CGFloat r,g,b;
    
	// From Foley and Van Dam
    
	if (s == 0.0f) {
		// Achromatic color: there is no hue
		r = g = b = v;
	} else {
		// Chromatic color: there is a hue
		if (h == 360.0f) h = 0.0f;
		h /= 60.0f;										// h is now in [0, 6)
        
		int i = floorf(h);								// largest integer <= h
		CGFloat f = h - i;								// fractional part of h
		CGFloat p = v * (1 - s);
		CGFloat q = v * (1 - (s * f));
		CGFloat t = v * (1 - (s * (1 - f)));
        
		switch (i) {
			case 0:	r = v; g = t; b = p;	break;
			case 1:	r = q; g = v; b = p;	break;
			case 2:	r = p; g = v; b = t;	break;
			case 3:	r = p; g = q; b = v;	break;
			case 4:	r = t; g = p; b = v;	break;
			case 5:	r = v; g = p; b = q;	break;
		}
	}
    
	if (pR) *pR = r;
	if (pG) *pG = g;
	if (pB) *pB = b;
}


+ (void)red:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b toHue:(CGFloat *)pH saturation:(CGFloat *)pS brightness:(CGFloat *)pV
{
	CGFloat h,s,v;
    
	// From Foley and Van Dam
    
	CGFloat max = MAX(r, MAX(g, b));
	CGFloat min = MIN(r, MIN(g, b));
    
	// Brightness
	v = max;
    
	// Saturation
	s = (max != 0.0f) ? ((max - min) / max) : 0.0f;
    
	if (s == 0.0f) {
		// No saturation, so undefined hue
		h = 0.0f;
	} else {
		// Determine hue
		CGFloat rc = (max - r) / (max - min);		// Distance of color from red
		CGFloat gc = (max - g) / (max - min);		// Distance of color from green
		CGFloat bc = (max - b) / (max - min);		// Distance of color from blue
        
		if (r == max) h = bc - gc;					// resulting color between yellow and magenta
		else if (g == max) h = 2 + rc - bc;			// resulting color between cyan and yellow
		else /* if (b == max) */ h = 4 + gc - rc;	// resulting color between magenta and cyan
        
		h *= 60.0f;									// Convert to degrees
		if (h < 0.0f) h += 360.0f;					// Make non-negative
	}
    
	if (pH) *pH = h;
	if (pS) *pS = s;
	if (pV) *pV = v;
}

static void HSL2RGB(float h, float s, float l, float* outR, float* outG, float* outB)
{
	float			temp1,
    temp2;
	float			temp[3];
	int				i;
    
	// Check for saturation. If there isn't any just return the luminance value for each, which results in gray.
	if(s == 0.0) {
		if(outR)
			*outR = l;
		if(outG)
			*outG = l;
		if(outB)
			*outB = l;
		return;
	}
    
	// Test for luminance and compute temporary values based on luminance and saturation
	if(l < 0.5)
		temp2 = l * (1.0 + s);
	else
		temp2 = l + s - l * s;
    temp1 = 2.0 * l - temp2;
    
	// Compute intermediate values based on hue
	temp[0] = h + 1.0 / 3.0;
	temp[1] = h;
	temp[2] = h - 1.0 / 3.0;
    
	for(i = 0; i < 3; ++i) {
        
		// Adjust the range
		if(temp[i] < 0.0)
			temp[i] += 1.0;
		if(temp[i] > 1.0)
			temp[i] -= 1.0;
        
        
		if(6.0 * temp[i] < 1.0)
			temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
		else {
			if(2.0 * temp[i] < 1.0)
				temp[i] = temp2;
			else {
				if(3.0 * temp[i] < 2.0)
					temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
				else
					temp[i] = temp1;
			}
		}
	}
    
	// Assign temporary values to R, G, B
	if(outR)
		*outR = temp[0];
	if(outG)
		*outG = temp[1];
	if(outB)
		*outB = temp[2];
}


static void RGB2HSL(float r, float g, float b, float* outH, float* outS, float* outL)
{
    r = r/255.0f;
    g = g/255.0f;
    b = b/255.0f;
    
    
    float h,s, l, v, m, vm, r2, g2, b2;
    
    h = 0;
    s = 0;
    l = 0;
    
    v = MAX(r, g);
    v = MAX(v, b);
    m = MIN(r, g);
    m = MIN(m, b);
    
    l = (m+v)/2.0f;
    
    if (l <= 0.0){
        if(outH)
			*outH = h;
		if(outS)
			*outS = s;
		if(outL)
			*outL = l;
        return;
    }
    
    vm = v - m;
    s = vm;
    
    if (s > 0.0f){
        s/= (l <= 0.5f) ? (v + m) : (2.0 - v - m);
    }else{
        if(outH)
			*outH = h;
		if(outS)
			*outS = s;
		if(outL)
			*outL = l;
        return;
    }
    
    r2 = (v - r)/vm;
    g2 = (v - g)/vm;
    b2 = (v - b)/vm;
    
    if (r == v){
        h = (g == m ? 5.0f + b2 : 1.0f - g2);
    }else if (g == v){
        h = (b == m ? 1.0f + r2 : 3.0 - b2);
    }else{
        h = (r == m ? 3.0f + g2 : 5.0f - r2);
    }
    
    h/=6.0f;
    
    if(outH)
        *outH = h;
    if(outS)
        *outS = s;
    if(outL)
        *outL = l;
    
}
@end
