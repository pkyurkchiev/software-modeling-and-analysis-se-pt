Insert into [BookingManagement].[BookingStatus] 
values
('Pending'),
('Confirmed'),
('Cancelled')
GO

Insert into [PaymentManagement].[PaymentMethods] 
values
('Credit Card'),
('Debit Card'),
('PayPal'),
('Bank Transfer')
GO

Insert into UserManagement.Users (FirstName, LastName, Username, Email, [Password], PhoneNumber, IsHost) values 
('Mihaela', 'Peneva', 'mihaela_peneva', 'peneva@gmail.com', 'password123', '123456789', 0),
('Petar', 'Todorov', 'petar_todorov', 'todorov@gmail.com', 'password589', '122446789', 0),
('Iva', 'Tananska', 'ivaT', 'tananaska@gmail.com', 'password456', '987654321', 1),
('Victoria', 'Toteva', 'vToteva', 'toteva@gmail.com', 'password789', '555555555', 1),
('Nikolay', 'Dimitrov', 'nikolay_d', 'dimitrov@gmail.com', 'password321', '111222333', 0),
('Elena', 'Stoyanova', 'elena_s', 'stoyanova@gmail.com', 'password654', '444555666', 1),
('Georgi', 'Petrov', 'georgi_p', 'petrov@gmail.com', 'password789', '777888999', 0),
('Kristina', 'Ivanova', 'kristina_i', 'ivanova@gmail.com', 'password987', '222333444', 1)
GO

Insert into LocationManagement.Locations(City, Country) values 
('Primorsko', 'Bulgaria'),
('Banite', 'Bulgaria'),
('Dospat', 'Bulgaria'),
('Lom', 'Bulgaria'),
('Bansko', 'Bulgaria'),
('Plovdiv', 'Bulgaria'),
('Varna', 'Bulgaria'),
('Sofia', 'Bulgaria')
GO

Insert into PropertyManagement.PropertyTypes([Type]) values
('Apartment'),
('Villa'),
('Hotel'),
('Guest House'),
('Hostel'),
('Bungalou')
GO

Insert into PropertyManagement.Properties (HostId, [Name], [Description], StreetInfo, LocationId, PropertyTypeId) values 
(3, 'Sea View Apartment', 'Beautiful sea view apartment with two bedrooms', 'ul. Dunav 56', 1, 1),
(4, 'Mountain Apartment', 'Cozy apartment in the mountains', 'ul. Orfei 9', 3, 1),
(3, 'Hotel Panorama', 'Hotel in the mountains with spa and swimming pools with mineral water.', 'ul. Georgi Rakovski', 2, 3),
(4, 'Guest House Kalina', 'Guest House near river Dunav with excellent view and good location.', 'ul. Petar Beron', 4, 4),
(5, 'Villa in Bansko', 'Cozy Villa located in the mountains', 'ul. Pirin 17', 5, 2),
(5, 'Sofia City Center Apartment', 'Modern apartment in the heart of Sofia', 'ul. Vitosha 12', 4, 1),
(5, 'Seaside Villa', 'Luxury villa with private pool', 'ul. Morski Briz 45', 3, 2),
(4, 'Hostel near Plovdiv', 'Rustic Hostel with beautiful garden', 'ul. Vasil Levski 21', 6, 5)
GO

Insert into PropertyManagement.RoomType([Type], [Description]) values
('one bedroom apartment', 'two single beds'),
('two bedroom apartment', 'two double beds'),
('three bedroom apartment', 'three double beds'),
('apartment with terrace', 'one double bed'),
('queen room', 'one double bed'),
('standard double room', 'two single beds'),
('standard triple room', 'three single beds'),
('deluxe twin room', 'two single beds'),
('deluxe double room', 'one double bed'),
('deluxe family room', 'two double beds'),
('standard one bedroom', 'single bed')
GO

Insert into PropertyManagement.Rooms ([Name], QuantityRooms, PricePerNight, RoomTypeId, PropertyId, PeopleCapacity) values
('Queen Double', 5, 100.00, 6, 3, 2),
('Standart Double', 10, 60.00, 7, 3, 2),
('Standart Triple', 5, 90.00, 8, 3, 3),
('Two Bedroom Apartment', 2, 170.00, 2, 1, 4),
('Three Bedroom Apartment', 3, 200.00, 3, 2, 6),
('Deluxe Double Room', 15, 70.00, 10, 4, 2),
('Luxury Suite', 5, 300.00, 1, 4, 2),
('Family Suite', 10, 200.00, 2, 3, 4),
('Single Room', 15, 30.00, 11, 8, 1),
('Studio Apartment', 3, 120.00, 3, 6, 3)
GO

Insert into BookingManagement.Bookings(UserId, CheckInDate, CheckOutDate, NumberOfPeople, TotalAmount, BookingStatusId, PaymentMethodId, Discount) values 
(1, '2024-11-05', '2024-11-10', 4, 500.00, 2 , 10),
(1, '2024-10-25', '2024-10-27', 2, 900.00, 1 , 0),
(2, '2024-12-01', '2024-12-10', 3, 450.00, 1 , 0),
(5, '2024-11-15', '2024-11-20', 2, 600.00, 2 , 5),
(6, '2024-12-05', '2024-12-12', 1, 350.00, 1 , 0),
(7, '2024-11-10', '2024-11-15', 3, 450.00, 2 , 10)
GO

Insert into BookingManagement.BookingDetail(BookingId, RoomId, GuestName, TotalPrice) values
(1, 1, 'Mihaela Peneva ', 500.00),
(2, 1, 'Petar Todorov', 900.00),
(3, 5, 'Petar Todorov' ,400.00),
(4, 2, 'Nikolay Dimitrov', 600.00),
(5, 3, 'Elena Stoyanova', 350.00),
(6, 1, 'Georgi Petrov', 450.00)
GO

Insert into PropertyManagement.Reviews(PropertyId, UserId, Rating, Comment) values 
(3, 2, 5, 'Really nice hotel! The spa is really relaxing. The only problem is it`s a bit far from the city center.'),
(2, 2, 3, 'It was good for the amount of money we pay. But it is far away from the sea and the city center.'),
(2, 1, 4, 'Good!'),
(1, 3, 5, 'Absolutely fantastic place! Highly recommend.'),
(4, 1, 4, 'Nice location but a bit noisy.'),
(2, 4, 3, 'Average stay. Expected more for the price.')
GO

Insert into PropertyManagement.Amenities ([Description]) values 
('WiFi'),
('Parking'), 
('Pool'),
('Spa'), 
('Balcon'), 
('Fitness Center'), 
('Pets allowed')
GO

Insert into PropertyManagement.PropertyAmenities (PropertyId, AmenityId) values 
(1, 1),
(1, 2),
(2, 1),
(2, 2),
(2, 7),
(3, 1),
(3, 2),
(3, 3),
(3, 4),
(3, 6) 
GO

---- Insert Favourites
Insert into UserManagement.Favorites(UserId, PropertyId)
values 
(1, 1),
(2, 2), 
(3, 3), 
(4, 4)
GO

---- Insert Airlines and Flights
Insert into TransportManagement.Airlines (Name, Code)
values ('WizzAir', 'WZ'), ('RyanAir', 'RA'), ('Bulgarian Air', 'BA'), ('EasyJet', 'EJ'), ('Turkish Airlines', 'TK'), ('Lufthansa', 'LH');
GO

Insert into TransportManagement.Flights (AirlineId, FlightNumber, DepartureAirport, ArrivalAirport, DepartureTime, ArrivalTime, Price)
values 
(1, 'W64352', 'BGY', 'SOF', '2024-11-01 08:00:00', '2024-11-01 11:00:00', 300.00),
(2, 'RA1426', 'FRA', 'SOF', '2024-11-02 10:00:00', '2024-11-02 13:00:00', 350.00),
(6, 'LH1412', 'MUC', 'SOF', '2024-12-01 08:00:00', '2024-12-01 10:30:00', 400.00),
(5, 'TK2020', 'IST', 'SOF', '2024-12-02 09:00:00', '2024-12-02 12:00:00', 450.00)
GO

Insert into BookingManagement.FlightBookings (UserId, FlightId, NumberOfPeople, TotalAmount, BookingStatusId)
values 
(3, 1, 1, 300.00, 2),
(1, 3, 2, 800.00, 2),
(4, 2, 1, 450.00, 1)
GO

Insert into TransportManagement.RentalCompanies (Name, Location, ContactInfo)
values 
('AutoRent', 'Burgas', 'autorent@outlook.com'), 
('RentACar', 'Sofia', 'rentACar@outlook.com')
GO

Insert into TransportManagement.Cars (CompanyId, Make, Model, Year, DailyRate, IsRented)
values 
(1, 'Toyota', 'Camry', 2020, 45.00, 0),
(2, 'Ford', 'Explorer', 2019, 65.00, 0),
(2, 'Honda', 'Civic', 2021, 55.00, 0),
(1, 'BMW', 'X5', 2022, 85.00, 0)
GO

Insert into TransportManagement.CarRentals (UserId, CarID, StartDate, EndDate, TotalAmount, RentalStatusId)
values 
(1, 3, '2024-11-05', '2024-11-10', 225.00, 2),
(2, 4, '2024-10-25', '2024-10-27', 300.00, 1)
GO

Insert into [HistoryManagement].[BookingPaymentHistory]
(BookingId, AmountPaid, CreatedAt)
values
(1, 500.00, '2024-11-10'),
(2, 900.00, '2024-10-27'),
(3, 450.00, '2024-12-10')
GO

Insert into [HistoryManagement].[CarRentalPaymentHistory]
(CarRentalId, AmountPaid, CreatedAt)
values
(3, 225.00, '2024-10-05'),
(4, 300.00, '2024-10-15')
GO

Insert into [HistoryManagement].[FlightBookingPaymentHistory]
(FlightBookingId, AmountPaid, CreatedAt)
values
(1, 300.00, '2024-10-17')
GO

Insert into [TransportManagement].[TaxiServices] ([Name], ContactInfo)
values 
    ('Eco Taxi', '041 121 55'),
    ('Budget Taxi', '043 234 91')
GO

Insert into [BookingManagement].[TaxiBookings] 
(UserId, TaxiServiceId, PickupLocation, DropoffLocation, PickupTime, EstimatedPrice, BookingStatusId, PaymentMethodId, CreatedAt)
values 
    (1, 1, 'Airport Sofia Terminal 1', 'Ploshtad Suedinenie', '2024-10-16 11:15:00', 15.75, 1, 1, '2024-10-12 11:48:00'),
    (2, 2, 'Airport Sofia Terminal 2', 'National Palace of Culture', '2024-10-17 08:15:00', 22.50, 1, 2, '2024-10-10 18:19:00')
GO

Insert into [HistoryManagement].[TaxiBookingPaymentHistory]
(TaxiBookingId, AmountPaid, CreatedAt)
values
(1, 15.75, '2024-10-12 11:48:00'),
(2, 22.50, '2024-10-10 18:19:00')
GO