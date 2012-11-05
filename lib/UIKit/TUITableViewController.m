/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUITableViewController.h"

@interface TUITableViewController ()

@property (nonatomic, assign) TUITableViewStyle style;

@end

@implementation TUITableViewController

@dynamic view;

- (id)init {
	return [self initWithStyle:TUITableViewStylePlain];
}

- (id)initWithStyle:(TUITableViewStyle)style {
	if((self = [super init])) {
		_style = style;
	}
	
	return self;
}

- (void)loadView {
	self.view = [[TUITableView alloc] initWithFrame:CGRectZero style:self.style];
	
	self.view.delegate = self;
	self.view.dataSource = self;
	
	self.view.maintainContentOffsetAfterReload = YES;
	self.view.needsDisplayWhenWindowsKeyednessChanges = YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.view reloadData];
	if(self.clearsSelectionOnViewWillAppear) {
		[self.view deselectRowAtIndexPath:self.view.indexPathForSelectedRow animated:animated];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self.view flashScrollIndicators];
}

- (NSInteger)tableView:(TUITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p | TUITableView = %@>", self.class, self, self.view];
}

@end
