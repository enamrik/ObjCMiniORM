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

You may setup a single instance of **MORepository** for your entire application or use one instance per controller or whatever works best for you.

To create a new repository, do the following:

    MORepository* repository = [[MORepository alloc]init];

Then you can open a connection to the database by calling:

	[repository open];
	
So where's the database? Well because the repository was created using the default constructor, a database named data.db is automatically created for you and stored in the Library folder of your application. If a database with that name already exits in the Library folder, it won't be overriden but will be used instead. This is a nice feature for getting prototypes up quickly. If you would like to specify the path to an existing database, pass the path in when creating your repository:

    MORepository* repository = [[MORepository alloc]initWithDBFilePath:pathAndName];
    
If the database does not exist at that path, one will be created at that path with the given name. More often than not, you'll want to package a database in you application bundle and have the repository copy that database to the application installation folder when the application starts up (this is a one time event). To do this create the repository this way:

    MORepository* repository = [[MORepository alloc]initWithBundleFile:name];
    
Creating the repository this way will cause the repository to first check the bundle for a database file with the specified name at the root of the bundle. If the database file is found in the bundle, it will be copied to the Library folder. If the file already exists in the Library folder, no copy takes place and the existing database will be used. If you want the database bundle file to be stored at a different path from the Library folder with a different name, then create your repository like this:

    MORepository* repository = [[MORepository alloc]initWithBundleFile:name dbFilePath:pathAndName];

To close the database, call the close method:

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