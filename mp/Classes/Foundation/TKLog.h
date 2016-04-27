//
//  TKLog.h
//  mp
//
//  Created by Min Tsai on 3/28/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "DDLog.h"

#ifdef LOGGING_ON
static const int ddLogLevel = LOG_LEVEL_INFO;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif
