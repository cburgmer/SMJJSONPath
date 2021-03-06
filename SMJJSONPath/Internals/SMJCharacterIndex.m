/*
 * SMJCharacterIndex.m
 *
 * Copyright 2019 Avérous Julien-Pierre
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/* Adapted from https://github.com/json-path/JsonPath/blob/master/json-path/src/main/java/com/jayway/jsonpath/internal/CharacterIndex.java */


#import "SMJCharacterIndex.h"


NS_ASSUME_NONNULL_BEGIN


/*
** Defines
*/
#pragma mark Defines

#define kOpenParenthesisChar 	'('
#define kCloseParenthesisChar 	')'
#define kCloseSquareBracketChar ']'
#define kSpaceChar 				' '
#define kEscapeChar				'\\'
#define kSingleQuoteChar 		'\''
#define kDoubleQuoteChar 		'"'
#define kMinusChar 				'-'
#define kPeriodChar 			'.'
#define kRegexChar 				'/'


/*
** Macros
*/
#pragma mark Macros

#define SMSetError(Error, Code, Message, ...) \
	do { \
		if (Error) {\
			NSString *___message = [NSString stringWithFormat:(Message), ## __VA_ARGS__];\
			*(Error) = [NSError errorWithDomain:@"SMJCharacterIndexErrorDomain" code:(Code) userInfo:@{ NSLocalizedDescriptionKey : ___message }]; \
		} \
	} while (0) \


/*
** SMJCharacterIndex
*/
#pragma mark SMJCharacterIndex

@implementation SMJCharacterIndex
{
	NSString *_charSequence;
}

- (instancetype)initWithString:(NSString *)string
{
	self = [super init];
	
	if (self)
	{
		_charSequence = [string copy];
		_position = 0;
		_endPosition = string.length - 1;
	}
	
	return self;
}

- (NSInteger)length
{
	return _endPosition + 1;
}

- (BOOL)positionAtEnd
{
	return _position >= _endPosition;
}

- (BOOL)hasMoreCharacters
{
	return [self isInBoundsIndex:_position + 1];
}

- (BOOL)isInBoundsIndex:(NSInteger)index
{
	return (index >= 0) && (index <= _endPosition);
}

- (BOOL)inBounds
{
	return [self isInBoundsIndex:_position];
}

- (BOOL)isOutOfBoundsIndex:(NSInteger)index
{
	return ![self isInBoundsIndex:index];
}

- (unichar)characterAtIndex:(NSInteger)index
{
	return [_charSequence characterAtIndex:index];
}

- (unichar)characterAtIndex:(NSInteger)position defaultCharacter:(unichar)defaultChar
{
	if (![self isInBoundsIndex:position])
		return defaultChar;
	else
		return [self characterAtIndex:position];
}

- (unichar)currentCharacter
{
	return [_charSequence characterAtIndex:_position];
}

- (BOOL)currentCharacterIsEqualTo:(unichar)character
{
	return ([_charSequence characterAtIndex:_position] == character);
}

- (BOOL)lastCharacterIsEqualTo:(unichar)character
{
	return ([_charSequence characterAtIndex:_endPosition] == character);
}

- (BOOL)nextCharacterIsEqualTo:(unichar)character
{
	return [self isInBoundsIndex:_position + 1] && ([_charSequence characterAtIndex:_position + 1] == character);
}

- (NSInteger)incrementPositionBy:(NSInteger)charCount
{
	_position = _position + charCount;
	
	return _position;
}

- (NSInteger)decrementEndPositionBy:(NSInteger)charCount
{
	_endPosition = _endPosition - charCount;
	
	return _endPosition;
}

- (NSInteger)indexOfClosingSquareBracketFromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition;
	
	while ([self isInBoundsIndex:readPosition])
	{
		if ([self characterAtIndex:readPosition] == kCloseSquareBracketChar)
		{
			return readPosition;
		}
		
		readPosition++;
	}
	
	return NSNotFound;
}

- (NSInteger)indexOfMatchingCloseCharacterFromIndex:(NSInteger)startPosition openCharacter:(unichar)openChar closeCharacter:(unichar)closeChar skipStrings:(BOOL)skipStrings skipRegex:(BOOL)skipRegex error:(NSError **)error
{
	if ([self characterAtIndex:startPosition] != openChar)
	{
		SMSetError(error, 1, @"Expected %c but found %c", (char)openChar, (char)[self characterAtIndex:startPosition]);
		return NSNotFound;
	}
	
	NSInteger opened = 1;
	NSInteger readPosition = startPosition + 1;
	
	while ([self isInBoundsIndex:readPosition])
	{
		if (skipStrings)
		{
			unichar quoteChar = [self characterAtIndex:readPosition];
			
			if (quoteChar == kSingleQuoteChar || quoteChar == kDoubleQuoteChar)
			{
				readPosition = [self nextIndexOfUnescapedCharacter:quoteChar fromIndex:readPosition];
				
				if (readPosition == NSNotFound)
				{
					SMSetError(error, 1, @"Could not find matching close quote for %c when parsing : %@", (char)quoteChar, _charSequence);
					return NSNotFound;
				}
				
				readPosition++;
			}
		}
		
		if (skipRegex)
		{
			if ([self characterAtIndex:readPosition] == kRegexChar)
			{
				readPosition = [self nextIndexOfUnescapedCharacter:kRegexChar fromIndex:readPosition];
				
				if (readPosition == NSNotFound)
				{
					SMSetError(error, 2, @"Could not find matching close for %c when parsing regex in : %@", (char)kRegexChar, _charSequence);
					return NSNotFound;
				}
				
				readPosition++;
			}
		}
		
		if ([self characterAtIndex:readPosition] == openChar)
		{
			opened++;
		}
		
		if ([self characterAtIndex:readPosition] == closeChar)
		{
			opened--;
			
			if (opened == 0)
			{
				return readPosition;
			}
		}
		readPosition++;
	}
			 
	return NSNotFound;
}

- (NSInteger)indexOfClosingBracketFromIndex:(NSInteger)startPosition skipStrings:(BOOL)skipStrings skipRegex:(BOOL)skipRegex error:(NSError **)error
{
	return [self indexOfMatchingCloseCharacterFromIndex:startPosition openCharacter:kOpenParenthesisChar closeCharacter:kCloseParenthesisChar skipStrings:skipStrings skipRegex:skipRegex error:error];
}


- (NSInteger)indexOfNextSignificantCharacter:(unichar)character
{
	return [self indexOfNextSignificantCharacter:character fromIndex:_position];
}

- (NSInteger)indexOfNextSignificantCharacter:(unichar)character fromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition + 1;
	
	while (![self isOutOfBoundsIndex:readPosition] && [self characterAtIndex:readPosition] == kSpaceChar)
		readPosition++;
	
	if ([self characterAtIndex:readPosition] == character)
		return readPosition;
	else
		return NSNotFound;
}

- (NSInteger)nextIndexOfCharacter:(unichar)character
{
	return [self nextIndexOfCharacter:character fromIndex:_position + 1];
}

- (NSInteger)nextIndexOfCharacter:(unichar)character fromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition;
	
	while (![self isOutOfBoundsIndex:readPosition])
	{
		if ([self characterAtIndex:readPosition] == character)
		{
			return readPosition;
		}
		
		readPosition++;
	}
	
	return NSNotFound;
}

- (NSInteger)nextIndexOfUnescapedCharacter:(unichar)character
{
	return [self nextIndexOfUnescapedCharacter:character fromIndex:_position];
}

- (NSInteger)nextIndexOfUnescapedCharacter:(unichar)character fromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition + 1;
	BOOL inEscape = NO;
	
	while ([self isOutOfBoundsIndex:readPosition] == NO)
	{
		if (inEscape)
		{
			inEscape = NO;
		}
		else if ([self characterAtIndex:readPosition] == '\\')
		{
			inEscape = TRUE;
		}
		else if ([self characterAtIndex:readPosition] == character)
		{
			return readPosition;
		}
		
		readPosition ++;
	}
	
	return NSNotFound;
}

- (BOOL)nextSignificantCharacterIsEqualTo:(unichar)character
{
	return [self nextSignificantCharacterIsEqualTo:character fromIndex:_position];
}

- (BOOL)nextSignificantCharacterIsEqualTo:(unichar)character fromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition + 1;
	
	while (![self isOutOfBoundsIndex:readPosition] && [self characterAtIndex:readPosition] == kSpaceChar)
	{
		readPosition++;
	}
	
	return ([self isOutOfBoundsIndex:readPosition] == NO) && [self characterAtIndex:readPosition] == character;
}

- (unichar)nextSignificantCharacter
{
	return [self nextSignificantCharacterFromIndex:_position];
}

- (unichar)nextSignificantCharacterFromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition + 1;
	
	while (![self isOutOfBoundsIndex:readPosition] && [self characterAtIndex:readPosition] == kSpaceChar)
	{
		readPosition++;
	}
	
	if (![self isOutOfBoundsIndex:readPosition])
	{
		return [self characterAtIndex:readPosition];
	}
	else
	{
		return ' ';
	}
}

- (BOOL)readSignificantCharacter:(unichar)character error:(NSError **)error
{
	if ([self skipBlanks].currentCharacter != character)
	{
		SMSetError(error, 1, @"Expected character '%c' but found '%c'", (char)character, (char)([self skipBlanks].currentCharacter));
		return NO;
	}
	
	[self incrementPositionBy:1];
	
	return YES;
}

- (BOOL)hasSignificantString:(NSString *)string
{
	[self skipBlanks];
	
	if (![self isInBoundsIndex:_position + string.length - 1])
		return NO;
	
	if (![[self stringFromIndex:_position toIndex:_position + string.length] isEqualToString:string])
		return NO;
	
	[self incrementPositionBy:string.length];
	
	return YES;
}

- (NSInteger)indexOfPreviousSignificantCharacter
{
	return [self indexOfPreviousSignificantCharacterFromIndex:_position];
}

- (NSInteger)indexOfPreviousSignificantCharacterFromIndex:(NSInteger)startPosition
{
	NSInteger readPosition = startPosition - 1;
	
	while (![self isOutOfBoundsIndex:readPosition] && [self characterAtIndex:readPosition] == kSpaceChar)
	{
		readPosition--;
	}
	
	if (![self isOutOfBoundsIndex:readPosition])
	{
		return readPosition;
	}
	else
	{
		return NSNotFound;
	}
}

- (unichar)previousSignificantCharacterFromIndex:(NSInteger)startPosition
{
	NSInteger previousSignificantCharIndex = [self indexOfPreviousSignificantCharacterFromIndex:startPosition];
	
	if (previousSignificantCharIndex == NSNotFound)
		return ' ';
	else
		return [self characterAtIndex:previousSignificantCharIndex];
}

- (unichar)previousSignificantCharacter
{
	return [self previousSignificantCharacterFromIndex:_position];
}

- (NSString *)stringFromIndex:(NSInteger)start toIndex:(NSInteger)end
{
	return [_charSequence substringWithRange:NSMakeRange(start, end - start)];
}

- (NSString *)stringValue
{
	return _charSequence;
}

- (BOOL)isNumberCharacterAtIndex:(NSInteger)readPosition
{
	unichar character = [self characterAtIndex:readPosition];
	
	return (character >= '0' && character <= '9') || character == kMinusChar  || character == kPeriodChar;
}

- (SMJCharacterIndex *)skipBlanks
{
	while ([self inBounds] && _position < _endPosition  && self.currentCharacter == kSpaceChar)
	{
		[self incrementPositionBy:1];
	}
	
	return self;
}

- (SMJCharacterIndex *)skipBlanksAtEnd
{
	while ([self inBounds] && _position < _endPosition && [self lastCharacterIsEqualTo:kSpaceChar])
	{
		[self decrementEndPositionBy:1];
	}
	
	return self;
}

- (SMJCharacterIndex *)trim
{
	[self skipBlanks];
	[self skipBlanksAtEnd];
	
	return self;
}

@end


NS_ASSUME_NONNULL_END
