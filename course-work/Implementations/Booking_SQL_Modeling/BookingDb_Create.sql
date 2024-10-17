CREATE DATABASE BookingDB
GO

USE BookingDB
GO

Create schema UserManagement
GO

Create schema LocationManagement
GO

Create schema PropertyManagement
GO

Create schema BookingManagement
GO

Create schema PaymentManagement
GO

Create schema TransportManagement
GO

Create schema HistoryManagement
GO


----------------- [UserManagement].[Users] ------------------
Create table [UserManagement].[Users]
(
    ID int identity(1, 1) primary key,
	FirstName nvarchar(50) not null,
	LastName nvarchar(50) not null,
    Username nvarchar(50) not null unique,
    Email nvarchar(100) not null unique,
    [Password] nvarchar(255) not null,
    FullName nvarchar(100),
    PhoneNumber nvarchar(10),
    IsHost tinyint not null default (0),
    CreatedAt datetime default current_timestamp,
	constraint User_Password_CK check (datalength(password) >= 6 )
)
GO

----------------- [LocationManagement].[Locations] ------------------
Create table [LocationManagement].[Locations] 
(
    ID int identity(1, 1) primary key,
    City nvarchar(100) not null,
    Country nvarchar(100) not null
)
GO

----------------- [PropertyManagement].[PropertyTypes] ------------------
Create table [PropertyManagement].[PropertyTypes]
(
	ID int identity(1, 1) primary key,
	[Type] nvarchar(150) not null,
	[Description] nvarchar(250) null
)
GO

----------------- [PropertyManagement].[Properties] ------------------
Create table [PropertyManagement].[Properties] 
(
    ID int identity(1, 1) primary key,
    HostId int not null,
    [Name] nvarchar(100) not null,
    [Description] nvarchar(max),
	StreetInfo nvarchar(200) not null,
    LocationId int not null,
	PropertyTypeId int not null,
    CreatedAt datetime default current_timestamp,
    constraint FK_Properties_HostId foreign key (HostId) references UserManagement.Users(ID),
    constraint FK_Properties_LocationId foreign key (LocationId) references LocationManagement.Locations(ID),
	constraint FK_Properties_PropertyTypeId foreign key (PropertyTypeId) references PropertyManagement.PropertyTypes(ID)
)
GO

----------------- [BookingManagement].[BookingStatus] ------------------
Create table [BookingManagement].[BookingStatus] 
(
    ID int identity(1, 1) primary key,
    [Description] nvarchar(50) not null
)
GO

Insert into [BookingManagement].[BookingStatus] 
values
('Pending'),
('Confirmed'),
('Cancelled')
GO

----------------- [PaymentManagement].[PaymentMethods] ------------------
Create table [PaymentManagement].[PaymentMethods] 
(
    ID int identity(1, 1) primary key,
    [Description] nvarchar(50) not null 
)
GO

----------------- [BookingManagement].[Bookings] ------------------
Create table [BookingManagement].[Bookings] 
(
    ID int identity(1, 1) primary key,
    UserId int not null,
    CheckInDate date not null,
    CheckOutDate date not null,
	NumberOfPeople int not null,
    TotalAmount decimal(10, 2) not null,
    BookingStatusId int default(1) not null,
	PaymentMethodId int not null,
	Discount decimal(10,2) null,
    CreatedAt datetime default current_timestamp,
    constraint FK_Bookings_UserId foreign key (UserId) references UserManagement.Users(ID),
    constraint FK_Bookings_BookingStatusId foreign key (BookingStatusId) references BookingManagement.BookingStatus(ID),
	constraint FK_Bookings_PaymentMethodId foreign key (PaymentMethodId) references PaymentManagement.PaymentMethods(ID)
)
GO

-------------- [HistoryManagement].[BookingPaymentHistory] ------------------
Create table [HistoryManagement].[BookingPaymentHistory]
(
	ID int identity(1, 1) primary key,
	BookingId int not null,
	AmountPaid decimal(10,2) not null,
	CreatedAt datetime default current_timestamp,
	constraint FK_BookingPaymentHistory_BookingId foreign key (BookingId) references BookingManagement.Bookings(ID)
)
GO

-------------- [PropertyManagement].[RoomType] ------------------
Create table [PropertyManagement].[RoomType]
(
	ID int identity(1, 1) primary key,
	[Type] nvarchar(150) not null,
	[Description] nvarchar(250) null
)
GO

-------------- [PropertyManagement].[Rooms] ------------------
CREATE TABLE [PropertyManagement].[Rooms] (
	ID int identity(1, 1) primary key,
	[Name] nvarchar(255) not null,
	QuantityRooms int not null,
	PricePerNight decimal(10,2) not null,
	RoomTypeId int not null,
	PropertyId int not null,
	PeopleCapacity int not null,
	constraint FK_Rooms_RoomTypeId foreign key (RoomTypeId) references PropertyManagement.RoomType(ID),
	constraint FK_Rooms_PropertyId foreign key (PropertyId) references PropertyManagement.Properties(ID)
)
GO

-------------- [BookingManagement].[BookingDetail] ------------------
Create table [BookingManagement].[BookingDetail]
(
	ID int identity(1, 1) primary key,
	BookingId int not null,
	RoomId int not null,
	GuestName nvarchar(100) not null,
	TotalPrice decimal(10,2) not null,
	CreatedAt datetime default current_timestamp,
	constraint FK_BookingDetail_BookingId foreign key (BookingId) references BookingManagement.Bookings(ID),
	constraint FK_BookingDetail_RoomId foreign key (RoomId) references PropertyManagement.Rooms(ID)
)
GO

----------------- [PropertyManagement].[Reviews] ------------------
Create table [PropertyManagement].[Reviews] 
(
    ID int identity(1, 1) primary key,
    PropertyId int not null,
    UserId int not null,
    Rating int check (Rating between 1 and 5),
    Comment nvarchar(max),
    CreatedAt datetime default current_timestamp,
    constraint FK_Reviews_PropertyId foreign key (PropertyId) references PropertyManagement.Properties(ID),
    constraint FK_Reviews_UserId foreign key (UserId) references UserManagement.Users(ID)
)
GO

----------------- [PropertyManagement].[Amenities] ------------------
Create table [PropertyManagement].[Amenities] 
(
    ID int identity(1, 1) primary key,
    [Description] nvarchar(50) not null unique
)
GO

----------------- [PropertyManagement].[PropertyAmenities] ------------------
Create table [PropertyManagement].[PropertyAmenities] 
(
    PropertyId int not null,
    AmenityId int not null,
    primary key (PropertyId, AmenityId),
    constraint FK_PropertyAmenities_PropertyId foreign key (PropertyId) references PropertyManagement.Properties(ID),
    constraint FK_PropertyAmenities_AmenityId foreign key (AmenityId) references PropertyManagement.Amenities(ID)
)
GO

----------------- [UserManagement].[Favorites] ------------------
Create table [UserManagement].[Favorites] 
(
    UserId int not null,
    PropertyId int not null,
    constraint FK_Favorites_UserId foreign key (UserId) references UserManagement.Users(ID),
    constraint FK_Favorites_PropertyId foreign key (PropertyId) references PropertyManagement.Properties(ID)
)
GO

----------------- [TransportManagement].[Airlines] ------------------
Create table [TransportManagement].[Airlines] 
(
    ID int identity(1, 1) primary key,
    [Name] nvarchar(100) not null,
    Code nvarchar(10) unique not null
)
GO

----------------- [TransportManagement].[Flights] ------------------
Create table [TransportManagement].[Flights]
(
    ID int identity(1, 1) primary key,
    AirlineId int not null,
    FlightNumber nvarchar(20) not null,
    DepartureAirport nvarchar(50) not null,
    ArrivalAirport nvarchar(50) not null,
    DepartureTime datetime not null,
    ArrivalTime datetime not null,
    Price decimal(10, 2) not null,
    constraint FK_Flights_AirlineId foreign key (AirlineId) references TransportManagement.Airlines(ID)
)
GO

----------------- [BookingManagement].[FlightBookings] ------------------
Create table [BookingManagement].[FlightBookings]
(
    ID int identity(1, 1) primary key,
    UserId int not null,
    FlightId int not null,
    NumberOfPeople int not null,
    TotalAmount decimal(10, 2) not null,
    BookingStatusId int  default(1),
	PaymentMethodId int not null,
	Discount decimal(10,2) null,
    CreatedAt datetime default current_timestamp,
    constraint FK_FlightBookings_UserId foreign key (UserId) references UserManagement.Users(ID),
    constraint FK_FlightBookings_FlightId foreign key (FlightId) references TransportManagement.Flights(ID),
    constraint FK_FlightBookings_BookingStatusId foreign key (BookingStatusId) references BookingManagement.BookingStatus(ID),
	constraint FK_FlightBookings_PaymentMethodId foreign key (PaymentMethodId) references PaymentManagement.PaymentMethods(ID)
)
GO

----------------- [TransportManagement].[RentalCompanies] ------------------
Create table [TransportManagement].[RentalCompanies]
(
    ID int identity(1, 1) primary key,
    [Name] nvarchar(100) not null,
    [Location] nvarchar(100),
    ContactInfo nvarchar(100)
)
GO

----------------- [TransportManagement].[Cars] ------------------
Create table [TransportManagement].[Cars] 
(
    ID int identity(1, 1) primary key,
    CompanyId int not null,
    Make nvarchar(50) not null,
    Model nvarchar(50) not null,
    [Year] int not null,
    DailyRate decimal(10, 2) not null,
    IsRented tinyint default (0),
    constraint FK_Cars_CompanyId foreign key (CompanyId) references TransportManagement.RentalCompanies(ID)
)
GO

----------------- [TransportManagement].[CarRentals] ------------------
Create table [TransportManagement].[CarRentals]
(
    ID int identity(1, 1) primary key,
    UserId int not null,
    CarId int not null,
    StartDate date not null,
    EndDate date not null,
    TotalAmount decimal(10, 2) not null,
    RentalStatusId int default (1),
	PaymentMethodId int not null,
	Discount decimal(10,2) null,
    CreatedAt datetime default current_timestamp,
    constraint FK_CarRentals_UserId foreign key (UserId) references UserManagement.Users(ID),
    constraint FK_CarRentals_CarId foreign key (CarId) references TransportManagement.Cars(ID),
	constraint FK_CarRentals_RentalStatusId foreign key (RentalStatusId) references BookingManagement.BookingStatus(ID),
	constraint FK_CarRentals_PaymentMethodId foreign key (PaymentMethodId) references PaymentManagement.PaymentMethods(ID)
)
GO

----------------- [TransportManagement].[TaxiServices] ------------------
Create table [TransportManagement].[TaxiServices]
(
    ID int identity(1, 1) primary key,
    [Name] nvarchar(100) not null,
    ContactInfo nvarchar(100)
)
GO

----------------- [BookingManagement].[TaxiBookings] ------------------
Create table [BookingManagement].[TaxiBookings] 
(
    ID int identity(1, 1) primary key,
    UserId int not null,
    TaxiServiceId int not null,
    PickupLocation nvarchar(100) not null,
    DropoffLocation nvarchar(100) not null,
    PickupTime datetime not null,
    EstimatedPrice decimal(10, 2) not null,
    BookingStatusId int default (1),
	PaymentMethodId int not null,
    CreatedAt datetime default current_timestamp,
    constraint FK_TaxiBookings_UserId foreign key (UserId) references UserManagement.Users(ID),
    constraint FK_TaxiBookings_TaxiServiceId foreign key (TaxiServiceId) references TransportManagement.TaxiServices(ID),
	constraint FK_TaxiBookings_BookingStatusId foreign key (BookingStatusId) references BookingManagement.BookingStatus(ID),
	constraint FK_TaxiBookings_PaymentMethodId foreign key (PaymentMethodId) references PaymentManagement.PaymentMethods(ID)
)
GO

----------------- [HistoryManagement].[CarRentalPaymentHistory] ------------------
Create table [HistoryManagement].[CarRentalPaymentHistory]
(
	 ID int identity(1, 1) primary key,
	 CarRentalId int not null,
	 AmountPaid decimal(10,2) not null,
	 CreatedAt datetime default current_timestamp,
	 constraint FK_CarRentalPaymentHistory_CarRentalId foreign key (CarRentalId) references TransportManagement.CarRentals(ID),
)
GO

----------------- [HistoryManagement].[TaxiBookingPaymentHistory] ------------------
Create table [HistoryManagement].[TaxiBookingPaymentHistory]
(
	 ID int identity(1, 1) primary key,
	 TaxiBookingId int not null,
	 AmountPaid decimal(10,2) not null,
	 CreatedAt datetime default current_timestamp,
	 constraint FK_TaxiBookingPaymentHistory_TaxiBookingId foreign key (TaxiBookingId) references BookingManagement.TaxiBookings(ID),
)
GO

----------------- [HistoryManagement].[FlightBookingPaymentHistory] ------------------
Create table [HistoryManagement].[FlightBookingPaymentHistory]
(
	 ID int identity(1, 1) primary key,
	 FlightBookingId int not null,
	 AmountPaid decimal(10,2) not null,
	 CreatedAt datetime default current_timestamp,
	 constraint FK_CFlightBookingPaymentHistory_FlightBookingId foreign key (FlightBookingId) references BookingManagement.FlightBookings(ID),
)
GO

