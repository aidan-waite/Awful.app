//
//  AwfulThread+AwfulMethods.m
//  Awful
//
//  Created by Sean Berry on 3/28/12.
//  Copyright (c) 2012 Regular Berry Software LLC. All rights reserved.
//

#import "AwfulThread+AwfulMethods.h"
#import "AwfulForum+AwfulMethods.h"
#import "AwfulParsing.h"

@implementation AwfulThread (AwfulMethods)

+(NSArray *)threadsForForum : (AwfulForum *)forum
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[AwfulThread entityName]];
    NSSortDescriptor *stickySort = [NSSortDescriptor sortDescriptorWithKey:@"stickyIndex" ascending:YES];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastPostDate" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(forum=%@) AND (isBookmarked==NO)", forum];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:stickySort, sort, nil]];
    [fetchRequest setPredicate:predicate];
    
    NSError *err = nil;
    NSArray *threads = [ApplicationDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&err];
    if(err != nil) {
        NSLog(@"failed to load threads %@", [err localizedDescription]);
        return [NSArray array];
    }
    return threads;
}

+ (void)removeOldThreadsForForum:(AwfulForum *)forum
{
    NSArray *threads = [AwfulThread threadsForForum:forum];
    for(AwfulThread *thread in threads) {
        if(!thread.isBookmarkedValue) {
            [ApplicationDelegate.managedObjectContext deleteObject:thread];
        }
    }
}

+(NSArray *)bookmarkedThreads
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[AwfulThread entityName]];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastPostDate" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isBookmarked==YES"];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    [fetchRequest setPredicate:predicate];
    
    NSError *err = nil;
    NSArray *threads = [ApplicationDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&err];
    if(err != nil) {
        NSLog(@"failed to load threads %@", [err localizedDescription]);
        return [NSArray array];
    }
    return threads;
}

+(void)removeBookmarkedThreads
{
    NSArray *threads = [AwfulThread bookmarkedThreads];
    for(AwfulThread *thread in threads) {
        [ApplicationDelegate.managedObjectContext deleteObject:thread];
    }
}

+(NSMutableArray *)parseBookmarkedThreadsWithData : (NSData *)data
{
    NSString *raw_str = StringFromSomethingAwfulData(data);
    NSData *converted = [raw_str dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:converted];
    
    NSMutableArray *threads = [[NSMutableArray alloc] init];
    NSMutableArray *existing_threads = [NSMutableArray arrayWithArray:[AwfulThread bookmarkedThreads]];
    
    NSString *xpathForThread = @"//tr[" HAS_CLASS(thread) "]";
    NSArray *post_strings = PerformRawHTMLXPathQuery(hpple.data, xpathForThread);
    
    for(NSString *thread_html in post_strings) {
        
        @autoreleasepool {
            
            TFHpple *thread_base = [[TFHpple alloc] initWithHTMLData:[thread_html dataUsingEncoding:NSUTF8StringEncoding]];
            
            TFHppleElement *tid_element = [thread_base searchForSingle:xpathForThread];
            NSString *tid = nil;
            if(tid_element != nil) {
                NSString *tid_str = [tid_element objectForKey:@"id"];
                if(tid_str == nil) {
                    // announcements don't have thread_ids, they get linked to announcement.php
                    // gonna disregard announcements for now
                    continue;
                } else {
                    tid = [tid_str substringFromIndex:6];
                }
            }
            
            if(tid != nil) {
                AwfulThread *thread = nil;
                for(AwfulThread *existing_thread in existing_threads) {
                    if([existing_thread.threadID isEqualToString:tid]) {
                        thread = existing_thread;
                        break;
                    }
                }
                
                [existing_threads removeObjectsInArray:threads];
                
                if(thread == nil) {
                    NSManagedObjectContext *moc = ApplicationDelegate.managedObjectContext;
                    thread = [AwfulThread insertInManagedObjectContext:moc];
                }
                
                thread.threadID = tid;
                thread.isBookmarkedValue = YES;
                
                [AwfulThread populateAwfulThread:thread fromBase:thread_base];
                [threads addObject:thread];
            }
        }
    }
    
    return threads;
}

+(NSMutableArray *)parseThreadsWithData : (NSData *)data forForum : (AwfulForum *)forum
{
    NSString *raw_str = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
    NSData *converted = [raw_str dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:converted];
    
    NSArray *subs = PerformRawHTMLXPathQuery(data, @"//table[@id='subforums']//tr[" HAS_CLASS(subforum) "]");
    if (subs.count > 0)
        [AwfulForum updateSubforums:subs inForum:forum];
    
    NSMutableArray *threads = [[NSMutableArray alloc] init];
    NSMutableArray *existing_threads = [NSMutableArray arrayWithArray:[AwfulThread threadsForForum:forum]];
    
    NSString *xpathForThread = @"//tr[" HAS_CLASS(thread) "]";
    NSArray *post_strings = PerformRawHTMLXPathQuery(hpple.data, @"//tr[" HAS_CLASS(thread) "]");
    
    for(NSString *thread_html in post_strings) {
        
        @autoreleasepool {
            
            TFHpple *thread_base = [[TFHpple alloc] initWithHTMLData:[thread_html dataUsingEncoding:NSUTF8StringEncoding]];
                        
            TFHppleElement *tid_element = [thread_base searchForSingle:xpathForThread];
            NSString *tid = nil;
            if(tid_element != nil) {
                NSString *tid_str = [tid_element objectForKey:@"id"];
                if(tid_str == nil) {
                    // announcements don't have thread_ids, they get linked to announcement.php
                    // gonna disregard announcements for now
                    continue;
                } else {
                    tid = [tid_str substringFromIndex:6];
                }
            }
            
            if(tid != nil) {
                AwfulThread *thread = nil;
                for(AwfulThread *existing_thread in existing_threads) {
                    if([existing_thread.threadID isEqualToString:tid]) {
                        thread = existing_thread;
                        break;
                    }
                }
                
                [existing_threads removeObjectsInArray:threads];
                
                if(thread == nil) {
                    NSManagedObjectContext *moc = ApplicationDelegate.managedObjectContext;
                    thread = [AwfulThread insertInManagedObjectContext:moc];
                }
                
                thread.forum = forum;
                thread.threadID = tid;
                thread.isBookmarkedValue = NO;
                
                // will override this with NSNotFound if not stickied from inside 'populateAwfulThread'
                [thread setStickyIndex:[NSNumber numberWithInt:[threads count]]]; 
                
                [AwfulThread populateAwfulThread:thread fromBase:thread_base];
                [threads addObject:thread];
            }
        }
    }
    
    return threads;
}

+ (void)populateAwfulThread:(AwfulThread *)thread fromBase:(TFHpple *)thread_base
{
    TFHppleElement *title = [thread_base searchForSingle:@"//a[" HAS_CLASS(thread_title) "]"];
    if(title != nil) {
        thread.title = [title content];
    }
    
    TFHppleElement *sticky = [thread_base searchForSingle:@"//td[" HAS_CLASS(title_sticky) "]"];
    if(sticky == nil) {
        thread.stickyIndexValue = NSNotFound;
    }
    
    TFHppleElement *icon = [thread_base searchForSingle:@"//td[" HAS_CLASS(icon) "]/img"];
    if(icon != nil) {
        NSString *icon_str = [icon objectForKey:@"src"];
        thread.threadIconImageURL = [NSURL URLWithString:icon_str];
    } else {
        // Film Dump rating.
        TFHppleElement *rating = [thread_base searchForSingle:@"//td[" HAS_CLASS(rating) "]/img[contains(@src, '/rate/reviews')]"];
        if (rating) {
            thread.threadIconImageURL = [NSURL URLWithString:[rating objectForKey:@"src"]];
        }
    }
    
    TFHppleElement *icon2 = [thread_base searchForSingle:@"//td[" HAS_CLASS(icon2) "]/img"];
    if(icon2 != nil) {
        NSString *icon2_str = [icon2 objectForKey:@"src"];
        thread.threadIconImageURL2 = [NSURL URLWithString:icon2_str];
    }
    
    TFHppleElement *author = [thread_base searchForSingle:@"//td[" HAS_CLASS(author) "]/a"];
    if(author != nil) {
        thread.authorName = [author content];
    }
    
    [thread setSeen:[NSNumber numberWithBool:NO]];
    TFHppleElement *seen = [thread_base searchForSingle:@"//tr[" HAS_CLASS(seen) "]"];
    if(seen != nil) {
        thread.seenValue = YES;
    }
    
    TFHppleElement *locked = [thread_base searchForSingle:@"//tr[" HAS_CLASS(closed) "]"];
    if(locked != nil) {
        thread.isLockedValue = YES;
    }
    
    thread.starCategory = [NSNumber numberWithInt:AwfulStarCategoryNone];
    TFHppleElement *cat_zero = [thread_base searchForSingle:@"//tr[" HAS_CLASS(category0) "]"];
    if(cat_zero != nil) {
        thread.starCategoryValue = AwfulStarCategoryBlue;
    }
    
    TFHppleElement *cat_one = [thread_base searchForSingle:@"//tr[" HAS_CLASS(category1) "]"];
    if(cat_one != nil) {
        thread.starCategoryValue = AwfulStarCategoryRed;
    }
    
    TFHppleElement *cat_two = [thread_base searchForSingle:@"//tr[" HAS_CLASS(category2) "]"];
    if(cat_two != nil) {
        thread.starCategoryValue = AwfulStarCategoryYellow;
    }
    
    thread.totalUnreadPosts = [NSNumber numberWithInt:-1];
    TFHppleElement *unread = [thread_base searchForSingle:@"//a[" HAS_CLASS(count) "]/b"];
    if(unread != nil) {
        NSString *unread_str = [unread content];
        thread.totalUnreadPostsValue = [unread_str intValue];
    } else {
        unread = [thread_base searchForSingle:@"//a[" HAS_CLASS(x) "]"];
        if(unread != nil) {
            // they've read it all
            thread.totalUnreadPostsValue = 0;
        }
    }
    
    TFHppleElement *total = [thread_base searchForSingle:@"//td[" HAS_CLASS(replies) "]/a"];
    if(total != nil) {
        thread.totalRepliesValue = [[total content] intValue];
    } else {
        total = [thread_base searchForSingle:@"//td[" HAS_CLASS(replies) "]"];
        if(total != nil) {
            thread.totalRepliesValue = [[total content] intValue];
        }
    }
    
    //thread.threadRatingValue = NSNotFound;
    TFHppleElement *rating = [thread_base searchForSingle:@"//td[" HAS_CLASS(rating) "]/img"];
    if(rating != nil) {
        NSString *rating_str = [rating objectForKey:@"title"];
        NSError *regex_error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]+) votes - ([0-9\\.]+) average"           
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&regex_error];
        
        NSTextCheckingResult *match = [regex firstMatchInString:rating_str
                                                        options:0
                                                          range:NSMakeRange(0, rating_str.length)];
        if (match) {
            NSString *numVotes = [rating_str substringWithRange:[match rangeAtIndex:1]];
            NSString *average = [rating_str substringWithRange:[match rangeAtIndex:2]];
            //NSLog(@"%@; %@",numVotes, average);
            
            thread.threadVotesValue = numVotes.intValue;
            thread.threadRating = [NSDecimalNumber decimalNumberWithString:average];
        }

        
    }
    
    TFHppleElement *date = [thread_base searchForSingle:@"//td[" HAS_CLASS(lastpost) "]//div[" HAS_CLASS(date) "]"];
    TFHppleElement *last_author = [thread_base searchForSingle:@"//td[" HAS_CLASS(lastpost) "]//a[" HAS_CLASS(author) "]"];
    
    if(date != nil && last_author != nil) {
        thread.lastPostAuthorName = [NSString stringWithFormat:@"%@", [last_author content]];
        
        static NSDateFormatter *df = nil;
        if (df == nil) {
            df = [[NSDateFormatter alloc] init];
            [df setTimeZone:[NSTimeZone localTimeZone]];
            [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        }
        static NSString *formats[] = {
            @"h:mm a MMM d, yyyy",
            @"HH:mm MMM d, yyyy",
        };
        for (size_t i = 0; i < sizeof(formats) / sizeof(formats[0]); i++) {
            [df setDateFormat:formats[i]];
            NSDate *myDate = [df dateFromString:[date content]];
            if(myDate != nil) {
                thread.lastPostDate = myDate;
                break;
            }
        }
    }
}

-(NSURL *)firstIconURL
{
    if(self.threadIconImageURL == nil) {
        return nil;
    }
    
    NSString *minus_extension = [[self.threadIconImageURL lastPathComponent] stringByDeletingPathExtension];
    NSURL *tag_url = [[NSBundle mainBundle] URLForResource:minus_extension withExtension:@"png"];
    return tag_url;
}

-(NSURL *)secondIconURL
{
    if(self.threadIconImageURL2 == nil) {
        return nil;
    }
    
    NSString *minus_extension = [[self.threadIconImageURL2 lastPathComponent] stringByDeletingPathExtension];
    NSURL *tag_url = [[NSBundle mainBundle] URLForResource:[minus_extension stringByAppendingString:@"-secondary"] withExtension:@"png"];
    return tag_url;
}

@end
