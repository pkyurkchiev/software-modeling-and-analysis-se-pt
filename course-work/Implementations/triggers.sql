DELIMITER //

CREATE TRIGGER SendNotificationMessageToThePostCreator
BEFORE INSERT ON USER_COMMENT
FOR EACH ROW
BEGIN
    SET @PostCreatorID = (SELECT UserID FROM POST WHERE PostID = NEW.PostID);
    SET @CommentContent = NEW.Content;

    INSERT INTO MESSAGE (SenderID, ReceiverID, Content) VALUES (@PostCreatorID, @PostCreatorID, @CommentContent);
END //

CREATE TRIGGER SendReactionNotification
BEFORE INSERT ON POST_REACTION
FOR EACH ROW
BEGIN
    SET @PostCreatorID = (SELECT UserID FROM POST WHERE PostID = NEW.PostID);
    SET @ReactionType = NEW.ReactionType;

    INSERT INTO MESSAGE (SenderID, ReceiverID, Content) VALUES (@PostCreatorID, @PostCreatorID, @ReactionType);
END //
