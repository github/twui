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

#import "TUITextRenderer.h"
#import "TUITextEditor.h"
#import "TUIView.h"
#import "CoreText+Additions.h"
#import "TUITextRenderer+Private.h"
#import "TUIScrollView.h"
#import "TUIView+TUIBridgedView.h"
#import "TUIScrollView+TUIBridgedScrollView.h"

static NSAttributedString *killBuffer = nil;

@interface NSString (ABTokenizerAdditions)
@end

@implementation NSString (ABTokenizerAdditions)

- (CFIndex)ab_endOfWordGivenCursor:(CFIndex)cursor // if cursor is in word, return end of current word, if past, end of next word
{
	__block CFIndex ret = -1;
	[self enumerateSubstringsInRange:NSMakeRange(0, [self length]) 
							 options:NSStringEnumerationByWords|NSStringEnumerationSubstringNotRequired
						  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
							  CFIndex l = substringRange.location + substringRange.length;
							  if(l > cursor) {
								  ret = l;
								  *stop = YES;
							  }
						  }];
	if(ret == -1) {
		ret = [self length]; // go to end
	}
	return ret;
}

- (CFIndex)ab_beginningOfWordGivenCursor:(CFIndex)cursor // if cursor is in word, return end of current word, if past, end of next word
{
	__block CFIndex ret = -1;
	[self enumerateSubstringsInRange:NSMakeRange(0, [self length]) 
							 options:NSStringEnumerationByWords|NSStringEnumerationReverse|NSStringEnumerationSubstringNotRequired
						  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
							  CFIndex l = substringRange.location;
							  if(l < cursor) {
								  ret = l;
								  *stop = YES;
							  }
						  }];
	if(ret == -1) {
		ret = 0; // go to beginning
	}
	return ret;
}

@end

@implementation TUITextRenderer (KeyBindings)

#define TEXT [attributedString string]

- (TUITextEditor *)_textEditor
{
	if([self isKindOfClass:[TUITextEditor class]])
		return (TUITextEditor *)self;
	return nil;
}

- (void)_scrollToIndex:(CFIndex)index {
	id<TUIBridgedScrollView> scrollView = self.view.ancestorScrollView;
	if (scrollView) {
		// Get the rect for the index passed within the text.
		CFRange r = CFRangeMake(index, 0);
		CFIndex nRects = 1;
		CGRect rects[nRects];
		AB_CTFrameGetRectsForRange([self ctFrame], r, rects, &nRects);
		
		if (nRects == 1) {
			// If it exists, then scroll to the beginning of the rects.
			CGRect rect = [scrollView convertFromWindowRect:[self.view convertToWindowRect:rects[0]]];
			[scrollView scrollToIncludeRect:rect];
		} else if (nRects == 0) {
			// Otherwise, scroll to the middle of the text rects.
			CGRect rect = [scrollView convertFromWindowRect:[self.view convertToWindowRect:CGRectMake(0, self.view.frame.size.height / 2, 0, 1)]];
			[scrollView scrollToIncludeRect:rect];
		}
	}
}

- (CFIndex)_indexByMovingIndex:(CFIndex)index
							by:(CFIndex)incr {
	CFIndex lineIndex;
	float xPosition;
	AB_CTFrameGetLinePositionOfIndex(TEXT, [self ctFrame], index, &lineIndex, &xPosition);
	
	if(lineIndex >= 0) {
		NSArray *lines = (__bridge NSArray *)CTFrameGetLines([self ctFrame]);
		CFIndex linesCount = [lines count];
		
		// If the incremental value is less than 0 and the line index
		// is 0, the index doesn't change.
		if(incr <= 0 && lineIndex == 0) {
			return 0;
			
			// If the line index after shifting is more than the line count,
			// return the last character index.
		} else if(lineIndex + incr >= linesCount) {
			return [TEXT length];
			
			// If the line index is within text bounds after increment,
			// return the real character index.
		} else if(lineIndex + incr >= 0) {
			CFIndex index;
			AB_CTFrameGetIndexForPositionInLine(TEXT, [self ctFrame], lineIndex + incr, xPosition, &index);
			return index;
		}
	}
	
	// Oops! Something went wrong. Return error (-1).
	return -1;
}

- (void)moveUp:(id)sender
{
	NSInteger selectionLength = labs(_selectionStart - _selectionEnd);
	if(selectionLength)
		_selectionStart = _selectionEnd = MIN(_selectionEnd,_selectionStart);
	else
		_selectionEnd = _selectionStart = [self _indexByMovingIndex:MIN(_selectionStart,_selectionEnd)
																 by:-1];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveUpAndModifySelection:(id)sender
{
	_selectionEnd = [self _indexByMovingIndex:MIN(_selectionStart,_selectionEnd)
										   by:-1];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveDown:(id)sender
{
	NSInteger selectionLength = labs(_selectionStart - _selectionEnd);
	if(selectionLength)
		_selectionStart = _selectionEnd = MAX(_selectionEnd,_selectionStart);
	else
		_selectionEnd = _selectionStart = [self _indexByMovingIndex:MAX(_selectionStart,_selectionEnd)
																 by:1];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveDownAndModifySelection:(id)sender
{
	_selectionEnd = [self _indexByMovingIndex:MAX(_selectionStart,_selectionEnd)
										   by:1];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveRight:(id)sender
{
	NSInteger selectionLength = labs(_selectionStart - _selectionEnd);
	NSInteger max = [TEXT length];
	_selectionStart = _selectionEnd = MIN(MAX(_selectionStart, _selectionEnd) + (selectionLength?0:1), max);
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveLeft:(id)sender
{
	NSInteger selectionLength = labs(_selectionStart - _selectionEnd);
	NSInteger min = 0;
	_selectionStart = _selectionEnd = MAX(MIN(_selectionStart, _selectionEnd) - (selectionLength?0:1), min);
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveRightAndModifySelection:(id)sender
{
	NSInteger max = [TEXT length];
	_selectionEnd = MIN(_selectionEnd + 1, max);
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveLeftAndModifySelection:(id)sender
{
	NSInteger min = 0;
	_selectionEnd = MAX(_selectionEnd - 1, min);
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveWordRight:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT ab_endOfWordGivenCursor:MAX(_selectionStart, _selectionEnd)];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveWordLeft:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT ab_beginningOfWordGivenCursor:MIN(_selectionStart, _selectionEnd)];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveWordRightAndModifySelection:(id)sender
{
	_selectionEnd = [TEXT ab_endOfWordGivenCursor:_selectionEnd];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveWordLeftAndModifySelection:(id)sender
{
	_selectionEnd = [TEXT ab_beginningOfWordGivenCursor:_selectionEnd];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveToBeginningOfLineAndModifySelection:(id)sender
{
	_selectionEnd = 0; // fixme for multiline
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveToEndOfLineAndModifySelection:(id)sender
{
	_selectionEnd = [TEXT length]; // fixme for multiline
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveToBeginningOfLine:(id)sender
{
	_selectionStart = _selectionEnd = 0;
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveToEndOfLine:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT length];
	[self.view setNeedsDisplay];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveToBeginningOfParagraphAndModifySelection:(id)sender
{
	[self moveToBeginningOfLineAndModifySelection:sender];
}

- (void)moveToEndOfParagraphAndModifySelection:(id)sender
{
	[self moveToEndOfLineAndModifySelection:sender];
}

- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender
{
	[self moveToBeginningOfLineAndModifySelection:sender];
}

- (void)moveToEndOfDocumentAndModifySelection:(id)sender
{
	[self moveToEndOfLineAndModifySelection:sender];
}

- (void)insertNewline:(id)sender
{
	[[self _textEditor] insertText:@"\n"];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)insertNewlineIgnoringFieldEditor:(id)sender
{
	[[self _textEditor] insertText:@"\n"];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)deleteBackward:(id)sender
{
	// Find the range to delete, handling an empty selection and the input point being at 0
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0) {
		if(deleteRange.location == 0) {
			return;
		} else {
			deleteRange.location -= 1;
			deleteRange.length = 1;
		}
	}
	
	[[self _textEditor] deleteCharactersInRange:deleteRange];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)deleteForward:(id)sender
{
	// Find the range to delete, handling an empty selection and the input point being at the end
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0) {
		if(deleteRange.location == [TEXT length]) {
			return;
		} else {
			deleteRange.length = 1;
		}
	}

	[[self _textEditor] deleteCharactersInRange:deleteRange];
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}


- (void)deleteToBeginningOfLine:(id)sender
{
	NSInteger selectionLength = labs(_selectionStart - _selectionEnd);
	if(selectionLength == 0) {
		[[self _textEditor] deleteCharactersInRange:NSMakeRange(0, _selectionStart)];
	} else {
		[self deleteBackward:nil];
	}
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)deleteWordBackward:(id)sender
{
	NSInteger selectionLength = labs(_selectionStart - _selectionEnd);
	if(selectionLength == 0) {
		_selectionEnd = [TEXT ab_beginningOfWordGivenCursor:_selectionEnd];
		[self deleteBackward:nil];
	} else {
		[self deleteBackward:nil];
	}
	[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
}

- (void)moveToBeginningOfParagraph:(id)sender
{
	CFIndex cursor = MIN(_selectionStart, _selectionEnd);
	__block CFIndex ret = -1;
	[TEXT enumerateSubstringsInRange:NSMakeRange(0, [TEXT length]) options:NSStringEnumerationByParagraphs | NSStringEnumerationReverse | NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		CFIndex l = substringRange.location;
		if(l < cursor) {
			ret = l;
			*stop = YES;
		}
	}];
	
	if(ret == -1) {
		ret = 0;
	}
	
	_selectionStart = _selectionEnd = ret;
		
	[self.view setNeedsDisplay];
}

- (void)moveToEndOfParagraph:(id)sender
{
	CFIndex cursor = MAX(_selectionStart, _selectionEnd);
	__block CFIndex ret = -1;
	[TEXT enumerateSubstringsInRange:NSMakeRange(0, [TEXT length]) options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		CFIndex l = substringRange.location + substringRange.length;
		if(l > cursor) {
			ret = l;
			*stop = YES;
		}
	}];
	
	if(ret == -1) {
		ret = [TEXT length];
	}
	
	_selectionStart = _selectionEnd = ret;
	
	[self.view setNeedsDisplay];
}

- (void)moveToBeginningOfDocument:(id)sender
{
	_selectionStart = _selectionEnd = 0;
	
	[self.view setNeedsDisplay];
}

- (void)moveToEndOfDocument:(id)sender
{
	_selectionStart = _selectionEnd = [TEXT length];
	
	[self.view setNeedsDisplay];
}
- (void)deleteToBeginningOfParagraph:(id)sender
{
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0)
		deleteRange.length = [TEXT length] - deleteRange.location;
	killBuffer = [[self _textEditor].backingStore attributedSubstringFromRange:deleteRange];
	[self deleteToBeginningOfLine:sender];
}

- (void)deleteToEndOfLine:(id)sender
{
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0)
		deleteRange.length = [TEXT length] - deleteRange.location;
	killBuffer = [[self _textEditor].backingStore attributedSubstringFromRange:deleteRange];
	[[self _textEditor] deleteCharactersInRange:deleteRange];
	[self _scrollToIndex:MAX(_selectionStart, _selectionEnd)];
}

- (void)deleteToEndOfParagraph:(id)sender
{
	NSRange deleteRange = [self selectedRange];
	if(deleteRange.length == 0)
		deleteRange.length = [TEXT length] - deleteRange.location;
	killBuffer = [[self _textEditor].backingStore attributedSubstringFromRange:deleteRange];
	[self deleteToEndOfLine:sender];
}

- (void)yank:(id)sender
{
	if(killBuffer)
	{
		[[self _textEditor] insertText:killBuffer];
		[self _scrollToIndex:MIN(_selectionStart, _selectionEnd)];
	}
}

@end
