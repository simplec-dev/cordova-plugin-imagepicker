//
//  CTPicker.m
//
//  Created by Christopher Sullivan on 10/25/13.
//  Updated by Jeduan Cornejo on 07/06/15
//

#import "CTPicker.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

@interface CTPicker ()

@property (copy) NSString* callbackId;

@end

@implementation CTPicker

@synthesize callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command {
	NSDictionary *options = [command.arguments objectAtIndex: 0];
    [self.commandDelegate runInBackground:^{
        NSInteger maxImages = [options[@"maxImages"] integerValue];
        NSInteger minImages = [options[@"minImages"] integerValue];
        self.width = [options[@"width"] integerValue] ?: 0;
        self.height = [options[@"height"] integerValue] ?: 0;
        self.quality = [options[@"quality"] integerValue] ?: 100;
        NSString *mediaType = (NSString *)options[@"mediaType"];
        
        // Create the an album controller and image picker
        QBImagePickerController *imagePicker = [[QBImagePickerController alloc] init];
        
        imagePicker.allowsMultipleSelection = (maxImages >= 2);
        imagePicker.showsNumberOfSelectedAssets = YES;
        imagePicker.maximumNumberOfSelection = maxImages;
        imagePicker.minimumNumberOfSelection = minImages;

        NSMutableArray *collections = [imagePicker.assetCollectionSubtypes mutableCopy];
        
        if ([mediaType isEqualToString:@"image"]) {
            imagePicker.mediaType = QBImagePickerMediaTypeImage;
            [collections removeObject:@(PHAssetCollectionSubtypeSmartAlbumVideos)];
        } else if ([mediaType isEqualToString:@"video"]) {
            imagePicker.mediaType = QBImagePickerMediaTypeVideo;
        } else {
            imagePicker.mediaType = QBImagePickerMediaTypeAny;
        }
        imagePicker.assetCollectionSubtypes = [collections copy];
        
        imagePicker.delegate = self;
        
        self.callbackId = command.callbackId;
        [self.viewController presentViewController:imagePicker animated:YES completion:NULL];
    }];
}

#pragma mark - QBImagePickerControllerDelegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    NSLog(@"Selected assets:");
    NSLog(@"%@", assets);
    NSString *docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    NSString *filePath;

    __block NSMutableArray *resultStrings = [[NSMutableArray alloc] init];
    
    for (PHAsset *asset in assets) {
        int i = 1;
        do {
            filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, i++, @"jpg"];
        } while ([fileManager fileExistsAtPath:filePath]);
        
        CGSize targetSize;
        if (self.width == 0 && self.height == 0) {
            targetSize = PHImageManagerMaximumSize;
        } else {
            targetSize = CGSizeMake(self.width, self.height);
        }
        
        [manager requestImageForAsset:asset
                           targetSize:targetSize
                          contentMode:PHImageContentModeAspectFill
                              options:options
                        resultHandler:^(UIImage *image, NSDictionary *info) {
                            
            NSError *err;
            NSData *data = UIImageJPEGRepresentation(image, self.quality/100.0f);
            if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                [self didFinishImagesWithResult:pluginResult];
            } else {
                [resultStrings addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
                if ([resultStrings count] == [assets count]) {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultStrings];
                    [self didFinishImagesWithResult:pluginResult];
                }
            }
        }];
    }
    
    [self.viewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) didFinishImagesWithResult: (CDVPluginResult *)pluginResult
{
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    self.callbackId = nil;
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"User cancelled."];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    self.callbackId = nil;
    [self.viewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
