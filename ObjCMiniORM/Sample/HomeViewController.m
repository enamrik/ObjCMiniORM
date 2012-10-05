//
//  HomeViewController.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/3/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "HomeViewController.h"
#import "MORepository.h"
#import "Contact.h"

@interface HomeViewController ()
@property(strong)MORepository*repository;
@property(strong)IBOutlet UIBarButtonItem *btnAddContact;
@property(strong)IBOutlet UITableView *tblContacts;
@property(strong)IBOutlet UITextField *txtContactName;
@property(strong)NSMutableArray* contacts;
@end

@implementation HomeViewController

-(void)dealloc{
    self.contacts=nil;
    self.btnAddContact=nil;
    self.tblContacts=nil;
    self.txtContactName=nil;
    self.repository=nil;
    [super dealloc];
}

- (id)initWithRepository:(MORepository*)repo{
    self = [super initWithNibName:@"HomeViewController" bundle:nil];
    if (self) {
        //create database using default path and name
        self.repository = repo;
        
        //check if contacts table exists
        BOOL tableExists =[[self.repository
            executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?;"
            withParameters:[NSArray arrayWithObject:@"contact"]] intValue] > 0;
        
        if(tableExists==false){
            //create contact table
            NSString*setupSql=@"create table contact(contactid integer primary key, fullName text, addedOn number)";
            [self.repository executeSQL:setupSql withParameters:nil];
        }
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self loadTableData];
}

-(IBAction)addContactAction:(id)sender{

    Contact *contact=[[Contact alloc]init];
    contact.fullName = self.txtContactName.text;
    contact.addedOn = [NSDate date];
    [self.repository commit:contact];
    [contact release];
    
    [self loadTableData];
    [self.tblContacts reloadData];
}

-(void)loadTableData{
    self.contacts = [[self.repository
        query:@"select * from contact order by addedOn desc"
        withParameters:nil
        forType:[Contact class]] mutableCopy];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView*)tableView{
	return 1;
}

-(NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger) section{
	return [self.contacts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 50.0f;
}

-(UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath{
    
	UITableViewCell *myCell;
	static NSString *defaultIdentifier=@"UITableViewCell";
     
    myCell=(UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:defaultIdentifier];
    if (myCell==nil) {
        myCell=[[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:defaultIdentifier]autorelease];
        [myCell setAccessoryType:UITableViewCellAccessoryNone];
    }

    Contact * contact = [self.contacts objectAtIndex:indexPath.row];
    myCell.textLabel.text = contact.fullName;
 	return  myCell;	
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
        Contact * contact = [self.contacts objectAtIndex:indexPath.row];
        [self.repository delete:contact];
		[self.contacts removeObjectAtIndex:indexPath.row];
		
		[self.tblContacts deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
            withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
