//
//  PCLoginVC.m
//  PassCapsule
//
//  Created by 邵建勇 on 15/5/20.
//  Copyright (c) 2015年 John Shaw. All rights reserved.
//

#import "PCLoginVC.h"
#import "EAIntroView.h"
#import "PCKeyChainUtils.h"
#import "PCDocumentDatabase.h"

#import "PCCloudManager.h"
#import "PCDocumentManager.h"


@interface PCLoginVC ()<UIGestureRecognizerDelegate,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *accountTextField;

@end

@implementation PCLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];

    BOOL isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLaunch"];
    if (isFirstLaunch) {
        //TODO:想想我这么丑的引导页还是干脆没有好了，以后弄个漂亮的
//        [self showIntroView];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isFirstLaunch"];
    }
    
    
    // tap for dismissing keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    // very important make delegate useful
    tap.delegate = self;
    
    self.passwordTextField.delegate = self;
    self.accountTextField.delegate = self;

}


-(void)showIntroView{
    //FIXME:美化引导页
    //    PCXMLcmp *test = [PCXMLcmp new];
    //    [test pcxmlcmptteesstt];
    EAIntroPage *page1   = [EAIntroPage page];
    page1.title          = NSLocalizedString(@"PassCapsule", @"name title");
    //    page1.titleColor = [UIColor colorWithRed:0.502 green:1.000 blue:0.000 alpha:1.000];
    page1.titlePositionY = 400;
    page1.descFont       = [UIFont fontWithName:@"Georgia-Italic" size:18];
    page1.desc           = @"安全密码管家";
    //    page1.descColor = [UIColor colorWithRed:0.502 green:1.000 blue:0.000 alpha:1.000];
    page1.descPositionY  = 300;
    page1.bgImage        = [UIImage imageNamed:@"bg1" ];
    
    EAIntroPage *page2   = [EAIntroPage page];
    page2.title          = @"三大特色";
    //    page2.titleColor = [UIColor colorWithWhite:0.600 alpha:1.000];
    page2.titlePositionY = 400;
    page2.descFont       = [UIFont fontWithName:@"Georgia-Italic" size:18];
    page2.desc           = @"分离式双重加密\n多用户支持\n云同步系统";
    //    page2.descColor =[UIColor colorWithWhite:0.600 alpha:1.000];
    page2.descPositionY  = 300;
    page2.bgImage        = [UIImage imageNamed:@"bg2"];
    
    EAIntroPage *page3   = [EAIntroPage page];
    page3.title          = @"立即登陆";
    //    page3.titleColor =[UIColor colorWithRed:0.251 green:0.502 blue:0.000 alpha:1.000];
    page3.titlePositionY = 400;
    page3.descFont       = [UIFont fontWithName:@"Georgia-Italic" size:18];
    page3.desc           = @"享受免费云同步服务";
    //    page3.descColor =[UIColor colorWithRed:0.251 green:0.502 blue:0.000 alpha:1.000];
    page3.descPositionY  = 300;
    page3.bgImage        = [UIImage imageNamed:@"bg3"];
    
    
    //    [self.introView  setSwipeToExit:NO];
    NSArray *pages= @[page1,page2,page3];
    EAIntroView *intro = [[EAIntroView alloc] initWithFrame:self.view.bounds andPages:pages];
    intro.pageControlY = 60;
    [intro showInView:self.view animateDuration:0.0];
}

#pragma mark - action
- (IBAction)login:(id)sender {
    NSString *name = self.accountTextField.text;
    NSString *password = self.passwordTextField.text;
    
    [AVUser logInWithUsername:name password:password error:nil];

    NSString *segueID = nil;
    
//    BOOL isCreateDB = [[NSUserDefaults standardUserDefaults] boolForKey:USERDEFAULT_DATABASE_CREATE];
//    if(isCreateDB){
//        segueID = @"toUnLockView";
//    } else {
//        segueID = @"toNewDocumentView";
//    }

    AVUser *current = [AVUser currentUser];
    if (current) {
        //do someting
        NSString *cloudID = [current objectForKey:CLOUD_DATABASE_ID];
        if (cloudID) {
            segueID = @"toUnLockView";
            PCDocumentManager *document = [PCDocumentManager sharedDocumentManager];
            PCCloudDatabase *cloudDatabase = [[PCCloudManager sharedCloudManager] queryCloudDatabaseByID:cloudID];
            
            BOOL createSuccess = [document syncDocumentFormCloudWithUser:current];
            if (createSuccess) {
                NSLog(@"create cloud database ok!");
            }

        } else {
            segueID = @"toNewDocumentView";
        }
        
    }
    [self performSegueWithIdentifier:segueID sender:self];
}


- (IBAction)registPress:(UIButton *)sender {
    UIViewController *descViewController =
    [self.storyboard instantiateViewControllerWithIdentifier:@"PCRegistNavigation"];
    
    [self presentViewController:descViewController animated:YES completion:nil];
}


#pragma mark - textField delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField isEqual:self.accountTextField]){
        [self.passwordTextField becomeFirstResponder];
    } else if([textField isEqual:self.passwordTextField]){
        [textField resignFirstResponder];
    }
    return YES;
}



#pragma mark - GestureRecognizer delegate
// tap dismiss keyboard
-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toNewDocumentView"]) {
       //todo
    }
    if ([segue.identifier isEqualToString:@"toUnLockView"]) {
        //todo
    }
}


@end
