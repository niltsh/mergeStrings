//
//  main.m
//  mergeStrings
//
//  Created by NILTSH on 15/5/2.
//  Copyright (c) 2015年 NILTSH. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    int errout = false;
    int ret = 0;

    @autoreleasepool {
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        
        NSString *oldFile = nil, *newFile = nil, *outputFile = nil;
        BOOL verbose = false;
        
        NSMutableDictionary *translatedDict = nil;
        NSMutableArray *outputLines = nil;
        
        if ([args count] < 7)
            goto bailout;
        
        for (int i = 0; i < [args count]; i++) {
            if (i == 0) {
                continue;
            } else {
                if ([[args objectAtIndex:i] isEqualToString:@"-o"]) {
                    oldFile = [[args objectAtIndex:++i] retain];
                    continue;
                }
                
                if ([[args objectAtIndex:i] isEqualToString:@"-n"]) {
                    newFile = [[args objectAtIndex:++i] retain];
                    continue;
                }
                
                if ([[args objectAtIndex:i] isEqualToString:@"-O"]) {
                    outputFile = [[args objectAtIndex:++i] retain];
                    continue;
                }
                
                if ([[args objectAtIndex:i] isEqualToString:@"-v"]) {
                    verbose = true;
                    continue;
                }
            }
        }
        
        if (!(oldFile && newFile && outputFile))
            goto bailout;
        
        fprintf(stdout, "Old file: %s\nNew file: %s\nOut file: %s\n\n", [oldFile UTF8String], [newFile UTF8String], [outputFile UTF8String]);
        
        NSError *err;
        NSString * old = [[[NSString alloc] initWithContentsOfFile:oldFile encoding:NSUTF16StringEncoding error:&err] autorelease];
        if (!old) {
            fprintf(stderr, "Old file open error: %s\n", [[err localizedDescription] UTF8String]);
            goto bailout2;
        }
//        if (verbose) {
//            NSLog(@"Old file content:\n%@", old);
//        }
        
        NSString *new = [[[NSString alloc] initWithContentsOfFile:newFile encoding:NSUTF16StringEncoding error:&err] autorelease];
        if (!new) {
            fprintf(stderr, "New file open error: %s\n", [[err localizedDescription] UTF8String]);
            goto bailout2;
        }
//        if (verbose) {
//            NSLog(@"New file content:\n%@", new);
//        }
        
        //旧的翻译文件读出 行
        NSArray *splitLines = [old componentsSeparatedByString:@"\n"];
        
        translatedDict = [[NSMutableDictionary alloc] initWithCapacity:100];
        
        for (NSString *line in splitLines) {
            // 读出 每一行
            // 按照等号分割，分割出来 0 是翻译前的内容， 1 是翻译后的内容
            NSArray *keyAndObj = [line componentsSeparatedByString:@"\" = \""];

            if ([keyAndObj count] == 2) {
                // 如果分割出2个内容，登录到 translatedDict
                [translatedDict setObject:[keyAndObj objectAtIndex:1] forKey:[keyAndObj objectAtIndex:0]];
                
            } else if ([keyAndObj count] == 1) {
                // 什么也没有分割出来什么也不做
            } else {
                // 分割出来的多于两个，出错
                fprintf(stderr, "Read old file error, at:%s\n", [line UTF8String]);
                goto bailout2;
            }
        }
        
        fprintf(stderr, "Read in %lu entries from the old.\n", [translatedDict count]);
        
        outputLines = [[NSMutableArray alloc] initWithCapacity:100];

        // 分割出新的文件 每一行
        NSArray *splitedlinesNew = [new componentsSeparatedByString:@"\n"];
        
        int tranaltedLineNum = 0;
        
        for (NSString *line in splitedlinesNew) {
            // 每一行按照 ＝ 分割
            NSArray *keyAndObjNew = [line componentsSeparatedByString:@"\" = \""];
            
            if ([keyAndObjNew count] == 2) {
                // 分割出两个内容
                // 去参照旧文件
                NSString *checkTranslated = [translatedDict objectForKey:[keyAndObjNew objectAtIndex:0]];

                if (checkTranslated) {
                    // 找到已经翻译的内容，那么 用 ＝ 连接起来
                    NSString *translatedLine = [NSString stringWithFormat:@"%@\" = \"%@", [keyAndObjNew objectAtIndex:0], checkTranslated];
                    
                    // 添加
                    [outputLines addObject:translatedLine];
                    tranaltedLineNum++;
                } else {
                    // 没有找到翻译的内容，那说明是一个新的entry
                    [outputLines addObject:line];
                    fprintf(stdout, "Add new entry: %s\n", [line UTF8String]);
                }
            } else if([keyAndObjNew count] == 1) {
                // 分割出来一个内容，说明不是 有＝的内容，直接加到outputLines
                [outputLines addObject:line];
            } else {
                fprintf(stderr, "Read new file error, at:%s\n", [line UTF8String]);
                goto bailout2;
            }
        }
        
        fprintf(stdout, "Translate %d entries\n", tranaltedLineNum);
        
        NSString *outputString = [outputLines componentsJoinedByString:@"\n"];
        
        if (![outputString writeToFile:outputFile atomically:YES encoding:NSUTF16StringEncoding error:&err]) {
            fprintf(stderr, "Write to output file error: %s\n", [[err localizedDescription] UTF8String]);
            goto bailout2;
        }
        
        goto normal;
bailout:
        fprintf(stderr, "Usage: mergeStings [-v] -o <old file> -n <new file> -O <output file>\n");
bailout2:
        errout = true;
normal:
        if (oldFile) {
            [oldFile release];
        }
        if (newFile) {
            [newFile release];
        }
        if (outputFile) {
            [outputFile release];
        }
        if (translatedDict) {
            [translatedDict release];
        }
        if (outputLines) {
            [outputLines release];
        }
        
        if (errout)
            ret = 1;
    }
    return ret;
}
