###About

ObjCMiniORM is a mini-ORM for iOS that works with Sqlite3. It was the end result of a lot of Google searches and is continually being updated as I learn more about Objective-C and Sqlite. 

###Getting Started

To get started, add the **libsqlite3.0.dylib** framework to your project. Then copy the following files to your project:

* MORepository.h
* MORepository.m
* ModelProperty.h
* ModelProperty.m

###Usage

#####Connecting to a Database

Create a new repository:

	//creates sqlite database named data.db in Library folder
    MORepository* repository = [[MORepository alloc]init];

	//creates sqlite database in specified folder with specified file name
    MORepository* repository = [[MORepository alloc]initWithDBFilePath:pathAndName];

	//copies sqlite database from application bundle to Library folder
    MORepository* repository = [[MORepository alloc]initWithBundleFile:name];
    
    //copies sqlite database from application bundle to specified folder with specified file name
    MORepository* repository = [[MORepository alloc]initWithBundleFile:name dbFilePath:pathAndName];
    
Open a connection:

    [repository open];
    

Close connection:

	[repository close];
	
#####Working with Objects

ObjCMiniORM will work with any Objective-C object that contains properties. Your objects do not need to inherit from a base class. To a complish this, ObjCMiniORM depends on certain conventions. The most important is that the object must have the same name as the table in the database from which it will be loaded and each object/table must have an INTEGER PRIMARY KEY field named <table-name>id. This is a very strict convention which is not friendly to greenfield projects. Future versions of ObjCMiniORM will provide more ways to override these conventions through configuration.

Let's create an object:

	@interface Contact : NSObject
	@property int contactId;
	@property(copy)NSString*fullName;
	@property(strong)NSDate* addedOn;
	@end
	
	@implementation Contact
	//assume ARC and auto-syn properties
	@end
	
This object will only map to a table with the following schema:

	CREATE TABLE contact
	(
		contactid INTEGER PRIMARY KEY, 
		fullName TEXT, 
		addedOn NUMBER
	)

Note, every property on the object must have an associated field on the database table but not necessarily the other way around. Let's create our object:

    Contact *contact=[][[Contact alloc]init]autorelease];
    contact.fullName = self.txtContactName.text;
    contact.addedOn = [NSDate date];
    
To insert our new object, either user the **insert** method like so: 

	[repository insert:contact];
	
or use the **commit** method like so:

	[repository commit:contact];

The commit method is more convenient because it will perform an insert or update based on whether the primary key has a number greater than zero or not. To query the object, execute the following SQL:

	NSArray* results =[repository
	   query:@"select * from contact where contactId  = ?"
	   withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:1]]
	   forType:[Contact class]];

This will return to us an array of contacts. In our case this would be an array with a single item, the one we just created.

###Coming Soon!!

* A migrations framework that will generate update scripts by doing a diff between the database and the models. The migration framework will also support adding simple sql text and will keep track of scripts executed in a special database table
* More convenience methods for querying e.g.[repository getById:<id> forType:<class>]
* More configuration options for working with existing sqlite databases