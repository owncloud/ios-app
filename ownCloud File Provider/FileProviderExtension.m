//
//  FileProviderExtension.m
//  ownCloud File Provider
//
//  Created by Felix Schwarz on 07.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

#import "FileProviderExtension.h"

@interface FileProviderExtension ()

@property (nonatomic, readonly, strong) NSFileManager *fileManager;

@end

@implementation FileProviderExtension

- (instancetype)init {
    if (self = [super init]) {
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (nullable NSFileProviderItem)itemForIdentifier:(NSFileProviderItemIdentifier)identifier error:(NSError * _Nullable *)error {
    // resolve the given identifier to a record in the model
    
    // TODO: implement the actual lookup
    NSFileProviderItem item = nil;
    
    return item;
}

- (nullable NSURL *)URLForItemWithPersistentIdentifier:(NSFileProviderItemIdentifier)identifier {
    // resolve the given identifier to a file on disk
    NSFileProviderItem item = [self itemForIdentifier:identifier error:NULL];
    if (!item) {
        return nil;
    }
    
    // in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
    NSFileProviderManager *manager = [NSFileProviderManager defaultManager];
    NSURL *perItemDirectory = [manager.documentStorageURL URLByAppendingPathComponent:identifier isDirectory:YES];
    
    return [perItemDirectory URLByAppendingPathComponent:item.filename isDirectory:NO];
}

- (nullable NSFileProviderItemIdentifier)persistentIdentifierForItemAtURL:(NSURL *)url {
    // resolve the given URL to a persistent identifier using a database
    NSArray <NSString *> *pathComponents = [url pathComponents];
    
    // exploit the fact that the path structure has been defined as
    // <base storage directory>/<item identifier>/<item file name> above
    NSParameterAssert(pathComponents.count > 2);
    
    return pathComponents[pathComponents.count - 2];
}

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    NSFileProviderItemIdentifier identifier = [self persistentIdentifierForItemAtURL:url];
    if (!identifier) {
        completionHandler([NSError errorWithDomain:NSFileProviderErrorDomain code:NSFileProviderErrorNoSuchItem userInfo:nil]);
        return;
    }
    
    NSError *error = nil;
    NSFileProviderItem fileProviderItem = [self itemForIdentifier:identifier error:&error];
    if (!fileProviderItem) {
        completionHandler(error);
        return;
    }
    NSURL *placeholderURL = [NSFileProviderManager placeholderURLForURL:url];
    if (![NSFileProviderManager writePlaceholderAtURL:placeholderURL withMetadata:fileProviderItem error:&error]) {
        completionHandler(error);
        return;
    }
    completionHandler(nil);
}

- (void)startProvidingItemAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler {
    // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
    
    /* TODO:
     This is one of the main entry points of the file provider. We need to check whether the file already exists on disk,
     whether we know of a more recent version of the file, and implement a policy for these cases. Pseudocode:
     
     if (!fileOnDisk) {
         downloadRemoteFile();
         callCompletion(downloadErrorOrNil);
     } else if (fileIsCurrent) {
         callCompletion(nil);
     } else {
         if (localFileHasChanges) {
             // in this case, a version of the file is on disk, but we know of a more recent version
             // we need to implement a strategy to resolve this conflict
             moveLocalFileAside();
             scheduleUploadOfLocalFile();
             downloadRemoteFile();
             callCompletion(downloadErrorOrNil);
         } else {
             downloadRemoteFile();
             callCompletion(downloadErrorOrNil);
         }
     }
     */
    
    completionHandler([NSError errorWithDomain:NSCocoaErrorDomain code:NSFeatureUnsupportedError userInfo:@{}]);
}


- (void)itemChangedAtURL:(NSURL *)url {
    // Called at some point after the file has changed; the provider may then trigger an upload
    
    /* TODO:
     - mark file at <url> as needing an update in the model
     - if there are existing NSURLSessionTasks uploading this file, cancel them
     - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
     - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
     */
}

- (void)stopProvidingItemAtURL:(NSURL *)url {
    // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
    
    // TODO: look up whether the file has local changes
    BOOL fileHasLocalChanges = NO;
    
    if (!fileHasLocalChanges) {
        // remove the existing file to free up space
        [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
        
        // write out a placeholder to facilitate future property lookups
        [self providePlaceholderAtURL:url completionHandler:^(NSError * __nullable error) {
            // TODO: handle any error, do any necessary cleanup
        }];
    }
}

#pragma mark - Actions

/* TODO: implement the actions for items here
 each of the actions follows the same pattern:
 - make a note of the change in the local model
 - schedule a server request as a background task to inform the server of the change
 - call the completion block with the modified item in its post-modification state
 */

#pragma mark - Enumeration

- (nullable id<NSFileProviderEnumerator>)enumeratorForContainerItemIdentifier:(NSFileProviderItemIdentifier)containerItemIdentifier error:(NSError **)error {
    id<NSFileProviderEnumerator> enumerator = nil;
    if ([containerItemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier]) {
        // TODO: instantiate an enumerator for the container root
    } else if ([containerItemIdentifier isEqualToString:NSFileProviderWorkingSetContainerItemIdentifier]) {
        // TODO: instantiate an enumerator for the working set
    } else {
        // TODO: determine if the item is a directory or a file
        // - for a directory, instantiate an enumerator of its subitems
        // - for a file, instantiate an enumerator that observes changes to the file
    }
    
    return enumerator;
}

@end

