//
// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <AppAuth/AppAuth.h>
#import <FirebaseAppDistribution/FIRAppDistributionAuthPersistence+Private.h>
#import <FirebaseAppDistribution/FIRAppDistributionKeychainUtility+Private.h>

@interface FIRAppDistributionAuthPersistenceTests : XCTestCase
@end

@implementation FIRAppDistributionAuthPersistenceTests {
  NSMutableDictionary *_mockKeychainQuery;
  id _mockAuthorizationData;
  id _mockOIDAuthState;
  id _mockKeychainProtocol;
  id _partialMockAuthPersitence;
}

- (void)setUp {
  [super setUp];
  _mockKeychainQuery = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:(id)@"thing one", (id)@"another thing", nil];
  _mockKeychainProtocol = OCMProtocolMock(@protocol(FIRAppDistributionKeychainProtocol));
  _mockAuthorizationData = [@"this is some password stuff" dataUsingEncoding:NSUTF8StringEncoding];
  _mockOIDAuthState = OCMClassMock([OIDAuthState class]);
  OCMStub(ClassMethod([_mockKeychainProtocol unarchiveKeychainResult])).andReturn(_mockOIDAuthState);
  OCMStub(ClassMethod([_mockKeychainProtocol archiveDataForKeychain])).andReturn(_mockAuthorizationData);

  _partialMockAuthPersitence = OCMClassMock([FIRAppDistributionAuthPersistence class]);
  OCMStub(ClassMethod([_partialMockAuthPersitence keychainUtility])).andReturn(_mockKeychainProtocol);
  OCMStub(ClassMethod([_partialMockAuthPersitence handleAuthStateError])).andForwardToRealObject();
  OCMStub(ClassMethod([_partialMockAuthPersitence persistAuthState])).andForwardToRealObject();
  OCMStub(ClassMethod([_partialMockAuthPersitence clearAuthState])).andForwardToRealObject();
  OCMStub(ClassMethod([_partialMockAuthPersitence retrieveAuthState])).andForwardToRealObject();
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
  [super tearDown];
  [_mockAuthorizationData stopMocking];
  [_mockOIDAuthState stopMocking];
  [_mockKeychainProtocol stopMocking];
  [_partialMockAuthPersitence stopMocking];
}

- (void)testPersistAuthStateSuccess {
  OCMStub(ClassMethod([_mockKeychainProtocol addKeychainItem])).andReturn(YES);
  NSError *error;
  BOOL success = [_partialMockAuthPersitence persistAuthState:_mockOIDAuthState error:&error]
  XCTAssertTrue(success);
  XCTAssertNil(error);
}

- (void)testPersistAuthStateFailure {
  OCMStub(ClassMethod([_mockKeychainProtocol addKeychainItem])).andReturn(NO);
  NSError *error;
  BOOL success = [_partialMockAuthPersitence persistAuthState:_mockOIDAuthState error:&error]
  XCTAssertFalse(success);
  XCTAssertNotNil(error);
  XCTAssertEqual([error domain], kFIRAppDistributionKeychainErrorDomain)
  XCTAssertEqual([error code], FIRAppDistributionErrorTokenPersistenceFailure)
}

- (void)testOverwriteAuthStateSuccess {
  OCMStub(ClassMethod([_mockKeychainProtocol fetchKeychainItemMatching])).andDo(^BOOL(NSMutableDictionary *keychainQuery, NSData *data){
    data = _mockAuthorizationData;
    return YES;
  });
  OCMStub(ClassMethod([_mockKeychainProtocol updateKeychainItem])).andReturn(YES);
  NSError *error;
  BOOL success = [_partialMockAuthPersitence persistAuthState:_mockOIDAuthState error:&error]
  XCTAssertTrue(success);
  XCTAssertNil(error);
}

- (void)testOverwriteAuthStateFailure {
  OCMStub(ClassMethod([_mockKeychainProtocol fetchKeychainItemMatching])).andDo(^BOOL(NSMutableDictionary *keychainQuery, NSData *data){
    data = _mockAuthorizationData;
    return YES;
  });
  OCMStub(ClassMethod([_mockKeychainProtocol updateKeychainItem])).andReturn(NO);
  NSError *error;
  BOOL success = [_partialMockAuthPersitence persistAuthState:_mockOIDAuthState error:&error]
  XCTAssertFalse(success);
  XCTAssertNotNil(error);
  XCTAssertEqual([error domain], kFIRAppDistributionKeychainErrorDomain)
  XCTAssertEqual([error code], FIRAppDistributionErrorTokenPersistenceFailure)
}

- (void) testRetrieveAuthStateSuccess {
  OCMStub(ClassMethod([_mockKeychainProtocol fetchKeychainItemMatching])).andDo(^BOOL(NSMutableDictionary *keychainQuery, NSData *data){
    data = _mockAuthorizationData;
    return YES;
  });
  NSError *error;
  OIDAuthState *authState = [_partialMockAuthPersitence retrieveAuthState:&error]
  XCTAssertTrue([authState isKindOfClass:[OIDAuthState class]]);
  XCTAssertNil(error);
}


- (void) testRetrieveAuthStateFailure {
  OCMStub(ClassMethod([_mockKeychainProtocol fetchKeychainItemMatching])).andReturn(nil);
  NSError *error;
  BOOL success = [_partialMockAuthPersitence retrieveAuthState:&error]
  XCTAssertFalse(success);
  XCTAssertNotNil(error);
  XCTAssertEqual([error domain], kFIRAppDistributionKeychainErrorDomain)
  XCTAssertEqual([error code], FIRAppDistributionErrorTokenRetrievalFailure)
}


- (void) testClearAuthStateSuccess {
  OCMStub(ClassMethod([_mockKeychainProtocol clearAuthState])).andDo(^BOOL(NSMutableDictionary *keychainQuery, NSData *data){
    data = _mockAuthorizationData;
    return YES;
  });
  NSError *error;
  BOOL success = [_partialMockAuthPersitence clearAuthState:&error]
  XCTAssertTrue(success);
  XCTAssertNil(error);
}


- (void) testClearAuthStateFailure {
  OCMStub(ClassMethod([_mockKeychainProtocol retrieveAuthState])).andReturn(NO);
  NSError *error;
  BOOL success = [_partialMockAuthPersitence clearAuthState:&error]
  XCTAssertFalse(success);
  XCTAssertNotNil(error);
  XCTAssertEqual([error domain], kFIRAppDistributionKeychainErrorDomain)
  XCTAssertEqual([error code], FIRAppDistributionErrorTokenDeletionFailure)
}

@end
