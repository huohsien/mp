//
//  MPDataScrambler.m
//  mp
//
//  Created by Min Tsai on 5/30/12.
//  Copyright (c) 2012 Min-Hong Tsai. All rights reserved.
//

#import "MPDataScrambler.h"

@implementation MPDataScrambler


#pragma mark - Encode

+ (NSData *) encodeLengthHeader:(int)lengthOfMessage //, char *encode_lengthstring ) // encode_lengthstring為output 5 bytes
{
    
    int i , rn ;
    unsigned char LEN[10];
    unsigned char Ran4Bits[16]={0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240};
    
    //static unsigned int kk=1;
    //unsigned int  random = GetTickCount() % 10000 + lengthOfMessage;
    
    sprintf((char *)LEN,"%05d", lengthOfMessage);
    
    //轉成數字 LEN[0]=0;  LEN[1]=0;  LEN[2]=1;  LEN[3]=9;  LEN[4]=8;
    //前面4bits都是0000 , 用random 4bits取代  . 假設以下紅色為random取出的4 bits
    for(i=0 ; i<5 ; i++)
    {
        //if(kk++>100) kk=1;
        LEN[i] = LEN[i]-'0' ;
        //random = (random+kk*3)*(7);
        rn = arc4random() % 16 ;
        LEN[i] += Ran4Bits[rn] ;
    }
    //LEN bit位移 : 12345678 => 45678123
    for(i=0 ; i<5 ; i++)
    {
        unsigned char BIT1 = LEN[i]<<3;
        unsigned char BIT2 = LEN[i]>>5;
        LEN[i] = BIT1 + BIT2  ;
    }
    
    NSData *lenData = [NSData dataWithBytes:LEN length:5];
    return lenData;
    
    //memcpy(encode_lengthstring,LEN,5);
    //return 5;
}
 
+ (NSData *) encodeMessage:(NSData *)messageData length:(int)messageLength encodeLength:(NSData *)encodedLengthData  // messagestring 為input及output (overwrite)
{
    
    char *messageChar = (char *)[messageData bytes];
    char *lengthChar = (char *)[encodedLengthData bytes];
    
    unsigned char encodedMessage[messageLength];
    
    int i,j;
    //利用LEN 5個 bytes 依序對DATA做XOR
    for(i=0 , j=0  ;  i< messageLength;  i++ )  //XOR with LEN
    {
        encodedMessage[i] = messageChar[i] ^ lengthChar[j] ; 
        j++ ;
        if(j>=5) j=0 ;
    }
    //對DATA再做一次XOR (跟前一個BYE)
    for(i=1  ;  i< messageLength;  i++) 
    {
        encodedMessage[i] = encodedMessage[i] ^ encodedMessage[i-1] ;
    }
    
    NSData *msgData = [NSData dataWithBytes:encodedMessage length:messageLength];
    return msgData;
    
    //return messageLength;
}


#pragma mark - Decode

+ (int) decodeLengthHeader:(NSData *)encodedLength //回傳真正message長度
{
    char *lengthChar = (char *)[encodedLength bytes];
    
    int i;
    unsigned char LEN[10];
    memcpy(LEN, lengthChar, 5);
    //先將LEN還原
    for(i=0 ; i<5 ; i++)
    {
        unsigned char BIT1 = LEN[i]>>3;
        unsigned char BIT2 = LEN[i]<<5;
        LEN[i] = BIT1 + BIT2 ;  // bit位移 : 45678123 => 12345678
        LEN[i] &= 0x0f ; //移除前面4bits
    }
    //算出真正資料長度
    int datalength = 10000* LEN[0] + 1000* LEN[1] +100* LEN[2] +10* LEN[3] +LEN[4] ;
    return datalength;
}

+ (NSData *) decodedMessage:(NSData *)encodedMesssage length:(int)messageLength encodeLength:(NSData *)encodedLengthData
{
    char *messageChar = (char *)[encodedMesssage bytes];
    char *lengthChar = (char *)[encodedLengthData bytes];
    
    unsigned char decodedMessage[messageLength];
    
    
    int i,j;
    //先對DATA(跟前一個BYTE) 做XOR
    for(i=messageLength-1; i > 0; i--)  //由最後一個 byte做起
    {
        decodedMessage[i] = messageChar[i] ^ messageChar[i-1];
        
    }
    
    // first byte is the same
    decodedMessage[0] = messageChar[0];

    
    //再對LEN 5個bytes 依序做XOR
    for(i=0 , j=0; i< messageLength;  i++) 
    {
        decodedMessage[i] = decodedMessage[i] ^ lengthChar[j] ; 
        j ++ ;
        if( j >= 5 ) j=0;
    }
    
    NSData *msgData = [NSData dataWithBytes:decodedMessage length:messageLength];
    return msgData;
}


@end
