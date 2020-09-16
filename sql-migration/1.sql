-- Assign Users with a UserId

DECLARE @count int
DECLARE @i int = 1
DECLARE @Migrate bit = 1
DECLARE @DocumentId int
DECLARE @NormalizedUserName nvarchar(255)
DECLARE @UserId nvarchar(26)

IF(@Migrate = 1)
BEGIN
	SET @count = (SELECT COUNT(*) FROM UserIndex)
	SET @i = 1
	WHILE(@i <= @count)
	BEGIN
		WITH OrderedContentItem AS
		(
			SELECT DocumentId, NormalizedUserName,
			ROW_NUMBER() OVER (ORDER BY Id) AS 'RowNumber'
			FROM UserIndex
		)
		SELECT @DocumentId = DocumentId, @NormalizedUserName = NormalizedUserName FROM OrderedContentItem WHERE RowNumber = @i
		SET @UserId = LEFT(LOWER(REPLACE(NEWID(), '-', '')), 26)

		UPDATE UserIndex SET UserId = @UserId WHERE DocumentId = @DocumentId

		-- We update Users in the Document table
		UPDATE Document
		SET Content = JSON_MODIFY(Content, '$.UserId', @UserId)
		WHERE Id = @DocumentId

		-- We add UserId on all ContentItems in Document table
		UPDATE Document
		SET Content = JSON_MODIFY(Content, '$.UserId', @UserId)
		WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'
		AND JSON_VALUE(Content, '$.Owner') = @NormalizedUserName

		SELECT @i = @i + 1
	END
END

UPDATE ContentItemIndex SET UserId = (SELECT JSON_VALUE(Content, '$.UserId') FROM Document WHERE Id = ContentItemIndex.DocumentId)

--SELECT * FROM [AffairesExtra].[dbo].[UserIndex] LEFT JOIN Document ON UserIndex.DocumentId = Document.Id

--SELECT JSON_VALUE(Content, '$.UserId') as UserId,JSON_VALUE(Content, '$.Owner') as Owner, * FROM Document WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'

--SELECT JSON_VALUE(Content, '$.UserId') as UserId, JSON_VALUE(Content, '$.Owner') as Owner, JSON_VALUE(Content, '$.ContentType') as ContentType, *
--FROM Document 
--WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'
--AND JSON_VALUE(Content, '$.UserId') is NULL
--AND (JSON_VALUE(Content, '$.ContentType') != 'ProductInformationRequest' 
--AND JSON_VALUE(Content, '$.ContentType') != 'MagazineSubscription'
--AND JSON_VALUE(Content, '$.ContentType') != 'ContactRequest')

--SELECT DISTINCT JSON_VALUE(Content, '$.Owner') as Owner
--FROM Document 
--WHERE JSON_VALUE(Content, '$.UserId') is NULL
--AND (JSON_VALUE(Content, '$.ContentType') != 'ProductInformationRequest' 
--AND JSON_VALUE(Content, '$.ContentType') != 'MagazineSubscription'
--AND JSON_VALUE(Content, '$.ContentType') != 'ContactRequest')

--SELECT * FROM Document WHERE Content LIKE '%souellette@centrekubota.com%'