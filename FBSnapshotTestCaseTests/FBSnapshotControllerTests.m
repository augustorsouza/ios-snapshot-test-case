/*
 *  Copyright (c) 2017-2018, Uber Technologies, Inc.
 *  Copyright (c) 2015-2018, Facebook, Inc.
 *
 *  This source code is licensed under the MIT license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <XCTest/XCTest.h>
#import "FBSnapshotTestController.h"
#import "FBSnapshotTestCasePlatform.h"

@interface FBSnapshotControllerTests : XCTestCase

@end

@implementation FBSnapshotControllerTests

#pragma mark - Tests

- (void)testCompareReferenceImageToImageShouldBeEqual
{
    UIImage *referenceImage = [self _bundledImageNamed:@"square" type:@"png"];
    XCTAssertNotNil(referenceImage);
    UIImage *testImage = [self _bundledImageNamed:@"square-copy" type:@"png"];
    XCTAssertNotNil(testImage);

    FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
    NSError *error = nil;
    XCTAssertTrue([controller compareReferenceImage:referenceImage toImage:testImage tolerance:0 error:&error]);
    XCTAssertNil(error);
}

- (void)testCompareReferenceImageToImageShouldNotBeEqual
{
    UIImage *referenceImage = [self _bundledImageNamed:@"square" type:@"png"];
    XCTAssertNotNil(referenceImage);
    UIImage *testImage = [self _bundledImageNamed:@"square_with_text" type:@"png"];
    XCTAssertNotNil(testImage);

    FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
    NSError *error = nil;
    XCTAssertFalse([controller compareReferenceImage:referenceImage toImage:testImage tolerance:0 error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, FBSnapshotTestControllerErrorCodeImagesDifferent);
}

- (void)testCompareReferenceImageWithVeryLowToleranceShouldNotMatch
{
    UIImage *referenceImage = [self _bundledImageNamed:@"square" type:@"png"];
    XCTAssertNotNil(referenceImage);
    UIImage *testImage = [self _bundledImageNamed:@"square_with_pixel" type:@"png"];
    XCTAssertNotNil(testImage);

    FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
    // With virtually no margin for error, this should fail to be equal
    NSError *error = nil;
    XCTAssertFalse([controller compareReferenceImage:referenceImage toImage:testImage tolerance:0.0001 error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, FBSnapshotTestControllerErrorCodeImagesDifferent);
}

- (void)testCompareReferenceImageWithVeryLowToleranceShouldMatch
{
    UIImage *referenceImage = [self _bundledImageNamed:@"square" type:@"png"];
    XCTAssertNotNil(referenceImage);
    UIImage *testImage = [self _bundledImageNamed:@"square_with_pixel" type:@"png"];
    XCTAssertNotNil(testImage);

    FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
    // With some tolerance these should be considered the same
    NSError *error = nil;
    XCTAssertTrue([controller compareReferenceImage:referenceImage toImage:testImage tolerance:.001 error:&error]);
    XCTAssertNil(error);
}

- (void)testCompareReferenceImageWithDifferentSizes
{
  UIImage *referenceImage = [self _bundledImageNamed:@"square" type:@"png"];
  XCTAssertNotNil(referenceImage);
  UIImage *testImage = [self _bundledImageNamed:@"rect" type:@"png"];
  XCTAssertNotNil(testImage);
  
  FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
  // With some tolerance these should be considered the same
  NSError *error = nil;
  XCTAssertFalse([controller compareReferenceImage:referenceImage toImage:testImage tolerance:0 error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSnapshotTestControllerErrorCodeImagesDifferentSizes);
}

- (void)testFailedImageWithDeviceAgnosticShouldHaveModelOnName
{
  UIImage *referenceImage = [self _bundledImageNamed:@"square" type:@"png"];
  XCTAssertNotNil(referenceImage);
  UIImage *testImage = [self _bundledImageNamed:@"square_with_pixel" type:@"png"];
  XCTAssertNotNil(testImage);
  
  FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
  [controller setDeviceAgnostic:YES];
  [controller setReferenceImagesDirectory:@"/dev/null/"];
  NSError *error = nil;
  SEL selector = @selector(isDeviceAgnostic);
  [controller referenceImageForSelector:selector identifier:@"" error:&error];
  XCTAssertNotNil(error);
  NSString *deviceAgnosticReferencePath = FBDeviceAgnosticNormalizedFileName(NSStringFromSelector(selector));
  XCTAssertTrue([(NSString *)[error.userInfo objectForKey:FBReferenceImageFilePathKey] containsString:deviceAgnosticReferencePath]);
}

- (void)testImageWithoutSuffixIfAgnosticOptionIsUsed
{
  FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
  [controller setDeviceAgnostic:YES];
  [controller setAgnosticOptions:FBSnapshotTestCaseAgnosticOptionScreenScale];
  [controller setReferenceImagesDirectory:@"/dev/null/"];
  NSError *error = nil;
  SEL selector = @selector(isDeviceAgnostic);
  [controller referenceImageForSelector:selector identifier:@"" error:&error];
  XCTAssertNotNil(error);
  NSString *imageFilePath = (NSString *)[error.userInfo objectForKey:FBReferenceImageFilePathKey];
  XCTAssertTrue([[imageFilePath componentsSeparatedByString:@"@"] count] == 1);
}

- (void)testImageWithSuffixIfAgnosticOptionIsNotUsed
{
  FBSnapshotTestController *controller = [[FBSnapshotTestController alloc] initWithTestClass:nil];
  [controller setDeviceAgnostic:YES];
  [controller setReferenceImagesDirectory:@"/dev/null/"];
  NSError *error = nil;
  SEL selector = @selector(isDeviceAgnostic);
  [controller referenceImageForSelector:selector identifier:@"" error:&error];
  XCTAssertNotNil(error);
  NSString *imageFilePath = (NSString *)[error.userInfo objectForKey:FBReferenceImageFilePathKey];
  XCTAssertTrue([[imageFilePath componentsSeparatedByString:@"@"] count] == 2);
}

#pragma mark - Private helper methods

- (UIImage *)_bundledImageNamed:(NSString *)name type:(NSString *)type
{
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:name ofType:type];
  NSData *data = [[NSData alloc] initWithContentsOfFile:path];
  return [[UIImage alloc] initWithData:data];
}

@end
