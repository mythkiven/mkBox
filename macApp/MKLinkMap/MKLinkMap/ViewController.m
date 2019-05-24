/**
 *
 * Created by https://github.com/mythkiven/ on 19/05/23.
 * Copyright © 2019年 mythkiven. All rights reserved.
 *
 */


#import "ViewController.h"

@interface SymbolModel : NSObject
@property (nonatomic, copy) NSString *file;
@property (nonatomic, assign) NSUInteger size;
@end
@implementation SymbolModel
@end


@interface ViewController()
@property (weak) IBOutlet NSScrollView *contentView;
@property (weak) IBOutlet NSScrollView *deadCodeContentView;
@property (weak) IBOutlet NSTextField *filePath;
@property (weak) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSTextField *searchField;
@property (unsafe_unretained) IBOutlet NSTextView *content;
@property (unsafe_unretained) IBOutlet NSTextView *deadCodeContent;
@property (weak) IBOutlet NSButton *groupButton;

@property (strong) NSURL *linkMapFileURL;
@property (strong) NSString *linkMapContent;
@property (strong) NSString *appName;

@property (nonatomic,strong) NSMutableString *result;
@property (nonatomic,strong) NSMutableString *deadCodeResult;
@end

NSString *const defaultString = @"使用方法：\n\
1. 在 XCode 中开启编译选项 Write Link Map File : XCode -> Project -> Build Settings ->  Write Link Map File 设为 yes，并指定好 linkMap 的存储位置 \n\
2. 工程编译完成后，在指定的位置找到 Link Map 文件（默认名称:$(PRODUCT_NAME)-LinkMap-$(CURRENT_VARIANT)-$(CURRENT_ARCH).txt） \n\
默认的文件地址：~/Library/Developer/Xcode/DerivedData/xxxxxxxxxxxx/Build/Intermediates/XXX.build/Debug-iphoneos/XXX.build/ \n\
\n\
3. 回到本应用，点击 \"选择文件\"，选择 Link Map 文件  \n\
4. 点击 \"分析\"，解析 Link Map 文件 \n\
5. 点击 \"格式化输出\"，会输出经过处理后，易于阅读的  Link Map 文件(文件过大时，输出可能需要几分钟时间) \n\
6. 点击 \"输出文件\"，会输出经统计后的 Link Map 文件 \n\
\n\
6. 搜索功能：输入目标文件的关键字，然后点击 \"分析\"\n\
7. 按库分析：勾选 \"按库统计\"，然后点击 \"分析\"\n\
\n\
源码参见：https://github.com/mythkiven/mkBox";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.content.automaticLinkDetectionEnabled = YES;
    [self stopAnimation];
}

#pragma mark - 选择文件
- (IBAction)chooseFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = YES;
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *document = [[panel URLs] objectAtIndex:0];
            self.filePath.stringValue = document.path;
            self.linkMapFileURL = document;
            NSString *content = [NSString stringWithContentsOfURL:self.linkMapFileURL encoding:NSMacOSRomanStringEncoding error:nil];
            NSString *line = [content componentsSeparatedByString:@"\n"].firstObject;
            if(line.length && [line componentsSeparatedByString:@".app/"].count>1){
                self.appName = [line componentsSeparatedByString:@".app/"].lastObject;
            }
            if(!self.appName.length){
                [self showAlertWithText:@"请选择正确的 Link Map 文件!"];
                self.filePath.stringValue = @"请选择正确的 Link Map File";
            }
        }
    }];
}
#pragma mark - 格式化输出文件
- (IBAction)print:(id)sender {
    if (!_linkMapFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[_linkMapFileURL path] isDirectory:nil]) {
        [self showAlertWithText:@"请选择正确的 Link Map 文件路径"];
        return;
    }
    [self startAnimation];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *content = [NSString stringWithContentsOfURL:self.linkMapFileURL encoding:NSMacOSRomanStringEncoding error:nil];
        NSArray *lines = [content componentsSeparatedByString:@"\n"];
        __block BOOL objectfiles = NO;
        __block BOOL sections = NO;
        __block BOOL symbols = NO;
        __block BOOL deadSymbols = NO;
        NSMutableString *printString = [NSMutableString stringWithCapacity:0];
        NSMutableArray *marr = [NSMutableArray arrayWithArray:lines];
        [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL * _Nonnull stop) {
            if([line hasPrefix:@"#"]) {
                if([line hasPrefix:@"# Object files:"]){
                    objectfiles = YES;
                    [marr insertObject:@"\n########################## Object files ###########################\n"  atIndex:([lines indexOfObject:line])];
                }else if ([line hasPrefix:@"# Sections:"]){
                    sections = YES;
                    [marr insertObject:@"\n########################## Sections ###########################\n"  atIndex:([lines indexOfObject:line]+1)];
                }else if ([line hasPrefix:@"# Symbols:"]){
                    symbols = YES;
                    [marr insertObject:@"\n########################## Symbols ###########################\n"  atIndex:([lines indexOfObject:line]+2)];
                }else if ([line hasPrefix:@"# Dead Stripped Symbols:"]){
                    deadSymbols = YES;
                    [marr insertObject:@"\n########################## Dead Stripped Symbols ###########################\n"  atIndex:([lines indexOfObject:line]+3)];
                }
            } else {
                if(objectfiles && !sections && line.length>10) {
                    NSString *preString = [line substringToIndex:7];
                    NSArray *releaseArr = [line componentsSeparatedByString:@"Release-iphoneos/"];
                    NSArray *debugArr = [line componentsSeparatedByString:@"Debug-iphoneos/"];
                    NSArray *sdkArr = [line componentsSeparatedByString:@"SDKs/"];
                    NSArray *chainArr = [line componentsSeparatedByString:@"Toolchains/"];
                    if(preString){
                        if(releaseArr.count==2) {
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+1 withObject:[NSString stringWithFormat:@"%@../%@",preString,releaseArr.lastObject]];
                        }else if(debugArr.count==2) {
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+1 withObject:[NSString stringWithFormat:@"%@../%@",preString,debugArr.lastObject]];
                        }else if(sdkArr.count==2) {
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+1 withObject:[NSString stringWithFormat:@"%@../%@",preString,sdkArr.lastObject]];
                        }else if(chainArr.count==2) {
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+1 withObject:[NSString stringWithFormat:@"%@../%@",preString,chainArr.lastObject]];
                        }
                    }
                }else if(objectfiles && sections && !symbols){
                    if([line hasPrefix:@"0x"]){
                        NSArray <NSString *>*arr = [line componentsSeparatedByString:@"\t"];
                        if(arr.count == 4) {
                            NSString *size = formatSize(arr[1]);
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+2 withObject:[NSString stringWithFormat:@"%@\t%@\t%@\t%@",arr[0],size,arr[2],arr[3]]];
                        }
                    }
                }else if(objectfiles && sections && symbols && !deadSymbols){
                    if([line hasPrefix:@"0x"]){
                        NSArray <NSString *>*arr = [line componentsSeparatedByString:@"\t"];
                        if(arr.count == 3) {
                            NSString *size = formatSize(arr[1]);
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+3 withObject:[NSString stringWithFormat:@"%@\t%@\t%@",arr[0],size,arr[2]]];
                        }
                    }
                }else if(objectfiles && sections && symbols && deadSymbols){
                    if([line hasPrefix:@"<<dead>>"]){
                        NSArray <NSString *>*arr = [line componentsSeparatedByString:@"\t"];
                        if(arr.count == 3) {
                            NSString *size = formatSize(arr[1]);
                            [marr replaceObjectAtIndex:[lines indexOfObject:line]+4 withObject:[NSString stringWithFormat:@"%@\t%@\t%@",arr[0],size,arr[2]]];
                        }
                    }
                }
            }
        }];
        [marr enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL * _Nonnull stop) {
            [printString appendFormat:@"%@\n",line];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSOpenPanel* panel = [NSOpenPanel openPanel];
            [panel setAllowsMultipleSelection:NO];
            [panel setCanChooseDirectories:YES];
            [panel setResolvesAliases:NO];
            [panel setCanChooseFiles:NO];
            [panel beginWithCompletionHandler:^(NSInteger result) {
                [self stopAnimation];
                if (result == NSFileHandlingPanelOKButton) {
                    NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
                    NSMutableString *content =[[NSMutableString alloc]initWithCapacity:0];
                    [content appendFormat:@"%@/_printedLinkMapFile_%@.txt",[theDoc path],self.appName];
                    [printString writeToFile:content atomically:YES encoding:NSUTF8StringEncoding error:nil];
                }
            }];
        });
    });
}
NSString* formatSize(NSString *stringSize){
    NSUInteger size = strtoul([stringSize UTF8String], nil, 16);
    if (size / 1024.0 / 1024.0> 1) {
        return [NSString stringWithFormat:@"%.3fM", size / 1024.0 / 1024.0];
    }
    return [NSString stringWithFormat:@"%.3fK", size / 1024.0];
}

#pragma mark - 分析
- (IBAction)analyze:(id)sender {
    if (!_linkMapFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[_linkMapFileURL path] isDirectory:nil]) {
        [self showAlertWithText:@"请选择正确的 Link Map 文件路径"];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *content = [NSString stringWithContentsOfURL:self.linkMapFileURL encoding:NSMacOSRomanStringEncoding error:nil];
        if (![self checkContent:content]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithText:@"Link Map 文件格式有误"];
            });
            return ;
        }
        [self startAnimation];
        NSDictionary *symbolMap = [self symbolMapFromContent:content];
        NSArray <SymbolModel *>*symbols = [symbolMap allValues];
        NSArray *sortedSymbols = [self sortSymbols:symbols];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.result = [@"文件大小 \t 文件名称 \r\n\r\n" mutableCopy];
            if (self.groupButton.state == 1) {
                [self buildCombinationResultWithSymbols:sortedSymbols model:self.result];
            } else {
                [self buildResultWithSymbols:sortedSymbols model:self.result];
            }
        });
        NSDictionary *deadSymbolMap = [self deadSymbolMapFromContent:content];
        NSArray <SymbolModel *>*deadSymbols = [deadSymbolMap allValues];
        NSArray *deadSortedSymbols = [self sortSymbols:deadSymbols];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.deadCodeResult = [@"文件大小 \t 文件名称 \r\n\r\n" mutableCopy];
            if (self.groupButton.state == 1) {
                [self buildCombinationResultWithSymbols:deadSortedSymbols model:self.deadCodeResult];
            } else {
                [self buildResultWithSymbols:deadSortedSymbols model:self.deadCodeResult];
            }
        });
        [self stopAnimation];
    });
}
- (BOOL)checkContent:(NSString *)content {
    NSRange objsFileTagRange = [content rangeOfString:@"# Object files:"];
    if (objsFileTagRange.length == 0) {
        return NO;
    }
    NSString *subObjsFileSymbolStr = [content substringFromIndex:objsFileTagRange.location + objsFileTagRange.length];
    NSRange symbolsRange = [subObjsFileSymbolStr rangeOfString:@"# Symbols:"];
    if ([content rangeOfString:@"# Path:"].length <= 0||objsFileTagRange.location == NSNotFound||symbolsRange.location == NSNotFound) {
        return NO;
    }
    return YES;
}
- (NSMutableDictionary *)symbolMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,SymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    BOOL object = NO;
    BOOL sections = NO;
    BOOL symbols = NO;
    for(NSString *line in lines) {
        if([line hasPrefix:@"#"]) {
            if([line hasPrefix:@"# Object files:"])
                object = YES;
            else if ([line hasPrefix:@"# Sections:"])
                sections = YES;
            else if ([line hasPrefix:@"# Symbols:"])
                symbols = YES;
        } else {
            if(object && !sections && !symbols) {
                NSRange range = [line rangeOfString:@"]"];
                if(range.location != NSNotFound) {
                    SymbolModel *symbol = [SymbolModel new];
                    symbol.file = [line substringFromIndex:range.location+1];
                    NSString *key = [line substringToIndex:range.location+1];
                    symbolMap[key] = symbol;
                }
            } else if (object  && sections && symbols) {
                NSArray <NSString *>*symbolsArray = [line componentsSeparatedByString:@"\t"];
                if(symbolsArray.count == 3) {
                    NSString *fileKeyAndName = symbolsArray[2];
                    NSUInteger size = strtoul([symbolsArray[1] UTF8String], nil, 16);
                    NSRange range = [fileKeyAndName rangeOfString:@"]"];
                    if(range.location != NSNotFound) {
                        NSString *key = [fileKeyAndName substringToIndex:range.location+1];
                        SymbolModel *symbol = symbolMap[key];
                        if(symbol) {
                            symbol.size += size;
                        }
                    }
                }
            }
        }
    }
    return symbolMap;
}
- (NSMutableDictionary *)deadSymbolMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,SymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    BOOL object = NO;
    BOOL sections = NO;
    BOOL symbols = NO;
    BOOL deadSymbol = NO;
    for(NSString *line in lines) {
        if([line hasPrefix:@"#"]) {
            if([line hasPrefix:@"# Object files:"])
                object = YES;
            else if ([line hasPrefix:@"# Sections:"])
                sections = YES;
            else if ([line hasPrefix:@"# Symbols:"])
                symbols = YES;
            else if ([line hasPrefix:@"# Dead Stripped Symbols:"])
                deadSymbol = YES;
        } else {
            if(object && !sections && !symbols) {
                NSRange range = [line rangeOfString:@"]"];
                if(range.location != NSNotFound) {
                    SymbolModel *symbol = [SymbolModel new];
                    symbol.file = [line substringFromIndex:range.location+1];
                    NSString *key = [line substringToIndex:range.location+1];
                    symbolMap[key] = symbol;
                }
            } else if (deadSymbol) {
                NSArray <NSString *>*symbolsArray = [line componentsSeparatedByString:@"\t"];
                if(symbolsArray.count == 3) {
                    NSString *fileKeyAndName = symbolsArray[2];
                    NSUInteger size = strtoul([symbolsArray[1] UTF8String], nil, 16);
                    NSRange range = [fileKeyAndName rangeOfString:@"]"];
                    if(range.location != NSNotFound) {
                        NSString *key = [fileKeyAndName substringToIndex:range.location+1];
                        SymbolModel *symbol = symbolMap[key];
                        if(symbol) {
                            symbol.size += size;
                        }
                    }
                }
            }
        }
    }
    return symbolMap;
}
- (NSArray *)sortSymbols:(NSArray *)symbols {
    NSArray *sortedSymbols = [symbols sortedArrayUsingComparator:^NSComparisonResult(SymbolModel *  _Nonnull obj1, SymbolModel *  _Nonnull obj2) {
        if(obj1.size> obj2.size) {
            return NSOrderedAscending;
        } else if (obj1.size < obj2.size) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    return sortedSymbols;
}
- (void)buildResultWithSymbols:(NSArray *)symbols model:(NSMutableString*)model{
    NSUInteger totalSize = 0;
    NSString *searchKey = _searchField.stringValue;
    for(SymbolModel *symbol in symbols) {
        if (searchKey.length> 0) {
            if ([symbol.file containsString:searchKey]) {
                [self appendResultWithSymbol:symbol model:model];
                totalSize += symbol.size;
            }
        } else {
            [self appendResultWithSymbol:symbol model:model];
            totalSize += symbol.size;
        }
    }
    [model appendFormat:@"\r\n 总大小: %.2fM\r\n",(totalSize/1024.0/1024.0)];
}
- (void)buildCombinationResultWithSymbols:(NSArray *)symbols model:(NSMutableString*)model{
    NSUInteger totalSize = 0;
    NSMutableDictionary *combinationMap = [[NSMutableDictionary alloc] init];
    for(SymbolModel *symbol in symbols) {
        NSString *name = [[symbol.file componentsSeparatedByString:@"/"] lastObject];
        if ([name hasSuffix:@")"] &&
            [name containsString:@"("]) {
            NSRange range = [name rangeOfString:@"("];
            NSString *component = [name substringToIndex:range.location];
            SymbolModel *combinationSymbol = [combinationMap objectForKey:component];
            if (!combinationSymbol) {
                combinationSymbol = [[SymbolModel alloc] init];
                [combinationMap setObject:combinationSymbol forKey:component];
            }
            combinationSymbol.size += symbol.size;
            combinationSymbol.file = component;
        } else {
            // symbol 可能来自 app 本身的目标文件或者系统的动态库，在最后的结果中一起显示
            [combinationMap setObject:symbol forKey:symbol.file];
        }
    }
    NSArray <SymbolModel *>*combinationSymbols = [combinationMap allValues];
    NSArray *sortedSymbols = [self sortSymbols:combinationSymbols];
    NSString *searchKey = _searchField.stringValue;
    for(SymbolModel *symbol in sortedSymbols) {
        if (searchKey.length> 0) {
            if ([symbol.file containsString:searchKey]) {
                [self appendResultWithSymbol:symbol model:model];
                totalSize += symbol.size;
            }
        } else {
            [self appendResultWithSymbol:symbol model:model];
            totalSize += symbol.size;
        }
    }
    [model appendFormat:@"\r\n 总大小: %.2fM\r\n",(totalSize/1024.0/1024.0)];
}
- (void)appendResultWithSymbol:(SymbolModel *)model model:(NSMutableString*)smodel {
    NSString *size = nil;
    if (model.size / 1024.0 / 1024.0> 1) {
        size = [NSString stringWithFormat:@"%.2fM", model.size / 1024.0 / 1024.0];
    } else {
        size = [NSString stringWithFormat:@"%.2fK", model.size / 1024.0];
    }
    [smodel appendFormat:@"%@\t%@\r\n",size, [[model.file componentsSeparatedByString:@"/"] lastObject]];
}

#pragma mark - 输出文件
- (IBAction)ouputFile:(id)sender {
    if (!_linkMapFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[_linkMapFileURL path] isDirectory:nil]) {
        [self showAlertWithText:@"请选择正确的 Link Map 文件路径"];
        return;
    }
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setResolvesAliases:NO];
    [panel setCanChooseFiles:NO];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *theDoc = [[panel URLs] objectAtIndex:0];
            NSMutableString *content =[[NSMutableString alloc]initWithCapacity:0];
            [content appendFormat:@"%@/_decodeLinkMapFile_%@.txt",[theDoc path],self.appName];
            [self.result appendFormat:@"\r\n ******* 未使用代码分析: ********\r\n%@",self.deadCodeResult];
            [self.result   writeToFile:content atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }];
}

#pragma mark -  ui
- (void)startAnimation {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.indicator.hidden = NO;
        [self.indicator startAnimation:self];
    });
}
- (void)stopAnimation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.content.textStorage setAttributedString:[self autoLinkURLs:self.result]];
        self.deadCodeContent.string = self.deadCodeResult;
        self.indicator.hidden = YES;
        [self.indicator stopAnimation:self];
    });
}
- (NSMutableString*)result {
    if(_result)
        return _result;
    return [defaultString mutableCopy];
}
- (NSMutableString*)deadCodeResult {
    if(_deadCodeResult)
        return _deadCodeResult;
    return [@"" mutableCopy];
}
- (void)showAlertWithText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc]init];
        alert.messageText = text;
        [alert addButtonWithTitle:@"确定"];
        [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
        }];
    });
}
- (NSAttributedString *)autoLinkURLs:(NSString *)string {
    NSMutableAttributedString *linkedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    [detector enumerateMatchesInString:string options:0 range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        if (match.URL) {
            NSDictionary *attributes = @{ NSLinkAttributeName: match.URL };
            [linkedString addAttributes:attributes range:match.range];
        }
    }];
    return [linkedString copy];
}
@end
