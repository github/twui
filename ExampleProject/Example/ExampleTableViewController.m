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

#import "ExampleTableViewController.h"
#import "ExampleSectionHeaderView.h"
#import "ExampleTableViewCell.h"

@implementation ExampleTableViewController

// Configure the table view to autoresize and keep its content offset
// after a reload. Add a footer label to the table view as well.
- (void)viewDidLoad {
	self.view.maintainContentOffsetAfterReload = YES;
	self.view.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
	TUILabel *footerLabel = [[TUILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
	footerLabel.alignment = TUITextAlignmentCenter;
	footerLabel.backgroundColor = [NSColor clearColor];
	footerLabel.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
	footerLabel.text = @"Example Footer View";
	self.view.footerView = footerLabel;
}

// Configure the number of sections and rows in the table view, along with per-row heights.
- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView {
	return 8;
}

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section {
	return 25;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 50.0;
}

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section {
	ExampleSectionHeaderView *header = [[ExampleSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
	TUIAttributedString *title = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"Example Section %d", (int)section]];
	title.color = [NSColor blackColor];
	title.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
	header.labelRenderer.attributedString = title;
	
	// Dragging a title can drag the window too.
	[header setMoveWindowByDragging:YES];
	
	return header;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ExampleTableViewCell *cell = reusableTableCellOfClass(tableView, ExampleTableViewCell);
	
	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", (int)indexPath.row]];
	s.alignment = TUITextAlignmentCenter;
	s.color = [NSColor blackColor];
	s.font = [NSFont fontWithName:@"HelveticaNeue" size:15];;
	[s setFont:[NSFont fontWithName:@"HelveticaNeue-Bold" size:15] inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
	cell.attributedString = s;
	
	return cell;
}

// If a cell is clicked, push another table view controller from our navigation controller.
// Otherwise, if the cell was right-clicked, you may optionally show a menu.
- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event {
	if(event.type == NSRightMouseUp) {
		// Show context menu.
		
	} else if([event clickCount] == 1) {
		ExampleTableViewController *pushed = [[ExampleTableViewController alloc] initWithStyle:TUITableViewStylePlain];
		[self.navigationController pushViewController:pushed animated:YES];
	}
}

// Override this delegate method to return NO to disable cell selection.
- (BOOL)tableView:(TUITableView *)tableView shouldSelectRowAtIndexPath:(NSIndexPath *)indexPath forEvent:(NSEvent *)event{
	return NO;
}

// Override this delegate method to return YES to enable row reordering
// by dragging; either don't implement this method or return NO to disable it.
- (BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

// Update the model to reflect the changed index paths; since this example isn't backed by
// a "real" model, after dropping a cell the table will revert to it's previous state.
- (void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
	  toIndexPath:(NSIndexPath *)toIndexPath {
	
	NSLog(@"Move dragged row: %@ => %@", fromIndexPath, toIndexPath);
}

// Optionally revise the drag-to-reorder drop target index path by returning a
// different index path than the proposedPath. If proposedPath is suitable,
// return that. If this method is not implemented, proposedPath is used by default.
- (NSIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromPath toProposedIndexPath:(NSIndexPath *)proposedPath {
	
	return proposedPath;
}

@end
