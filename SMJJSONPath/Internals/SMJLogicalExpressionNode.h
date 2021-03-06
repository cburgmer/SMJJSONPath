/*
 * SMJLogicalExpressionNode.h
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


/* Adapted from https://github.com/json-path/JsonPath/blob/master/json-path/src/main/java/com/jayway/jsonpath/internal/filter/LogicalExpressionNode.java */


#import "SMJExpressionNode.h"


NS_ASSUME_NONNULL_BEGIN


/*
** SMJLogicalExpressionNode
*/
#pragma mark - SMJLogicalExpressionNode

@interface SMJLogicalExpressionNode : SMJExpressionNode

// -- Instance --
+ (instancetype)logicalNotWithExpressionNode:(SMJExpressionNode *)node;

+ (instancetype)logicalOrWithLeftExpressionNode:(SMJExpressionNode *)leftNode rightExpressionNode:(SMJExpressionNode *)rigthNode;
+ (instancetype)logicalOrWithExpressionNodes:(NSArray <SMJExpressionNode *> *)nodes;

+ (instancetype)logicalAndWithLeftExpressionNode:(SMJExpressionNode *)leftNode rightExpressionNode:(SMJExpressionNode *)rightNode;
+ (instancetype)logicalAndWithExpressionNodes:(NSArray <SMJExpressionNode *> *)nodes;

@end


NS_ASSUME_NONNULL_END
