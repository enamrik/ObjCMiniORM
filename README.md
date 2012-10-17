###About

ObjCMiniORM is a mini-ORM and database migration tool for iOS that works with Sqlite3.

###Getting Started

To get started, add the **libsqlite3.0.dylib** framework to your project. Then copy the following files to your project:

* MORepository.h
* MORepository.m
* MODbModelMeta.h
* MODbModelMeta.h

To use the migration feature, also add the following files to your project:

* MODbMigrator.h
* MODbMigrator.m

###Connecting to a Database

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
	
###Working with Objects

If **MODbModelMeta** isn't being used for manual mapping, ObjCMiniORM uses certain conventions for mapping objects. These conventions are:

* The class name much be the same as the table name
* A primary key is required, must be an integer and must be named <table-name>id

Given the following object:

	@interface Contact : NSObject
	@property int contactId;
	@property(copy)NSString*fullName;
	@property(strong)NSDate* addedOn;
	@end
	
	@implementation Contact
	//assume ARC and auto-syn properties
	@end
	
and schema:

	CREATE TABLE contact
	(
		contactid INTEGER PRIMARY KEY, 
		fullName TEXT, 
		addedOn NUMBER
	)

new records can be added as follows:

    Contact *contact=[][[Contact alloc]init]autorelease];
    contact.fullName = @"Name";
    contact.addedOn = [NSDate date];
	[repository commit:contact];

or updated as follows:

	NSArray* results =[repository
	   query:@"select * from contact where contactId  = ?"
	   withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:1]]
	   forType:[Contact class]];
	   
	Contact *contact=[results objectAtIndex:1];
	contact.fullName = @"Change Name";
	[repository commit:contact];
	
###Customizing Model Metadata

**MODbModelMeta** is used for manually mapping models and properties which overrides the conventions **MORepository** uses:

    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    
    //register a model
    [meta modelAddByType:Contact.class];
    
    //change the name of the mapped table
    [meta modelSetTableName:@"tblContact"];
    
    //change the table column that is mapped to a property
    [meta propertySetCurrentByName:@"ContactId"];
    [meta propertySetColumnName:@"Id"];
    
    //change which column is the primary key
    [meta propertySetCurrentByName:@"AnotherId"];
    [meta propertySetIsKey:true];
    
    //give the metadata to a repository
	[self.repository mergeModelMeta:meta];
	
	
###Migrations

**MODbMigrator** is used to update a database. A **MODbModelMeta** object must be used to specify which classes are mapped to database tables.

    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByType:Contact.class];
    [meta modelAddByType:Animal.class];
    
    //requires an already opened MORepository
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:self.repository andMeta:meta]autorelease];
    [migrator updateDatabaseAndRunScripts:true];
    
**MODbMigrator** can also run script files. Script files are only run once and are tracked in a database table to make sure they're never run again. Thes script files can be flagged as needing to run before or after the model update. Any object can be a script file if it implements the protocol **IScriptFile**. Script files are added to the **MODbMigrator** using the method `registerScriptFile:(id<IScriptFile>)scriptFile`.







