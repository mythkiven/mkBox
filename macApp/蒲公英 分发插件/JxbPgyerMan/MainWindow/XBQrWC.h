//
//  XBQrWC.h
//  JxbPgyerMan
//
//  Created by Peter Jin on https://github.com/JxbSir  15/5/20.
//  Copyright (c) 2015年 Peter Jin .  Mail:i@Jxb.name All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PVAsyncImageView.h"

@interface XBQrWC : NSWindowController
{
    IBOutlet  NSProgressIndicator*  progress;
    IBOutlet  PVAsyncImageView*     imgView;
}
@property(nonatomic,copy)NSString*  akey;
@end
