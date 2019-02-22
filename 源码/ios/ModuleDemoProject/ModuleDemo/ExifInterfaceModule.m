//
//  UZModuleDemo.m
//  UZModule
//
//  Created by kenny on 14-3-5.
//  Copyright (c) 2014年 APICloud. All rights reserved.
//

#import "ExifInterfaceModule.h"
#import "UZAppDelegate.h"
#import "NSDictionaryUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

@interface ExifInterfaceModule ()

@end

@implementation ExifInterfaceModule

+ (void)launch {
    //在module.json里面配置的launchClassMethod，必须为类方法，引擎会在应用启动时调用配置的方法，模块可以在其中做一些初始化操作
}

- (id)initWithUZWebView:(UZWebView *)webView_ {
    if (self = [super initWithUZWebView:webView_]) {
        
    }
    return self;
}

- (void)dispose {
    //do clean
}

- (void)setExifInfo:(NSDictionary *)paramDict {
    __block ExifInterfaceModule  *exif= self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger cbId = [paramDict integerValueForKey:@"cbId" defaultValue:-1];
        NSString *picPath = [paramDict stringValueForKey:@"picPath" defaultValue:nil];
        
        if (![picPath isKindOfClass:[NSString class]] || picPath.length<=0) {
            //error
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"处理图片不能为空" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        NSString *extname = [[picPath pathExtension] lowercaseString];
        if(![extname isEqual:@"jpeg"] && ![extname isEqual:@"jpg"]){
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"仅支持jpg和jpeg图片处理!"forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        
        NSString *picpath = [self getPathWithUZSchemeURL:picPath];
        
        UIImage *iamge =[UIImage imageNamed:picpath];
        if(iamge==nil){
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"文件不存在" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        
        NSData *imageData = UIImageJPEGRepresentation(iamge,1.0);
        
        NSString *lattemp = [paramDict stringValueForKey:@"latitude" defaultValue:@"0"];
        NSString *lngtemp = [paramDict stringValueForKey:@"longitude" defaultValue:@"0"];
        
        CGFloat latlon  = [lattemp doubleValue];
        CGFloat longi  = [lngtemp doubleValue];
        
        CGImageSourceRef source =CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        NSDictionary *dict = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
        
        NSMutableDictionary *metaDataDic = [dict mutableCopy];
        
        //GPS
        NSMutableDictionary *gpsDic =[NSMutableDictionary dictionary];
        if(latlon>0){
            [gpsDic setObject:@"N"forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        }else{
            [gpsDic setObject:@"S"forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        }
        [gpsDic setObject:[NSNumber numberWithDouble:fabs(latlon)] forKey:(NSString*)kCGImagePropertyGPSLatitude];
        
        if(longi>0){
            [gpsDic setObject:@"E"forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        }else{
            [gpsDic setObject:@"W"forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        }
        [gpsDic setObject:[NSNumber numberWithDouble:fabs(longi)] forKey:(NSString *)kCGImagePropertyGPSLongitude];
        
        [metaDataDic setObject:gpsDic forKey:(NSString*)kCGImagePropertyGPSDictionary];
        
        //写进图片
        CFStringRef UTI = CGImageSourceGetType(source);
        NSMutableData *data1 = [NSMutableData data];
        CGImageDestinationRef destination =CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data1, UTI, 1,NULL);
        if(!destination)
        {
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"写入文件失败" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metaDataDic);
        if(!CGImageDestinationFinalize(destination))
        {
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"写入文件失败" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        //获取cache目录
        NSString *cache = [self getPathWithUZSchemeURL:@"cache://"];
        
        NSString *overpath = [NSString stringWithFormat:@"%@/%@",cache,[picPath lastPathComponent]];
        [data1 writeToFile:overpath atomically:YES];
        NSLog(@"保存成功！path = %@",overpath);
        
        CFRelease(destination);
        CFRelease(source);
        
        NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"status"];
        [ret setObject:overpath forKey:@"newPicPath"];
        
        //获取保存后的gps数据
        id gpslatitude = 0;
        id gpslongitude = 0;
        NSURL *url2 = [NSURL fileURLWithPath:overpath];
        CGImageSourceRef source2 =CGImageSourceCreateWithURL((__bridge CFURLRef)url2, NULL);
        if(source2){
            NSDictionary *dd2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(NSString*)kCGImageSourceShouldCache, nil];
            CFDictionaryRef dict =CGImageSourceCopyPropertiesAtIndex(source2, 0, (__bridge CFDictionaryRef)dd2);
            if(dict)
            {
                //获得GPS 的 dictionary
                CFDictionaryRef gps =CFDictionaryGetValue(dict, kCGImagePropertyGPSDictionary);
                if(gps)
                {
                    NSString *gpslatref = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
                    NSString *t1 = [NSString stringWithString:gpslatref];
                    
                    
                    NSString *gpslonref = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
                    NSString *t2 = [NSString stringWithString:gpslonref];
                    
                    
                    //获取经纬度
                    NSString *gpslatitude1 = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
                    
                    if (gpslatitude1!=nil && [gpslatitude1 isKindOfClass:[NSNumber class]]) {
                        if([@"S" isEqualToString:t1]){
                            NSString *temp = [NSString stringWithFormat:@"%@%@",@"-",gpslatitude1.description];
                            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                            id result = [f numberFromString:temp];
                            if(result) gpslatitude = result;
                        }else{
                            gpslatitude = gpslatitude1;
                        }
                    }
                    
                    NSString *gpslongitude1 = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
                    
                    if (gpslongitude1!=nil && [gpslongitude1 isKindOfClass:[NSNumber class]]) {
                        if([@"W" isEqualToString:t2]){
                            NSString *temp = [NSString stringWithFormat:@"%@%@",@"-",gpslongitude1.description];
                            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                            id result = [f numberFromString:temp];
                            if(result) gpslongitude = result;
                        }else{
                            gpslongitude = gpslongitude1;
                        }
                    }
                }
                
                CFRelease(gps);
            }
        }
        
        [ret setObject:gpslatitude forKey:@"latitude"];
        [ret setObject:gpslongitude forKey:@"longitude"];
        
        //end
        
        [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:YES];
    });
}


- (void)getExifInfo:(NSDictionary *)paramDict {
    
    __block ExifInterfaceModule  *exif= self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSInteger cbId = [paramDict integerValueForKey:@"cbId" defaultValue:-1];
        NSString *picPath = [paramDict stringValueForKey:@"picPath" defaultValue:nil];
        
        if (![picPath isKindOfClass:[NSString class]] || picPath.length<=0) {
            //error
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"处理图片不能为空" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        NSString *extname = [[picPath pathExtension] lowercaseString];
        if(![extname isEqual:@"jpeg"] && ![extname isEqual:@"jpg"]){
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"仅支持jpg和jpeg图片处理!"forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        
        NSString *picpath1 = [self getPathWithUZSchemeURL:picPath];
        
        UIImage *iamge =[UIImage imageNamed:picpath1];
        if(iamge==nil){
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"文件不存在" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        
        NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"status"];
        
        id gpslatitude = 0;
        id gpslongitude = 0;
        //获取保存后的gps数据
        NSURL *url2 = [NSURL fileURLWithPath:picpath1];
        CGImageSourceRef source2 =CGImageSourceCreateWithURL((__bridge CFURLRef)url2, NULL);
        if(source2){
            NSDictionary *dd2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(NSString*)kCGImageSourceShouldCache, nil];
            CFDictionaryRef dict =CGImageSourceCopyPropertiesAtIndex(source2, 0, (__bridge CFDictionaryRef)dd2);
            if(dict)
            {
                //获得GPS 的 dictionary
                CFDictionaryRef gps =CFDictionaryGetValue(dict, kCGImagePropertyGPSDictionary);
                if(gps)
                {
                    NSString *gpslatref = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
                    NSString *t1 = [NSString stringWithString:gpslatref];
                    
                    
                    NSString *gpslonref = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
                    NSString *t2 = [NSString stringWithString:gpslonref];
                    
                    
                    //获取经纬度
                    NSString *gpslatitude1 = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
                    
                    if (gpslatitude1!=nil && [gpslatitude1 isKindOfClass:[NSNumber class]]) {
                        if([@"S" isEqualToString:t1]){
                            NSString *temp = [NSString stringWithFormat:@"%@%@",@"-",gpslatitude1.description];
                            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                            id result = [f numberFromString:temp];
                            if(result) gpslatitude = result;
                        }else{
                            gpslatitude = gpslatitude1;
                        }
                    }
                    
                    NSString *gpslongitude1 = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
                    
                    if (gpslongitude1!=nil && [gpslongitude1 isKindOfClass:[NSNumber class]]) {
                        if([@"W" isEqualToString:t2]){
                            NSString *temp = [NSString stringWithFormat:@"%@%@",@"-",gpslongitude1.description];
                            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                            id result = [f numberFromString:temp];
                            if(result) gpslongitude = result;
                        }else{
                            gpslongitude = gpslongitude1;
                        }
                    }
                    
                    CFRelease(gps);
                }
            }
        }
        CFRelease(source2);
        
        if(gpslatitude==nil){
            gpslatitude = [NSString stringWithFormat:@"0"];
        }
        if(gpslongitude==nil){
            gpslongitude = [NSString stringWithFormat:@"0"];
        }
        [ret setObject:gpslatitude forKey:@"latitude"];
        [ret setObject:gpslongitude forKey:@"longitude"];
        //end
        
        [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:YES];
        
    });
}

    
- (void)setDegreeExif:(NSDictionary *)paramDict {
    __block ExifInterfaceModule  *exif= self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSInteger cbId = [paramDict integerValueForKey:@"cbId" defaultValue:-1];
        NSString *picPath = [paramDict stringValueForKey:@"picPath" defaultValue:nil];
        NSInteger degrees = [paramDict integerValueForKey:@"degrees" defaultValue:0];
        
        if (![picPath isKindOfClass:[NSString class]] || picPath.length<=0) {
            //error
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"处理图片不能为空" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        NSString *extname = [[picPath pathExtension] lowercaseString];
        if(![extname isEqual:@"jpeg"] && ![extname isEqual:@"jpg"]){
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"仅支持jpg和jpeg图片处理!"forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        
        NSString *picpath = [self getPathWithUZSchemeURL:picPath];
        
        UIImage *iamge =[UIImage imageNamed:picpath];
        if(iamge==nil){
            NSDictionary *ret = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            NSMutableDictionary * errdict = [NSMutableDictionary dictionaryWithObject:@"文件不存在" forKey:@"msg"];
            
            [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:errdict doDelete:YES];
            return;
        }
        
        //获取原有图片中的gps属性数据
        
        id gpslatitude = 0;
        id gpslongitude = 0;
        //获取保存后的gps数据
        NSURL *url2 = [NSURL fileURLWithPath:picpath];
        CGImageSourceRef source2 =CGImageSourceCreateWithURL((__bridge CFURLRef)url2, NULL);
        if(source2){
            NSDictionary *dd2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],(NSString*)kCGImageSourceShouldCache, nil];
            CFDictionaryRef dict =CGImageSourceCopyPropertiesAtIndex(source2, 0, (__bridge CFDictionaryRef)dd2);
            if(dict)
            {
                //获得GPS 的 dictionary
                CFDictionaryRef gps =CFDictionaryGetValue(dict, kCGImagePropertyGPSDictionary);
                if(gps)
                {
                    NSString *gpslatref = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
                    NSString *t1 = [NSString stringWithString:gpslatref];
                    
                    
                    NSString *gpslonref = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
                    NSString *t2 = [NSString stringWithString:gpslonref];
                    
                    
                    //获取经纬度
                    NSString *gpslatitude1 = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
                    
                    if (gpslatitude1!=nil && [gpslatitude1 isKindOfClass:[NSNumber class]]) {
                        if([@"S" isEqualToString:t1]){
                            NSString *temp = [NSString stringWithFormat:@"%@%@",@"-",gpslatitude1.description];
                            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                            id result = [f numberFromString:temp];
                            if(result) gpslatitude = result;
                        }else{
                            gpslatitude = gpslatitude1;
                        }
                    }
                    
                    NSString *gpslongitude1 = (__bridge NSString*)CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
                    
                    if (gpslongitude1!=nil && [gpslongitude1 isKindOfClass:[NSNumber class]]) {
                        if([@"W" isEqualToString:t2]){
                            NSString *temp = [NSString stringWithFormat:@"%@%@",@"-",gpslongitude1.description];
                            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                            id result = [f numberFromString:temp];
                            if(result) gpslongitude = result;
                        }else{
                            gpslongitude = gpslongitude1;
                        }
                    }
                    
                    CFRelease(gps);
                }
            }
        }
        CFRelease(source2);
        //end
        
        UIImageOrientation orientation = UIImageOrientationUp;
        if(degrees==90){
            orientation = UIImageOrientationLeft;
        }else if(degrees==180){
            orientation = UIImageOrientationDown;
        }else if(degrees==270){
            orientation = UIImageOrientationRight;
        }else{
            orientation = UIImageOrientationUp;
        }
        
        UIImage *newimage = [self image:iamge rotation:orientation];
        
        //将gps数据重新写入
        NSData *imageData = UIImageJPEGRepresentation(newimage,1.0);
        
        CGFloat latlon  = [gpslatitude doubleValue];
        CGFloat longi  = [gpslongitude doubleValue];
        
        CGImageSourceRef source =CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        NSDictionary *dict = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
        
        NSMutableDictionary *metaDataDic = [dict mutableCopy];
        
        //GPS
        NSMutableDictionary *gpsDic =[NSMutableDictionary dictionary];
        if(latlon>0){
            [gpsDic setObject:@"N"forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        }else{
            [gpsDic setObject:@"S"forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        }
        [gpsDic setObject:[NSNumber numberWithDouble:fabs(latlon)] forKey:(NSString*)kCGImagePropertyGPSLatitude];
        
        if(longi>0){
            [gpsDic setObject:@"E"forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        }else{
            [gpsDic setObject:@"W"forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        }
        [gpsDic setObject:[NSNumber numberWithDouble:fabs(longi)] forKey:(NSString *)kCGImagePropertyGPSLongitude];
        
        [metaDataDic setObject:gpsDic forKey:(NSString*)kCGImagePropertyGPSDictionary];
        
        //写进图片
        CFStringRef UTI = CGImageSourceGetType(source);
        NSMutableData *data1 = [NSMutableData data];
        CGImageDestinationRef destination =CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data1, UTI, 1,NULL);
        if(!destination)
        { }
        
        CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metaDataDic);
        if(!CGImageDestinationFinalize(destination))
        { }
        
        //end
        
        
        //获取cache目录
        NSString *cache = [self getPathWithUZSchemeURL:@"cache://"];
        
        NSString *overpath = [NSString stringWithFormat:@"%@/%@",cache,[picPath lastPathComponent]];
        [data1 writeToFile:overpath atomically:YES];
        NSLog(@"保存成功！path = %@",overpath);
        
        CFRelease(destination);
        CFRelease(source);
        
        NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"status"];
        [ret setObject:overpath forKey:@"newPicPath"];
        //end
        
        [exif sendResultEventWithCallbackId:cbId dataDict:ret errDict:nil doDelete:YES];
        
    });
}
    
    
    
- (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
    {
        long double rotate = 0.0;
        CGRect rect;
        float translateX = 0;
        float translateY = 0;
        float scaleX = 1.0;
        float scaleY = 1.0;
        
        switch (orientation) {
            case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
            case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
            case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
            default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
        }
        
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        //做CTM变换
        CGContextTranslateCTM(context, 0.0, rect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextRotateCTM(context, rotate);
        CGContextTranslateCTM(context, translateX, translateY);
        
        CGContextScaleCTM(context, scaleX, scaleY);
        //绘制图片
        CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
        
        UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
        
        return newPic;
    }
    
@end
