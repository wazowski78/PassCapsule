//
//  PCCapsuleGroup.m
//  PassCapsule
//
//  Created by 邵建勇 on 15/6/29.
//  Copyright (c) 2015年 John Shaw. All rights reserved.
//

#import "PCCapsuleGroup.h"

@implementation PCCapsuleGroup

- (NSMutableArray *)entries{
    if (!_entries) {
        _entries = [[NSMutableArray alloc] init];
    }
    return _entries;
}

@end
