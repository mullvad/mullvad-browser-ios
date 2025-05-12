#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MullvadBrowser-Swift.h"


@interface URLBlocker_Tests : XCTestCase
@end

@implementation URLBlocker_Tests

- (void)testShouldBlockURL
{
	NSString *block;

	block = [URLBlocker.shared blockRuleFor:[NSURL URLWithString:@"https://twitter.com/"] withMain:nil];
	XCTAssertNotNil(block);

	block = [URLBlocker.shared blockRuleFor:[NSURL URLWithString:@"https://platform.twitter.com/widgets.js"] withMain:nil];
	XCTAssertNotNil(block);

	block = [URLBlocker.shared blockRuleFor:[NSURL URLWithString:@"https://platform.twitter-com/widgets.js"] withMain:nil];
	XCTAssertNil(block);
}

- (void)testNotBlockingFromSameSite
{
	NSString *block;

	block = [URLBlocker.shared blockRuleFor:[NSURL URLWithString:@"https://twitter.com/"] withMain:[NSURL URLWithString:@"https://www.twitter.com/"]];
	XCTAssert(block == nil);

	block = [URLBlocker.shared blockRuleFor:[NSURL URLWithString:@"https://platform.twitter.com/widgets.js"] withMain:[NSURL URLWithString:@"https://twitter.com/jcs/status/548344727771545600"]];
	XCTAssert(block == nil);

	block = [URLBlocker.shared blockRuleFor:[NSURL URLWithString:@"https://platform.twitter.com/widgets.js"] withMain:[NSURL URLWithString:@"https://jcs.org/statuses/2014/12/25/548344727771545600/"]];
	XCTAssert(block != nil);
}

@end
