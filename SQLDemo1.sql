--CREATE DATABASE AND TABLES
CREATE DATABASE LibraryDB;
GO
USE LibraryDB;
GO

CREATE TABLE Category (
    CategoryID   INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL
);

CREATE TABLE Author (
    AuthorID  INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName  VARCHAR(50) NOT NULL,
    Country   VARCHAR(50)
);

CREATE TABLE Staff (
    StaffID   INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName  VARCHAR(50) NOT NULL,
    Role      VARCHAR(30) NOT NULL
);

CREATE TABLE Member (
    MemberID  INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName  VARCHAR(50) NOT NULL,
    Email     VARCHAR(100) NOT NULL UNIQUE,
    Phone     VARCHAR(15),
    JoinDate  DATE NOT NULL
);

CREATE TABLE Book (
    BookID          INT IDENTITY(1,1) PRIMARY KEY,
    Title           VARCHAR(150) NOT NULL,
    ISBN            VARCHAR(13) NOT NULL UNIQUE,
    PublishYear     INT,
    CopiesTotal     INT NOT NULL,
    CopiesAvailable INT NOT NULL,
    AuthorID        INT NOT NULL REFERENCES Author(AuthorID),
    CategoryID      INT NOT NULL REFERENCES Category(CategoryID),
    CHECK (CopiesAvailable >= 0 AND CopiesAvailable <= CopiesTotal)
);

CREATE TABLE Loan (
    LoanID     INT IDENTITY(1,1) PRIMARY KEY,
    LoanDate   DATE NOT NULL,
    DueDate    DATE NOT NULL,
    ReturnDate DATE,
    BookID     INT NOT NULL REFERENCES Book(BookID),
    MemberID   INT NOT NULL REFERENCES Member(MemberID),
    StaffID    INT NOT NULL REFERENCES Staff(StaffID),
    CHECK (DueDate >= LoanDate)
);

CREATE TABLE Fine (
    FineID      INT IDENTITY(1,1) PRIMARY KEY,
    Amount      DECIMAL(6,2) NOT NULL,
    FineDate    DATE NOT NULL,
    PaymentDate DATE,
    LoanID      INT NOT NULL UNIQUE REFERENCES Loan(LoanID)
);

--TEST DATA 
INSERT INTO Category (CategoryName) VALUES
('Fiction'),
('Non-Fiction'),
('Science'),
('Technology'),
('History'),
('Biography'),
('Business'),
('Children');

INSERT INTO Author (FirstName, LastName, Country) VALUES
('Chinua', 'Achebe', 'Nigeria'),
('Chimamanda', 'Adichie', 'Nigeria'),
('Nadine', 'Gordimer', 'South Africa'),
('J.M.', 'Coetzee', 'South Africa'),
('Neshani', 'Andreetta', 'Namibia'),
('Joseph', 'Diescho', 'Namibia'),
('Sam', 'Nujoma', 'Namibia'),
('George', 'Orwell', 'United Kingdom'),
('Agatha', 'Christie', 'United Kingdom'),
('Stephen', 'Hawking', 'United Kingdom'),
('Yuval Noah', 'Harari', 'Israel'),
('Robert', 'Kiyosaki', 'United States'),
('Harper', 'Lee', 'United States'),
('Dan', 'Brown', 'United States'),
('Trevor', 'Noah', 'South Africa'),
('Paulo', 'Coelho', 'Brazil'),
('Ramez', 'Elmasri', 'United States'),
('Abraham', 'Silberschatz', 'United States'),
('Carl', 'Sagan', 'United States'),
('Roald', 'Dahl', 'United Kingdom');

INSERT INTO Staff (FirstName, LastName, Role) VALUES
('Maria', 'Shikongo', 'Librarian'),
('Tuyeni', 'Amupolo', 'Librarian'),
('Johannes', 'Haufiku', 'Assistant'),
('Selma', 'Nghidinwa', 'Assistant'),
('Petrus', 'Kandjii', 'Manager'),
('Anna', 'Iyambo', 'Librarian');

INSERT INTO Member (FirstName, LastName, Email, Phone, JoinDate) VALUES
('Ndapewa', 'Shilongo', 'ndapewa.shilongo@gmail.com', '0811234501', '2024-02-05'),
('Tangeni', 'Nakale', 'tangeni.nakale@gmail.com', '0811234502', '2024-02-12'),
('Johanna', 'Amukwaya', 'johanna.amukwaya@gmail.com', '0811234503', '2024-03-01'),
('Festus', 'Haimbili', 'festus.haimbili@gmail.com', '0811234504', '2024-03-18'),
('Lydia', 'Mbako', 'lydia.mbako@gmail.com', '0811234505', '2024-04-02'),
('Elias', 'Nghipandulwa', 'elias.nghipandulwa@gmail.com', '0811234506', '2024-04-20'),
('Rauna', 'Iipinge', 'rauna.iipinge@gmail.com', '0811234507', '2024-05-07'),
('Simon', 'Kauluma', 'simon.kauluma@gmail.com', '0811234508', '2024-05-25'),
('Hilma', 'Nekongo', 'hilma.nekongo@gmail.com', '0811234509', '2024-06-10'),
('Martin', 'Shaanika', 'martin.shaanika@gmail.com', '0811234510', '2024-07-01'),
('Saara', 'Kapewasha', 'saara.kapewasha@gmail.com', '0811234511', '2024-07-22'),
('Immanuel', 'Hamunyela', 'immanuel.hamunyela@gmail.com', '0811234512', '2024-08-14'),
('Loide', 'Ndjaba', 'loide.ndjaba@gmail.com', '0811234513', '2024-09-03'),
('Abner', 'Mwandingi', 'abner.mwandingi@gmail.com', '0811234514', '2024-09-27'),
('Emilia', 'Nangolo', 'emilia.nangolo@gmail.com', '0811234515', '2024-10-15'),
('Kaarina', 'Uugwanga', 'kaarina.uugwanga@gmail.com', '0811234516', '2024-11-04'),
('Tobias', 'Mutorwa', 'tobias.mutorwa@gmail.com', '0811234517', '2025-01-13'),
('Frieda', 'Tjivikua', 'frieda.tjivikua@gmail.com', '0811234518', '2025-02-06'),
('Gideon', 'Kavendji', 'gideon.kavendji@gmail.com', '0811234519', '2025-03-11'),
('Vistorina', 'Hoeses', 'vistorina.hoeses@gmail.com', '0811234520', '2025-04-08'),
('Leonard', 'Beukes', 'leonard.beukes@gmail.com', '0811234521', '2025-05-19'),
('Naomi', 'Nambala', 'naomi.nambala@gmail.com', '0811234522', '2025-06-30'),
('David', 'Katjiuongua', 'david.katjiuongua@gmail.com', '0811234523', '2025-08-04'),
('Rebecca', 'Gaoses', 'rebecca.gaoses@gmail.com', '0811234524', '2025-09-16'),
('Paulus', 'Ipinge', 'paulus.ipinge@gmail.com', '0811234525', '2026-01-21');

INSERT INTO Book (Title, ISBN, PublishYear, CopiesTotal, CopiesAvailable, AuthorID, CategoryID) VALUES
('Things Fall Apart', '9780385474542', 1958, 4, 4, 1, 1),
('Half of a Yellow Sun', '9780007200283', 2006, 3, 3, 2, 1),
('The Conservationist', '9780140032376', 1974, 3, 3, 3, 1),
('Disgrace', '9780099289524', 1999, 4, 4, 4, 1),
('The Purple Violet of Oshaantu', '9781770220119', 2001, 3, 3, 5, 1),
('Born of the Struggle', '9789991600014', 2013, 3, 3, 6, 1),
('Where Others Wavered', '9780901787064', 2001, 3, 3, 7, 6),
('Nineteen Eighty-Four', '9780451524935', 1949, 5, 5, 8, 1),
('Animal Farm', '9780451526342', 1945, 5, 5, 8, 1),
('Murder on the Orient Express', '9780062693662', 1934, 4, 4, 9, 1),
('And Then There Were None', '9780062073488', 1939, 4, 4, 9, 1),
('A Brief History of Time', '9780553380163', 1988, 4, 4, 10, 3),
('Sapiens', '9780062316110', 2011, 6, 6, 11, 5),
('Homo Deus', '9780062464316', 2015, 4, 4, 11, 2),
('Rich Dad Poor Dad', '9781612680194', 1997, 5, 5, 12, 7),
('To Kill a Mockingbird', '9780061120084', 1960, 5, 5, 13, 1),
('The Da Vinci Code', '9780307474278', 2003, 4, 4, 14, 1),
('Born a Crime', '9780399588174', 2016, 5, 5, 15, 6),
('The Alchemist', '9780062315007', 1988, 6, 6, 16, 1),
('Fundamentals of Database Systems', '9780133970777', 2015, 3, 3, 17, 4),
('Database System Concepts', '9780078022159', 2019, 3, 3, 18, 4),
('Cosmos', '9780345539434', 1980, 3, 3, 19, 3),
('Matilda', '9780142410370', 1988, 4, 4, 20, 8),
('The BFG', '9780142410387', 1982, 4, 4, 20, 8),
('Charlie and the Chocolate Factory', '9780142410318', 1964, 4, 4, 20, 8);

INSERT INTO Loan (LoanDate, DueDate, ReturnDate, BookID, MemberID, StaffID) VALUES
('2025-10-06', '2025-10-20', '2025-10-18', 13, 1, 1),
('2025-10-08', '2025-10-22', '2025-10-30', 8, 2, 2),
('2025-10-15', '2025-10-29', '2025-10-27', 19, 3, 1),
('2025-10-20', '2025-11-03', '2025-11-03', 1, 4, 3),
('2025-10-27', '2025-11-10', '2025-11-08', 18, 5, 2),
('2025-11-03', '2025-11-17', '2025-11-25', 9, 6, 4),
('2025-11-05', '2025-11-19', '2025-11-14', 16, 7, 1),
('2025-11-10', '2025-11-24', '2025-11-21', 12, 8, 6),
('2025-11-12', '2025-11-26', '2025-11-26', 15, 9, 2),
('2025-11-17', '2025-12-01', '2025-12-05', 20, 10, 3),
('2025-11-24', '2025-12-08', '2025-12-02', 21, 11, 1),
('2025-12-01', '2025-12-15', '2025-12-12', 2, 12, 5),
('2025-12-03', '2025-12-17', '2025-12-16', 10, 13, 4),
('2025-12-08', '2025-12-22', '2026-01-02', 17, 14, 2),
('2025-12-10', '2025-12-24', '2025-12-20', 23, 15, 6),
('2025-12-15', '2025-12-29', '2025-12-29', 24, 16, 1),
('2026-01-05', '2026-01-19', '2026-01-15', 25, 17, 3),
('2026-01-07', '2026-01-21', '2026-01-19', 13, 18, 2),
('2026-01-12', '2026-01-26', '2026-02-03', 4, 19, 4),
('2026-01-14', '2026-01-28', '2026-01-27', 19, 20, 1),
('2026-01-19', '2026-02-02', '2026-01-30', 3, 21, 6),
('2026-01-21', '2026-02-04', '2026-02-04', 22, 22, 2),
('2026-01-26', '2026-02-09', '2026-02-06', 5, 23, 5),
('2026-02-02', '2026-02-16', '2026-02-26', 8, 24, 3),
('2026-02-04', '2026-02-18', '2026-02-13', 14, 25, 1),
('2026-02-09', '2026-02-23', '2026-02-20', 6, 1, 4),
('2026-02-11', '2026-02-25', '2026-02-24', 11, 3, 2),
('2026-02-16', '2026-03-02', '2026-03-02', 13, 5, 6),
('2026-02-18', '2026-03-04', '2026-03-10', 18, 7, 1),
('2026-02-23', '2026-03-09', '2026-03-05', 9, 9, 3),
('2026-03-02', '2026-03-16', '2026-03-13', 15, 11, 2),
('2026-03-04', '2026-03-18', '2026-03-17', 20, 13, 5),
('2026-03-09', '2026-03-23', '2026-03-30', 7, 15, 4),
('2026-03-11', '2026-03-25', '2026-03-24', 19, 17, 1),
('2026-03-16', '2026-03-30', '2026-03-27', 1, 19, 6),
('2026-03-18', '2026-04-01', '2026-04-01', 16, 21, 2),
('2026-03-23', '2026-04-06', '2026-04-02', 12, 23, 3),
('2026-03-25', '2026-04-08', '2026-04-15', 17, 2, 1),
('2026-04-06', '2026-04-20', '2026-04-17', 13, 4, 4),
('2026-04-08', '2026-04-22', '2026-04-21', 21, 6, 2),
('2026-04-13', '2026-04-27', '2026-04-24', 2, 8, 5),
('2026-04-15', '2026-04-29', '2026-05-06', 10, 10, 6),
('2026-04-20', '2026-05-04', '2026-05-01', 23, 12, 1),
('2026-05-04', '2026-05-18', '2026-05-15', 24, 14, 3),
('2026-05-06', '2026-05-20', '2026-05-19', 18, 16, 2),
('2026-05-11', '2026-05-25', '2026-05-22', 8, 18, 4),
('2026-05-18', '2026-06-01', '2026-06-01', 19, 20, 1),
('2026-06-01', '2026-06-15', '2026-06-12', 13, 22, 6),
('2026-06-08', '2026-06-22', '2026-06-29', 15, 24, 2),
('2026-06-15', '2026-06-29', '2026-06-26', 9, 25, 3),
('2026-07-06', '2026-07-20', '2026-07-17', 1, 3, 1),
('2026-07-13', '2026-07-27', '2026-07-24', 16, 5, 5),
('2026-07-20', '2026-08-03', '2026-08-01', 14, 7, 2),
('2026-08-03', '2026-08-17', '2026-08-14', 20, 9, 4),
('2026-08-10', '2026-08-24', '2026-08-21', 12, 11, 6),
('2026-08-17', '2026-08-31', NULL, 13, 13, 1),
('2026-08-24', '2026-09-07', NULL, 8, 15, 2),
('2026-09-01', '2026-09-15', NULL, 18, 17, 3),
('2026-09-07', '2026-09-21', NULL, 19, 19, 4),
('2026-09-14', '2026-09-28', NULL, 4, 21, 1),
('2026-09-21', '2026-10-05', NULL, 1, 23, 6),
('2026-09-28', '2026-10-12', NULL, 12, 25, 2),
('2026-09-30', '2026-10-14', NULL, 22, 1, 5);

INSERT INTO Fine (Amount, FineDate, PaymentDate, LoanID) VALUES
(16.00, '2025-10-30', '2025-11-03', 2),
(16.00, '2025-11-25', NULL, 6),
(8.00,  '2025-12-05', '2025-12-05', 10),
(22.00, '2026-01-02', '2026-01-12', 14),
(16.00, '2026-02-03', '2026-02-10', 19),
(20.00, '2026-02-26', NULL, 24),
(12.00, '2026-03-10', '2026-03-10', 29),
(14.00, '2026-03-30', '2026-04-14', 33),
(14.00, '2026-04-15', NULL, 38),
(14.00, '2026-05-06', '2026-05-20', 42),
(14.00, '2026-06-29', NULL, 49);

UPDATE Book
SET CopiesAvaila+ble = CopiesTotal - (SELECT COUNT(*) FROM Loan
                                     WHERE Loan.BookID = Book.BookID
                                     AND Loan.ReturnDate IS NULL);

-- CHECK RECORD COUNTS 
SELECT 'Category' AS TableName, COUNT(*) AS Total FROM Category
UNION ALL SELECT 'Author', COUNT(*) FROM Author
UNION ALL SELECT 'Staff', COUNT(*) FROM Staff
UNION ALL SELECT 'Member', COUNT(*) FROM Member
UNION ALL SELECT 'Book', COUNT(*) FROM Book
UNION ALL SELECT 'Loan', COUNT(*) FROM Loan
UNION ALL SELECT 'Fine', COUNT(*) FROM Fine;

--BASIC SQL: INSERT, UPDATE, DELETE
INSERT INTO Member (FirstName, LastName, Email, Phone, JoinDate)
VALUES ('Test', 'Member', 'test.member@gmail.com', '0810667890', '2026-10-01');

UPDATE Member SET Phone = '0819999999' WHERE Email = 'test.member@gmail.com';

DELETE FROM Member WHERE Email = 'test.member@gmail.com';

--BASIC SQL: SELECT, WHERE, ORDER BY, DISTINCT
SELECT * FROM Book;

SELECT Title, PublishYear FROM Book WHERE PublishYear > 2000;

SELECT FirstName, LastName FROM Member ORDER BY LastName;

SELECT DISTINCT Country FROM Author;

SELECT * FROM Fine WHERE PaymentDate IS NULL;

--BASIC SQL: LIKE, BETWEEN, IN
SELECT Title FROM Book WHERE Title LIKE 'The%';

SELECT Title, PublishYear FROM Book WHERE PublishYear BETWEEN 1990 AND 2010;

SELECT FirstName, LastName, Country FROM Author
WHERE Country IN ('Namibia', 'South Africa');

--FUNCTIONS: STRING, DATE, MATH, CONVERSION
SELECT FirstName + ' ' + LastName AS FullName, UPPER(Email) AS EmailUpper
FROM Member;

SELECT Title, LEN(Title) AS TitleLength FROM Book;

SELECT LoanID, DATEDIFF(DAY, LoanDate, ReturnDate) AS DaysKept
FROM Loan
WHERE ReturnDate IS NOT NULL;

SELECT LoanID, YEAR(LoanDate) AS LoanYear, MONTH(LoanDate) AS LoanMonth
FROM Loan;

SELECT FineID, Amount, ROUND(Amount / 3, 2) AS ThirdOfFine,
       CAST(Amount AS INT) AS WholeAmount
FROM Fine;

SELECT LoanID, CONVERT(VARCHAR(10), LoanDate, 103) AS LoanDateFormatted
FROM Loan;

--AGGREGATES: COUNT, SUM, AVG, MIN, MAX
SELECT COUNT(*) AS TotalLoans FROM Loan;

SELECT SUM(Amount) AS TotalFines,
       AVG(Amount) AS AverageFine,
       MIN(Amount) AS SmallestFine,
       MAX(Amount) AS LargestFine
FROM Fine;

--GROUP BY AND HAVING
SELECT CategoryID, COUNT(*) AS NumberOfBooks
FROM Book
GROUP BY CategoryID;

SELECT MemberID, COUNT(*) AS NumberOfLoans
FROM Loan
GROUP BY MemberID
HAVING COUNT(*) > 2;

--REPORT 1: TOP 5 MOST BORROWED BOOKS
SELECT TOP 5 b.Title, COUNT(*) AS TimesBorrowed
FROM Loan l
JOIN Book b ON l.BookID = b.BookID
GROUP BY b.Title
ORDER BY TimesBorrowed DESC;

--REPORT 2: CURRENTLY OVERDUE BOOKS
SELECT m.FirstName + ' ' + m.LastName AS Member,
       b.Title,
       l.DueDate,
       DATEDIFF(DAY, l.DueDate, GETDATE()) AS DaysOverdue
FROM Loan l
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book b ON l.BookID = b.BookID
WHERE l.ReturnDate IS NULL AND l.DueDate < GETDATE()
ORDER BY DaysOverdue DESC;

--REPORT 3: UNPAID FINES PER MEMBER
SELECT m.FirstName + ' ' + m.LastName AS Member,
       COUNT(f.FineID) AS UnpaidFines,
       SUM(f.Amount) AS TotalOwed
FROM Fine f
JOIN Loan l ON f.LoanID = l.LoanID
JOIN Member m ON l.MemberID = m.MemberID
WHERE f.PaymentDate IS NULL
GROUP BY m.FirstName, m.LastName
ORDER BY TotalOwed DESC;