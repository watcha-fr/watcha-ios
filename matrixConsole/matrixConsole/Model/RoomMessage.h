/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <MatrixSDK/MatrixSDK.h>

#define ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH 200
#define ROOM_MESSAGE_CELL_IMAGE_MARGIN 8

extern NSString *const kLocalEchoEventIdPrefix;
extern NSString *const kFailedEventId;

typedef enum : NSUInteger {
    RoomMessageTypeText,
    RoomMessageTypeImage,
    RoomMessageTypeAudio,
    RoomMessageTypeVideo,
    RoomMessageTypeLocation
} RoomMessageType;

// Converts matrix events in room messages
@interface RoomMessage : NSObject

@property (nonatomic) RoomMessageType messageType;
@property (nonatomic) NSString *senderId;
@property (nonatomic) NSString *senderName;
@property (nonatomic) NSString *senderAvatarUrl;

// The message content size depends on its type:
// - RoomMessageTypeText: returns suitable content size of a text view to display the whole text message
// - Others: returns suitable content size for an image view in order to display attachment thumbnail or icon.
@property (nonatomic) CGSize contentSize;

// The body of the message, or kind of content description in case of attachment (e.g. "image attachment")
@property (nonatomic) NSAttributedString *attributedTextMessage;
// True if the sender name appears at the beginning of the message text (available only for messageType is RoomMessageTypeText)
@property (nonatomic) BOOL startsWithSenderName;

// Attachment info (nil when messageType is RoomMessageTypeText)
@property (nonatomic) BOOL isUploadInProgress;
@property (nonatomic) NSString *attachmentURL;
@property (nonatomic) NSDictionary *attachmentInfo;
@property (nonatomic) NSString *thumbnailURL;
@property (nonatomic) NSDictionary *thumbnailInfo;

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState;

// Concatenates successive text messages from the same user
// Return false if the provided event could not be added (for example the sender id is not the same, the sender name has been changed, or the messageType is not RoomMessageTypeText)
- (BOOL)addEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;
// Remove the item defined with this event id
// Return false if the event id is not found
- (BOOL)removeEvent:(NSString*)eventId;

// Return true if the event id is one of the message items
- (BOOL)containsEventId:(NSString*)eventId;
@end