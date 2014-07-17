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

#import "TUIControl.h"

@class TUITableView;

// The TUIRefreshControl is an update indicator control that can either
// be manually or automatically triggered by swipe or mouse events to
// display a small refresh action indicator.
@interface TUIRefreshControl : TUIControl

// This property returns YES if the refresh control is currently refreshing,
// by either manual or automatic control.
@property (nonatomic, assign, readonly, getter = isRefreshing) BOOL refreshing;

// Set a custom tint color for the refresh control.
@property (nonatomic, strong) NSColor *tintColor;

// To use the refresh control, initialize it by  attaching it to a table
// view passed. Once this has been done, the refresh control will become
// the pullDownView for that table view. It is advised not to modify the
// pullDownView after attachment to avoid refresh control breakage.
- (id)initInTableView:(TUITableView *)tableView;

// Manually begin the refresh process. Note that, unlike the automatic
// bounce-scrolled refresh, this manual refresh does not automatically lock
// and display the refresh indicator above the table view. This is a deliberate
// design choice taken to accomodate for targeting users who both have and
// do not have a multitouch trackpad. It is more natural to not be able to
// see the refresh indicator when using a mouse scroll wheel.
- (void)beginRefreshing;

// End the refresh process. Note that if a bounce scroll triggers an automatic
// refresh process, the only way to end it is to call this method.
// By design, the refresh indicator disappears.
- (void)endRefreshing;

@end
