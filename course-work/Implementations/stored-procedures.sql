DELIMITER //

CREATE PROCEDURE GetUserProfileSummary(IN p_UserID INT)
BEGIN
    SELECT UserID, Name, Email, Headline, Location, Summary
    FROM USER
    WHERE UserID = p_UserID;

    -- TotalPosts 
    SELECT COUNT(*) AS TotalPosts
    FROM POST
    WHERE UserID = p_UserID;

    -- Skills
    SELECT s.SkillName, us.EndorsementCount
    FROM USER_SKILL us
    JOIN SKILL s ON us.SkillID = s.SkillID
    WHERE us.UserID = p_UserID
    ORDER BY us.EndorsementCount DESC;

    -- Work experience
    SELECT c.CompanyName, we.JobTitle, we.StartDate, we.EndDate, we.IsCurrent
    FROM WORK_EXPERIENCE we
    JOIN COMPANY c ON we.CompanyID = c.CompanyID
    WHERE we.UserID = p_UserID
    ORDER BY we.StartDate DESC;
END //

CREATE PROCEDURE MostUsedSkills()
BEGIN
    SELECT s.SkillName, COUNT(u.UserID)
    FROM USER_SKILL us
    JOIN USER u ON us.UserID = u.UserID
    JOIN SKILL s ON us.SkillID = s.SkillID
    GROUP BY s.SkillName;
END //

-- Usage example:
-- CALL GetUserProfileSummary(1);
