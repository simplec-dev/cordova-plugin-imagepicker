//
//  CTPicker.m
//
//  Created by Christopher Sullivan on 10/25/13.
//  Updated by Jeduan Cornejo on 07/06/15
//

#import "CTPicker.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

@interface CTPicker ()

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize;
@property (copy) NSString* callbackId;

@end

@implementation CTPicker

@synthesize callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command {
	NSDictionary *options = [command.arguments objectAtIndex: 0];

	NSInteger maxImages = [options[@"maxImages"] integerValue];
    NSInteger minImages = [options[@"minImages"] integerValue];
    self.width = [options[@"width"] integerValue];
	self.height = [options[@"height"] integerValue];
	self.quality = [options[@"quality"] integerValue];
    NSString *mediaType = (NSString *)options[@"mediaType"];

	// Create the an album controller and image picker
    QBImagePickerController *imagePicker = [[QBImagePickerController alloc] init];

    imagePicker.allowsMultipleSelection = (maxImages >= 2);
    imagePicker.showsNumberOfSelectedAssets = YES;
    imagePicker.maximumNumberOfSelection = maxImages;
    imagePicker.minimumNumberOfSelection = minImages;

    if ([mediaType isEqualToString:@"image"]) {
        imagePicker.mediaType = QBImagePickerMediaTypeImage;
    } else if ([mediaType isEqualToString:@"video"]) {
        imagePicker.mediaType = QBImagePickerMediaTypeVideo;
    } else {
        imagePicker.mediaType = QBImagePickerMediaTypeAny;
    }

    imagePicker.delegate = self;

	self.callbackId = command.callbackId;
	[self.viewController presentViewController:imagePicker animated:YES completion:NULL];
}

#pragma mark - QBImagePickerControllerDelegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    NSLog(@"Selected assets:");
    NSLog(@"%@", assets);
    
    [self.viewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"Canceled.");
    
    [self.viewController dismissViewControllerAnimated:YES completion:NULL];
}


//- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
//	CDVPluginResult* result = nil;
//	NSMutableArray *resultStrings = [[NSMutableArray alloc] init];
//    NSData* data = nil;
//    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
//    NSError* err = nil;
//    NSFileManager* fileMgr = [[NSFileManager alloc] init];
//    NSString* filePath;
//    ALAsset* asset = nil;
//    UIImageOrientation orientation = UIImageOrientationUp;;
//    CGSize targetSize = CGSizeMake(self.width, self.height);
//	for (NSDictionary *dict in info) {
//        asset = [dict objectForKey:@"ALAsset"];
//        // From ELCImagePickerController.m
//
//        int i = 1;
//        do {
//            filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, i++, @"jpg"];
//        } while ([fileMgr fileExistsAtPath:filePath]);
//
//        @autoreleasepool {
//            ALAssetRepresentation *assetRep = [asset defaultRepresentation];
//            CGImageRef imgRef = NULL;
//
//            //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
//            //so use UIImageOrientationUp when creating our image below.
//            if (picker.returnsOriginalImage) {
//                imgRef = [assetRep fullResolutionImage];
//                orientation = [assetRep orientation];
//            } else {
//                imgRef = [assetRep fullScreenImage];
//            }
//
//            UIImage* image = [UIImage imageWithCGImage:imgRef scale:1.0f orientation:orientation];
//            if (self.width == 0 && self.height == 0) {
//                data = UIImageJPEGRepresentation(image, self.quality/100.0f);
//            } else {
//                UIImage* scaledImage = [self imageByScalingNotCroppingForSize:image toSize:targetSize];
//                data = UIImageJPEGRepresentation(scaledImage, self.quality/100.0f);
//            }
//
//            if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
//                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
//                break;
//            } else {
//                [resultStrings addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
//            }
//        }
//
//	}
//
//	if (nil == result) {
//		result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultStrings];
//	}
//
//	[self.viewController dismissViewControllerAnimated:YES completion:nil];
//	[self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
//}
//
//- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
//	[self.viewController dismissViewControllerAnimated:YES completion:nil];
//	CDVPluginResult* pluginResult = nil;
//    NSArray* emptyArray = [NSArray array];
//	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:emptyArray];
//	[self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
//}

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;

    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor == 0.0) {
            scaleFactor = heightFactor;
        } else if (heightFactor == 0.0) {
            scaleFactor = widthFactor;
        } else if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(width * scaleFactor, height * scaleFactor);
    }

    UIGraphicsBeginImageContext(scaledSize); // this will resize

    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }

    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

@end
