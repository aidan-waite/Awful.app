//  AwfulPostPreviewViewController.h
//
//  Copyright 2014 Awful Contributors. CC BY-NC-SA 3.0 US https://github.com/Awful/Awful.app

#import "UIViewController+AwfulTheme.h"
#import "AwfulModels.h"
@class Post;

/**
 * An AwfulPostPreviewViewController previews a post (new or edited).
 */
@interface AwfulPostPreviewViewController : AwfulViewController

/**
 * Preview editing a post. One of two designated initializers.
 */
- (id)initWithPost:(Post *)post BBcode:(NSAttributedString *)BBcode;

/**
 * Preview a new post. One of two designated initializers.
 */
- (id)initWithThread:(AwfulThread *)thread BBcode:(NSAttributedString *)BBcode;

@property (readonly, strong, nonatomic) Post *editingPost;

@property (readonly, strong, nonatomic) AwfulThread *thread;

@property (readonly, copy, nonatomic) NSAttributedString *BBcode;

/**
 * A block to call if submission is to continue.
 */
@property (copy, nonatomic) void (^submitBlock)(void);

@end

@interface AwfulPostPreviewViewController (SubclassingHooks)

- (id)initWithBBcode:(NSAttributedString *)BBcode;
- (void)fetchPreviewIfNecessary;
- (void)renderPreview;
@property (readonly, strong, nonatomic) Post *fakePost;
@property (readonly, strong, nonatomic) UIWebView *webView;

@end
