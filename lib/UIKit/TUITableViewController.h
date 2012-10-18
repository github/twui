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

#import "TUIViewController.h"
#import "TUITableView.h"

// The TUITableViewController is a controller that manages a table view.
// When the table view is about to appear, it reloads the table view’s data.
// You create a custom subclass of TUITableViewController for each table
// view that you want to manage.
// 
// It also clears its selection (with or without animation, depending on 
// the request) every time the table view is displayed. You can disable
// this behavior by changing the value in the clearsSelectionOnViewWillAppear
// property. When the table view has appeared, the controller flashes the 
// table view's scroll indicators.
// 
// When you initialize the controller in initWithStyle:, you must specify
// the style of the table view (plain or grouped) that the controller is
// to manage. Because the initially created table view is without table
// dimensions (that is, number of sections and number of rows per section)
// or content, the table view’s data source and delegate — that is, the
// TUITableViewController itself — must provide the table dimensions,
// the cell content, and any desired configurations as usual.
//
// You may override loadView or any other superclass method, but if you do
// be sure to invoke the superclass implementation of the method first.
@interface TUITableViewController : TUIViewController <TUITableViewDelegate, TUITableViewDataSource>

// Returns the table view managed by the controller.
@property (nonatomic, strong) TUITableView *view;

// A Boolean value indicating if the controller clears the selection when
// the table appears. When YES, the table view controller clears the
// table’s current selection when it receives a viewWillAppear: message.
// Setting this property to NO preserves the selection. Defaults to YES.
@property (nonatomic, assign) BOOL clearsSelectionOnViewWillAppear;

// Initializes a table view controller to manage a table view of a given style.
// The style specifies the style of table view that the controller is to
// manage (plain or grouped). Returns an initialized TUITableViewController.
// If you use the standard init method to initialize a controller, a
// table view in the plain style is created.
- (id)initWithStyle:(TUITableViewStyle)style;

@end
