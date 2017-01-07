//
//  GameScene.m
//  非凡桌面清理大师
//
//  Created by 何振邦 on 16/12/12.
//  Copyright © 2016年 何振邦. All rights reserved.
//

#import "GameScene.h"
@implementation SKLabelNode(click)
-(void)mouseDown:(NSEvent *)event{
    SKAction* big=[SKAction scaleTo:1.1 duration:0.1];
    SKAction* small=[SKAction scaleTo:1 duration:0.1];
    SKAction* combine=[SKAction sequence:[NSArray arrayWithObjects:big,small, nil]];
    [self runAction:combine];
}
-(void)mouseMoved:(NSEvent *)event{
    
}
@end
@implementation SKSpriteNode(click)

-(void)mouseDown:(NSEvent *)event{
    if([self.name isEqualToString:@"bg"])return;
    [self setColorBlendFactor:0.5];
}
-(void)mouseUp:(NSEvent *)event{
    [self setColorBlendFactor:0];
}
@end
@implementation GameScene {
    SKShapeNode *_spinnyNode;
    SKLabelNode *byType;
    SKLabelNode *byDate;
    SKLabelNode *byDeep;
}
//处理shell命令中会造成歧义的字符
-(NSString*)dealSpecChar:(NSString*)cmd{
    NSMutableString* temp=[NSMutableString stringWithString:cmd];
    [temp replaceOccurrencesOfString:@"#" withString:@"\\#" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"%" withString:@"\\%" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"&" withString:@"\\&" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"$" withString:@"\\$" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"," withString:@"\\," options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"=" withString:@"\\=" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"*" withString:@"\\*" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@" " withString:@"\\ " options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"|" withString:@"\\|" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"~" withString:@"\\~" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"{" withString:@"\\{" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"<" withString:@"\\<" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"}" withString:@"\\}" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@">" withString:@"\\>" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@"'" withString:@"\\'" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    [temp replaceOccurrencesOfString:@";" withString:@"\\;" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
    return temp;
}
-(NSString*)execCmd:(NSString*)cmd{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    //获得Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    [task waitUntilExit];
    
    //运行结果
    NSData *data = [file readDataToEndOfFile];
    NSString* result=[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //NSLog(@"the result of cmd %@ is %@",cmd,result);
    return result;
}

- (void)didMoveToView:(SKView *)view {
    SKSpriteNode* background=[SKSpriteNode spriteNodeWithImageNamed:@"background.png"];
    background.position=view.frame.origin;
    background.zPosition=-1;
    background.xScale=1.4;
    background.yScale=1.4;
    background.name=@"bg";
    [self addChild:background];
    //init chMon
    chMon=[NSDictionary dictionaryWithObjectsAndKeys:
           @"一月",@"Jan",
           @"二月",@"Feb",
           @"三月",@"Mar",
           @"四月",@"Apr",
           @"五月",@"May",
           @"六月",@"Jun",
           @"七月",@"Jul",
           @"八月",@"Aug",
           @"九月",@"Sep",
           @"十月",@"Oct",
           @"十一月",@"Nov",
           @"十二月",@"Dec", nil];
    //load gif
    cleanGif=[[NSMutableArray alloc]init];
    for (int i=0; i<26; ++i) {
        [cleanGif addObject:[SKTexture textureWithImageNamed:[NSString stringWithFormat:@"梁非凡%d.jpg",i]]];
    }
    // Setup your scene here
    //[self handle];
    // Get label node from scene and store it for use later
    byType = (SKLabelNode *)[self childNodeWithName:@"byType"];
    byDate=(SKLabelNode *)[self childNodeWithName:@"byDate"];
    byDeep=(SKLabelNode *)[self childNodeWithName:@"byDeep"];
    note=(SKLabelNode*)[self childNodeWithName:@"note"];
    scr=(SKSpriteNode*)[self childNodeWithName:@"scr"];
    [note setText:@"您的桌面文件会被按照文件类型整理"];
    mode=1;//default byType
    
}
-(void)handle{
    NSMutableArray* output=[NSMutableArray arrayWithArray:[[self execCmd:@"ls -l ~/desktop"]componentsSeparatedByString:@"\n"] ];
    if ([output count]<=1) {
        return;
    }
    //删去多余信息
    [output removeLastObject];//remove blank space
    [output removeObjectAtIndex:0];//remove file amount data
    //元素分割
    NSArray* fileNameArray=[[self execCmd:@"ls ~/desktop"]componentsSeparatedByString:@"\n"];
    //fileNameArray的有效长度和output一样
    NSLog(@"array length is %lu,%lu",(unsigned long)[output count],(unsigned long)[fileNameArray count]);

    for(int j=0;j<[output count];++j){
        NSMutableArray* data=[NSMutableArray arrayWithArray:[(NSString*)[output objectAtIndex:j] componentsSeparatedByString:@" "]];
        [data removeObject:@""];
        //下面处理文件名
        NSString* fileName=[self dealSpecChar:[fileNameArray objectAtIndex:j]];
        [data replaceObjectAtIndex:8 withObject:fileName];

        //下面处理文件后缀
        NSArray* fileType=[[data objectAtIndex:8]componentsSeparatedByString:@"."];
        if ([fileType count]>1) {
            NSLog(@"文件名:%@后缀:%@",[data objectAtIndex:8],[fileType lastObject]);
        }
        //判断是非是文件夹，文件夹data第二项大于2
    }
}
-(void)cleanByDeep{
    [self execCmd:@"mkdir ~/desktop/桌面文件"];
    NSMutableArray* output=[NSMutableArray arrayWithArray:[[self execCmd:@"ls -l ~/desktop"]componentsSeparatedByString:@"\n"]];
    //删去多余信息
    if ([output count]<=1) {
        return;
    }
    [output removeLastObject];//remove blank space
    [output removeObjectAtIndex:0];//remove file amount data
    //元素分割
    NSArray* fileNameArray=[[self execCmd:@"ls ~/desktop"]componentsSeparatedByString:@"\n"];
    //fileNameArray的有效长度和output一样
    //NSLog(@"array length is %lu,%lu",(unsigned long)[output count],(unsigned long)[fileNameArray count]);
    
    for(int j=0;j<[output count];++j){
        NSMutableArray* data=[NSMutableArray arrayWithArray:[(NSString*)[output objectAtIndex:j] componentsSeparatedByString:@" "]];
        [data removeObject:@""];
        //下面处理文件名
        NSString* fileName=[self dealSpecChar:[fileNameArray objectAtIndex:j]];
        [data replaceObjectAtIndex:8 withObject:fileName];        //文件名已经完成了空格的格式化处理
        if([fileName isEqualToString:@"$RECYCLE.BIN"]||[fileName isEqualToString:@"desktop.ini"]||[fileName isEqualToString:@"Thumbs.db"])continue;
        NSString* cmd=[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/桌面文件",[data objectAtIndex:8]];
        [self execCmd:cmd];
    }
}
-(void)cleanByDate{
    NSMutableArray* output=[NSMutableArray arrayWithArray:[[self execCmd:@"ls -l ~/desktop/"]componentsSeparatedByString:@"\n"] ];
    if ([output count]<=1) {
        return;
    }
    //获取时间
    //get current date Thu Dec 15 20:09:03 CST 2016
    //0-weekday 1-month 2-day 3-time 4-timeZone 5-year
    NSString* dateString=[[self execCmd:@"date"]stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSArray* date=[dateString componentsSeparatedByString:@" "];
    
    //删去多余信息
    [output removeLastObject];//remove blank space
    [output removeObjectAtIndex:0];//remove file amount data
    //元素分割
    NSArray* fileNameArray=[[self execCmd:@"ls ~/desktop"]componentsSeparatedByString:@"\n"];
    //fileNameArray的有效长度和output一样
    //NSLog(@"array length is %lu,%lu",(unsigned long)[output count],(unsigned long)[fileNameArray count]);
    
    for(int j=0;j<[output count];++j){
        NSMutableArray* data=[NSMutableArray arrayWithArray:[(NSString*)[output objectAtIndex:j] componentsSeparatedByString:@" "]];
        [data removeObject:@""];
        //下面处理文件名
        NSString* fileName=[self dealSpecChar:[fileNameArray objectAtIndex:j]];
        [data replaceObjectAtIndex:8 withObject:fileName];
        //ignore some win setting files
        if([fileName isEqualToString:@"$RECYCLE.BIN"]||[fileName isEqualToString:@"desktop.ini"]||[fileName isEqualToString:@"Thumbs.db"])continue;

        //判断时间  5月 6日 7年---->data index
        //0-weekday 1-month 2-day 3-time 4-timeZone 5-year--->date
        if ([[data objectAtIndex:7]isEqualToString:[date objectAtIndex:5]]||
            [[data objectAtIndex:7]containsString:@":"]) {
            //NSLog(@"this year-%@;",[data objectAtIndex:8]);
            [self execCmd:[NSString stringWithFormat:@"mkdir ~/desktop/%@",
                           [chMon objectForKey:[data objectAtIndex:5]]]];
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/%@",fileName,[chMon objectForKey:[data objectAtIndex:5]]]];
        }else{
            [self execCmd:[NSString stringWithFormat:@"mkdir ~/desktop/%@",
                           [data objectAtIndex:7]]];
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/%@",fileName,[data objectAtIndex:7]]];
        }
        
    }
}
-(void)cleanByType{
    NSMutableArray* output=[NSMutableArray arrayWithArray:[[self execCmd:@"ls -l ~/desktop"]componentsSeparatedByString:@"\n"] ];
    if ([output count]<=1) {
        return;
    }
    //read file type
    NSString* image=[NSString stringWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"image" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString* document=[NSString stringWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"document" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString* video=[NSString stringWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"video" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString* music=[NSString stringWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"music" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    NSString* devolop=[NSString stringWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"devolop" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    
    //删去多余信息
    [output removeLastObject];//remove blank space
    [output removeObjectAtIndex:0];//remove file amount data
    //元素分割
    NSArray* fileNameArray=[[self execCmd:@"ls ~/desktop"]componentsSeparatedByString:@"\n"];
    //fileNameArray的有效长度和output一样
    //NSLog(@"array length is %lu,%lu",(unsigned long)[output count],(unsigned long)[fileNameArray count]);
    //[self execCmd:@"mkdir ~/desktop/output/图像;mkdir ~/desktop/output/文稿;mkdir ~/desktop/output/视频;mkdir ~/desktop/output/音乐;mkdir ~/desktop/output/开发;mkdir ~/desktop/output/文件夹;mkdir ~/desktop/output/其他杂项"];
    for(int j=0;j<[output count];++j){
        NSMutableArray* data=[NSMutableArray arrayWithArray:[(NSString*)[output objectAtIndex:j] componentsSeparatedByString:@" "]];
        [data removeObject:@""];
        //下面处理文件名
        NSString* fileName=[self dealSpecChar:[fileNameArray objectAtIndex:j]];
        [data replaceObjectAtIndex:8 withObject:fileName];
        
        //下面处理文件后缀
        NSArray* fileType=[[data objectAtIndex:8]componentsSeparatedByString:@"."];
        if ([fileType count]>1) {
            NSLog(@"文件名:%@后缀:%@",[data objectAtIndex:8],[fileType lastObject]);
        }
        //文件分类：图像，文稿，视频，音乐，开发，文件夹，其他杂项
        //判断是非是文件夹，文件夹data第二项大于2
        //searchType的作用：避免开发中的.m被归类到音乐中.mp3的错误
        NSString* searchType=[NSString stringWithFormat:@".%@.",[fileType lastObject]];
        
        if([[data objectAtIndex:1]isNotEqualTo:@"1"]){//文件夹
            [self execCmd:@"mkdir ~/desktop/文件夹"];
            //NSLog(@"%@移入文件夹",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/文件夹",fileName]];
        }else if([image localizedCaseInsensitiveContainsString:searchType]){
            [self execCmd:@"mkdir ~/desktop/图像"];
            //NSLog(@"%@移入图像",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/图像",fileName]];
        }else if([document localizedCaseInsensitiveContainsString:searchType]){
            [self execCmd:@"mkdir ~/desktop/文稿"];
            //NSLog(@"%@移入文稿",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/文稿",fileName]];
        }else if([video localizedCaseInsensitiveContainsString:searchType]){
            [self execCmd:@"mkdir ~/desktop/视频"];
            //NSLog(@"%@移入视频",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/视频",fileName]];
        }else if([music localizedCaseInsensitiveContainsString:searchType]){
            [self execCmd:@"mkdir ~/desktop/音乐"];
            //NSLog(@"%@移入音乐",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/音乐",fileName]];
        }else if([devolop localizedCaseInsensitiveContainsString:searchType]){
            [self execCmd:@"mkdir ~/desktop/开发"];
            //NSLog(@"%@移入开发",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/开发",fileName]];
        }else{
            [self execCmd:@"mkdir ~/desktop/其他杂项"];
            //NSLog(@"%@移入其他",[fileType lastObject]);
            [self execCmd:[NSString stringWithFormat:@"mv ~/desktop/%@ ~/desktop/其他杂项",fileName]];
        }
    }
}
-(void)clean{
    switch (mode) {
        case 1://by Type
            [self cleanByType];
            break;
        case 2://by Date
            [self cleanByDate];
            break;
        case 3://byDeep
            [self cleanByDeep];
            break;
        default:
            mode=1;
            [note setText:@"您的桌面文件会被按照文件类型整理"];
            break;
    }
}
- (void)keyDown:(NSEvent *)theEvent {
}

- (void)mouseDown:(NSEvent *)theEvent {
    SKNode* clickedNode=[self nodeAtPoint:[theEvent locationInNode:self]];
    SKAction* sound;
    if (clickedNode!=nil&&![clickedNode isEqualToNode:self]) {//如果是self会死循环
        [clickedNode mouseDown:theEvent];
        if ([clickedNode.name isEqualToString:@"byType"]) {
            byDeep.text=@"超清爽净化清理";
            byDate.text=@"按文件日期清理";
            byType.text=@"✔︎按文件类型清理";
            mode=1;
            [note setText:@"您的桌面文件会被按照文件类型整理"];
            sound=[SKAction playSoundFileNamed:@"裆里有腊肠.mov" waitForCompletion:NO];
            [self runAction:sound];
        }else if([clickedNode.name isEqualToString:@"byDate"]){
            byDeep.text=@"超清爽净化清理";
            byDate.text=@"✔︎按文件日期清理";
            byType.text=@"按文件类型清理";
            mode=2;
            [note setText:@"您的桌面文件会被按照文件修改时间整理"];
            sound=[SKAction playSoundFileNamed:@"港中意玩.mov" waitForCompletion:NO];
            [self runAction:sound];
        }else if([clickedNode.name isEqualToString:@"byDeep"]){
            byDeep.text=@"✔︎超清爽净化清理";
            byDate.text=@"按文件日期清理";
            byType.text=@"按文件类型清理";
            mode=3;
            [note setText:@"您的所有桌面文件会被整理至一个文件夹内"];
            sound=[SKAction playSoundFileNamed:@"肛到我听到为止.mov" waitForCompletion:NO];
            [self runAction:sound];
        }else if([clickedNode.name isEqualToString:@"clean"]){
            [self clean];
            sound=[SKAction playSoundFileNamed:@"我要艹你啊.mov" waitForCompletion:NO];
            [self runAction:sound];
            SKAction* playmov=[SKAction animateWithTextures:[cleanGif copy] timePerFrame:0.09 resize:NO restore:NO];
            [scr runAction:playmov];
        }
    }
}
-(void)mouseUp:(NSEvent *)event{
    SKNode* clickedNode=[self nodeAtPoint:[event locationInNode:self]];
    if (clickedNode!=nil&&![clickedNode isEqualToNode:self]) {//如果是self会死循环
        [clickedNode mouseUp:event];
    }
}


-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
}

@end
