//
//  ExampleTableViewController.m
//  Example
//
//  Created by Max Goedjen on 11/13/12.
//
//

#import "ExampleTableViewController.h"
#import "ExampleSectionHeaderView.h"
#import "ExampleTableViewCell.h"

@implementation ExampleTableViewController

- (void)loadView {
	self.view = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
}

- (void)viewDidLoad {
	self.tableView = [[TUITableView alloc] initWithFrame:self.view.frame];
	self.tableView.alwaysBounceVertical = YES;
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	[self.tableView reloadData];
	self.tableView.maintainContentOffsetAfterReload = YES;
	self.tableView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
	TUILabel *footerLabel = [[TUILabel alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 44)];
	footerLabel.alignment = TUITextAlignmentCenter;
	footerLabel.backgroundColor = [NSColor clearColor];
	footerLabel.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
	footerLabel.text = @"Example Footer View";
	self.tableView.footerView = footerLabel;
	
	[self.view addSubview:self.tableView];
}

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
	
	// Add an activity indicator to the header view with a 24x24 size.
	// Since we know the height of the header won't change we can pre-
	// pad it to 4. However, since the table view's width can change,
	// we'll create a layout constraint to keep the activity indicator
	// anchored 16px left of the right side of the header view.
	TUIActivityIndicatorView *indicator = [[TUIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 4, 24, 24)
																   activityIndicatorStyle:TUIActivityIndicatorViewStyleGray];
	[indicator addLayoutConstraint:[TUILayoutConstraint constraintWithAttribute:TUILayoutConstraintAttributeMaxX
																	 relativeTo:@"superview"
																	  attribute:TUILayoutConstraintAttributeMaxX
																		 offset:-16.0f]];
	
	// Add a simple embossing shadow to the white activity indicator.
	// This way, we can see it better on a bright background. Using
	// the standard layer property keeps the shadow stable through
	// animations.
	indicator.layer.shadowColor = [NSColor whiteColor].tui_CGColor;
	indicator.layer.shadowOffset = CGSizeMake(0, -1);
	indicator.layer.shadowOpacity = 1.0f;
	indicator.layer.shadowRadius = 1.0f;
	
	// We then add it as a subview and tell it to start animating.
	[header	addSubview:indicator];
	[indicator startAnimating];
	
	return header;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ExampleTableViewCell *cell = reusableTableCellOfClass(tableView, ExampleTableViewCell);
	
	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", (int)indexPath.row]];
	s.color = [NSColor blackColor];
	s.font = [NSFont fontWithName:@"HelveticaNeue" size:15];;
	[s setFont:[NSFont fontWithName:@"HelveticaNeue-Bold" size:15] inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
	cell.attributedString = s;
	
	return cell;
}

- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event {
	if([event clickCount] == 1) {
		// do something cool
		ExampleTableViewController *pushed = [[ExampleTableViewController alloc] initWithNibName:nil bundle:nil];
		[self.navigationController pushViewController:pushed animated:YES];
	}
	
	if(event.type == NSRightMouseUp){
		// show context menu
	}
}
- (BOOL)tableView:(TUITableView *)tableView shouldSelectRowAtIndexPath:(NSIndexPath *)indexPath forEvent:(NSEvent *)event{
	switch (event.type) {
		case NSRightMouseDown:
			return NO;
	}
	
	return YES;
}

-(BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	// return YES to enable row reordering by dragging; don't implement this method or return
	// NO to disable
	return YES;
}

-(void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	// update the model to reflect the changed index paths; since this example isn't backed by
	// a "real" model, after dropping a cell the table will revert to it's previous state
	NSLog(@"Move dragged row: %@ => %@", fromIndexPath, toIndexPath);
}

-(NSIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromPath toProposedIndexPath:(NSIndexPath *)proposedPath {
	// optionally revise the drag-to-reorder drop target index path by returning a different index path
	// than proposedPath.  if proposedPath is suitable, return that.  if this method is not implemented,
	// proposedPath is used by default.
	return proposedPath;
}

@end
