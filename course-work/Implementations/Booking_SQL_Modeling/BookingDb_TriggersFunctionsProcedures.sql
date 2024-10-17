----------------- TRIGGERS ---------------------

----------------- AfterUserDelete ------------------
CREATE TRIGGER TR_AfterUserDelete
ON UserManagement.Users
AFTER DELETE
AS 
BEGIN
    DELETE FROM BookingManagement.Bookings WHERE UserId in (select ID from deleted)
	DELETE FROM PropertyManagement.Properties WHERE HostId in (select ID from deleted)
	DELETE FROM UserManagement.Favorites WHERE UserId in (select ID from deleted)
	DELETE FROM PropertyManagement.Reviews WHERE UserId in (select ID from deleted)
	DELETE FROM BookingManagement.FlightBookings where UserId in (select ID from deleted)
	DELETE FROM BookingManagement.TaxiBookings where UserId in (select ID from deleted)
	DELETE FROM TransportManagement.CarRentals where UserId in (select ID from deleted)
END
GO

----------------- AfterBookingDelete ------------------
CREATE TRIGGER TR_AfterBookingDelete
ON BookingManagement.Bookings
AFTER DELETE
AS 
BEGIN
    DELETE FROM HistoryManagement.BookingPaymentHistory WHERE BookingId in (select ID from deleted)
END

----------------- AfterFlightBookingDelete ------------------
GO
CREATE TRIGGER TR_AfterFlightBookingDelete
ON BookingManagement.FlightBookings
AFTER DELETE
AS 
BEGIN
    DELETE FROM HistoryManagement.FlightBookingPaymentHistory WHERE FlightBookingId in (select ID from deleted)
END

----------------- AfterCarRentalDelete ------------------
GO
CREATE TRIGGER TR_AfterCarRentalDelete
ON TransportManagement.CarRentals
AFTER DELETE
AS 
BEGIN
    DELETE FROM HistoryManagement.CarRentalPaymentHistory WHERE CarRentalId in (select ID from deleted)
END

----------------- AfterBookingDelete ------------------
GO
CREATE TRIGGER TR_AfterTaxiBookingDelete
ON BookingManagement.TaxiBookings
AFTER DELETE
AS 
BEGIN
    DELETE FROM HistoryManagement.TaxiBookingPaymentHistory WHERE TaxiBookingId in (select ID from deleted)
END

----------------- UpdateFullName ------------------
GO
CREATE TRIGGER trg_UpdateFullName
ON UserManagement.Users
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE UserManagement.Users
    SET FullName = CONCAT(FirstName, ' ', LastName)
    FROM inserted
    WHERE Users.ID = inserted.ID;
END
GO

----------------- PreventDeleteProperty ------------------
CREATE TRIGGER trg_PreventDeleteProperty
ON PropertyManagement.Properties
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
	SELECT 1 FROM BookingManagement.BookingDetail bd
	INNER JOIN PropertyManagement.Rooms r ON r.ID = bd.RoomId
	INNER JOIN BookingManagement.Bookings b on b.ID = bd.BookingId
	WHERE r.PropertyId IN (SELECT ID FROM deleted)
	AND  b.CheckOutDate >  GETDATE())
    BEGIN
        RAISERROR('Cannot delete property with active bookings.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
	ELSE
	BEGIN
		DELETE FROM PropertyManagement.Properties
		WHERE ID IN (SELECT ID FROM deleted);

		DELETE FROM PropertyManagement.PropertyAmenities where PropertyId IN (SELECT ID FROM deleted);
		DELETE FROM PropertyManagement.Reviews where PropertyId IN (SELECT ID FROM deleted);
		DELETE FROM UserManagement.Favorites where PropertyId IN (SELECT ID FROM deleted);
		DELETE FROM PropertyManagement.Rooms where PropertyId IN (SELECT ID FROM deleted);
	END
END
GO

----------------- FUNCTIONS ---------------------

----------------- fn_CalculateTotalNights ------------------
CREATE FUNCTION BookingManagement.fn_CalculateTotalNights
(
    @CheckInDate DATE,
    @CheckOutDate DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(DAY, @CheckInDate, @CheckOutDate);
END
GO

SELECT BookingManagement.fn_CalculateTotalNights('2024-01-01', '2024-01-05') AS TotalNights;
GO

----------------- fn_CheckRoomAvailability ------------------
CREATE FUNCTION BookingManagement.fn_CheckRoomAvailability
(
    @RoomId INT,
    @CheckInDate DATE,
    @CheckOutDate DATE
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsAvailable BIT;

    -- Check for room availability
    IF EXISTS (
        SELECT 1
        FROM BookingManagement.Bookings b
        JOIN BookingManagement.BookingDetail bd ON b.ID = bd.BookingId
        WHERE bd.RoomId = @RoomId
        AND b.CheckInDate < @CheckOutDate
        AND b.CheckOutDate > @CheckInDate
    )
    BEGIN
        SET @IsAvailable = 0;  -- Room is not available
    END
    ELSE
    BEGIN
        SET @IsAvailable = 1;  -- Room is available
    END

    RETURN @IsAvailable;
END;
GO

----------------- fn_GetPropertyRatingAverage ------------------
CREATE FUNCTION fn_GetPropertyRatingAverage
(
    @PropertyId INT
)
RETURNS DECIMAL(3, 2)
AS
BEGIN
    DECLARE @AverageRating DECIMAL(3, 2);
    
    SELECT @AverageRating = AVG(Rating)
    FROM PropertyManagement.Reviews
    WHERE PropertyId = @PropertyId;

    RETURN ISNULL(@AverageRating, 0); 
END
GO

SELECT dbo.fn_GetPropertyRatingAverage(1) AS AverageRating;
GO

----------------- STORED PROCEDURES ---------------------

----------------- GetUserBookings ------------------
CREATE PROCEDURE sp_GetUserBookings
    @UserId INT
AS
BEGIN
    SELECT *
    FROM BookingManagement.Bookings
    WHERE UserId = @UserId;
END
GO

----------------- UpdatePropertyPrice ------------------
CREATE PROCEDURE sp_UpdatePropertyPrice
    @PropertyId INT,
    @NewPrice DECIMAL(10, 2)
AS
BEGIN
    UPDATE PropertyManagement.Properties
    SET PricePerNight = @NewPrice
    WHERE ID = @PropertyId;
END
GO

----------------- GetPropertyAmenities ------------------
CREATE PROCEDURE sp_GetPropertyAmenities
    @PropertyId INT
AS
BEGIN
    SELECT a.Description
    FROM PropertyManagement.PropertyAmenities pa
    JOIN PropertyManagement.Amenities a ON pa.AmenityId = a.ID
    WHERE pa.PropertyId = @PropertyId;
END
GO

----------------- CreateBooking ------------------
CREATE PROCEDURE BookingManagement.CreateBooking
    @UserId INT,
    @CheckInDate DATE,
    @CheckOutDate DATE,
    @NumberOfPeople INT,
    @RoomId INT,
    @Discount DECIMAL(10, 2) = 0, 
	@GuestName nvarchar(50)
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(10, 2);
    DECLARE @PricePerNight DECIMAL(10, 2);
    DECLARE @RoomCapacity INT;
    DECLARE @Days INT;

    SET @Days = BookingManagement.fn_CalculateTotalNights(@CheckInDate, @CheckOutDate)

    IF BookingManagement.fn_CheckRoomAvailability(@RoomId, @CheckInDate, @CheckOutDate) = 0
    BEGIN
        RETURN 0;
    END

    SELECT @PricePerNight = PricePerNight, @RoomCapacity = PeopleCapacity
    FROM PropertyManagement.Rooms
    WHERE ID = @RoomId;

    IF @NumberOfPeople > @RoomCapacity
    BEGIN
        RETURN 0;
    END

    SET @TotalAmount = (@PricePerNight * @Days) - @Discount;

    BEGIN TRANSACTION;

    BEGIN TRY
		DECLARE @BookingId INT;

        INSERT INTO BookingManagement.Bookings (UserId, CheckInDate, CheckOutDate, NumberOfPeople, TotalAmount, Discount)
        OUTPUT INSERTED.ID INTO @BookingId
        VALUES (@UserId, @CheckInDate, @CheckOutDate, @NumberOfPeople, @TotalAmount, @Discount);

        INSERT INTO BookingManagement.BookingDetail (BookingId, RoomId, GuestName, TotalPrice)
        VALUES (@BookingId, @RoomId, @GuestName, @TotalAmount);

        COMMIT TRANSACTION;
		RETURN 1;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
		RETURN 0;
    END CATCH
END;

EXEC BookingManagement.CreateBooking @UserId = 1, @CheckInDate = '2024-10-20', @CheckOutDate = '2024-10-25', @NumberOfPeople = 2, @RoomId = 1, @Discount = 10.00, @GuestName = 'Petq Chalumova';
GO
----------------- GetUserBookingHistory ------------------
CREATE PROCEDURE BookingManagement.GetUserBookingHistory
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        b.ID AS BookingId,
        b.CheckInDate,
        b.CheckOutDate,
        b.NumberOfPeople,
        b.TotalAmount,
        b.Discount,
        r.Name AS RoomName,
        p.Name AS PropertyName,
        p.Description AS PropertyDescription,
        bd.GuestName,
        bd.TotalPrice AS RoomTotalPrice,
        b.CreatedAt
    FROM 
        BookingManagement.Bookings b
    JOIN 
        BookingManagement.BookingDetail bd ON b.ID = bd.BookingId
    JOIN 
        PropertyManagement.Rooms r ON bd.RoomId = r.ID
    JOIN 
        PropertyManagement.Properties p ON r.PropertyId = p.ID
    WHERE 
        b.UserId = @UserId
    ORDER BY 
        b.CreatedAt DESC;
END;
GO

EXEC BookingManagement.GetUserBookingHistory @UserId = 1;
GO

----------------- UpdateBookingStatus ------------------
CREATE PROCEDURE sp_UpdateBookingStatus
    @BookingId INT,
    @NewStatusId INT
AS
BEGIN
    UPDATE BookingManagement.Bookings
    SET BookingStatusId = @NewStatusId
    WHERE ID = @BookingId;

    IF @@ROWCOUNT = 0
    BEGIN
        RETURN 0;
    END

	RETURN 1;
END
GO

EXEC sp_UpdateBookingStatus @BookingId = 10, @NewStatusId = 2;  
GO

----------------- GetPropertyDetails ------------------
CREATE PROCEDURE sp_GetPropertyDetails
    @PropertyId INT
AS
BEGIN
    SELECT 
        P.ID AS PropertyId,
        P.Name,
        P.Description,
        P.PricePerNight,
        P.MaxGuests,
        L.City,
        L.Country,
        R.Rating,
        R.Comment
    FROM 
        PropertyManagement.Properties P
    JOIN 
        LocationManagement.Locations L ON P.LocationId = L.ID
    LEFT JOIN 
        PropertyManagement.Reviews R ON P.ID = R.PropertyId
    WHERE 
        P.ID = @PropertyId;
END
GO

EXEC sp_GetPropertyDetails @PropertyId = 2;
GO
