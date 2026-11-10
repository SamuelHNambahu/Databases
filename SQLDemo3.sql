USE LibraryDB;
SELECT COUNT(*) AS BookCount FROM Book;
SELECT COUNT(*) AS LoanCount FROM Loan;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Loan_Member_ReturnDate')
    DROP INDEX IX_Loan_Member_ReturnDate ON Loan;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fine_PaymentDate')
    DROP INDEX IX_Fine_PaymentDate ON Fine;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Loan_Book_ReturnDate')
    DROP INDEX IX_Loan_Book_ReturnDate ON Loan;
GO

---BEFORE TEST
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Query A: active loans for a member
SELECT LoanID, BookID, LoanDate, DueDate
FROM Loan
WHERE MemberID = 1 AND ReturnDate IS NULL;
GO

-- Query B: unpaid fines
SELECT FineID, Amount, FineDate
FROM Fine
WHERE PaymentDate IS NULL;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

---CREATE INDEXES
CREATE INDEX IX_Loan_Member_ReturnDate
ON Loan(MemberID, ReturnDate)
INCLUDE(BookID, LoanDate, DueDate);
GO

CREATE INDEX IX_Loan_Book_ReturnDate
ON Loan(BookID, ReturnDate)
INCLUDE(MemberID, DueDate);
GO

CREATE INDEX IX_Fine_PaymentDate
ON Fine(PaymentDate)
INCLUDE(LoanID, Amount, FineDate);
GO

---AFTER TEST
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT LoanID, BookID, LoanDate, DueDate
FROM Loan
WHERE MemberID = 1 AND ReturnDate IS NULL;
GO

SELECT FineID, Amount, FineDate
FROM Fine
WHERE PaymentDate IS NULL;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

---COMPLEX QUERY & EXECUTION PLAN
---QUERY 1 TOP5 BORROWED BOOKS
SELECT TOP 5 b.Title, COUNT(*) AS TimesBorrowed
FROM Loan l
JOIN Book b ON l.BookID = b.BookID
GROUP BY b.Title
ORDER BY TimesBorrowed DESC;
GO

---QUERY 2 CURRENTLY OVERDUE BOOKS
SELECT m.FirstName + ' ' + m.LastName AS Member,
       b.Title,
       l.DueDate,
       DATEDIFF(DAY, l.DueDate, GETDATE()) AS DaysOverdue
FROM Loan l
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book   b ON l.BookID   = b.BookID
WHERE l.ReturnDate IS NULL AND l.DueDate < GETDATE()
ORDER BY DaysOverdue DESC;
GO

---QUERY 3 UNPAID FINES PER MEMBER
SELECT m.FirstName + ' ' + m.LastName AS Member,
       COUNT(f.FineID) AS UnpaidFines,
       SUM(f.Amount)  AS TotalOwed
FROM Fine f
JOIN Loan l   ON f.LoanID  = l.LoanID
JOIN Member m ON l.MemberID = m.MemberID
WHERE f.PaymentDate IS NULL
GROUP BY m.FirstName, m.LastName
ORDER BY TotalOwed DESC;
GO

---QUERY OPTIMISATION(2 QUERIES BEFORE AND AFTER)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- QUERY 1 ORIGINAL (slow) YEAR() on column date filter
SELECT LoanID, MemberID, BookID, DueDate
FROM Loan
WHERE YEAR(DueDate) = 2026;
GO



-- OPTIMISED (SARGable)
SELECT LoanID, MemberID, BookID, DueDate
FROM LoanS
WHERE DueDate >= '2026-01-01' AND DueDate < '2027-01-01';
GO

---QUERY 2
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- ORIGINAL (slow)
SELECT Title
FROM Book
WHERE BookID NOT IN (SELECT BookID FROM Loan);
GO
-- OPTIMISED
SELECT b.Title
FROM Book b
WHERE NOT EXISTS (SELECT 1 FROM Loan l WHERE l.BookID = b.BookID);
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Realistic scenario: issue a loan atomically
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @BookID INT = 25;
    DECLARE @MemberID INT = 1;
    DECLARE @StaffID INT = 1;

    -- Pre-check: book must have copies available
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookID = @BookID AND CopiesAvailable > 0)
        THROW 50001, 'No copies available - cannot create loan.', 1;

    -- Insert the loan (trigger updates CopiesAvailable)
    INSERT INTO Loan (LoanDate, DueDate, ReturnDate, BookID, MemberID, StaffID)
    VALUES (CAST(GETDATE() AS DATE),
            DATEADD(DAY, 14, CAST(GETDATE() AS DATE)),
            NULL, @BookID, @MemberID, @StaffID);

    -- Confirm consistency before committing
    IF (SELECT CopiesAvailable FROM Book WHERE BookID = @BookID) < 0
        THROW 50002, 'CopiesAvailable went negative - aborting.', 1;

    COMMIT TRANSACTION;
    PRINT 'Loan committed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction rolled back: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Verify the loan exists
SELECT TOP 3 LoanID, BookID, MemberID, LoanDate, DueDate
FROM Loan
ORDER BY LoanID DESC;

-- Verify the copies decremented
SELECT BookID, Title, CopiesTotal, CopiesAvailable
FROM Book
WHERE BookID = 25;
GO

-- ROLLBACK revert an unintended change
BEGIN TRANSACTION;

UPDATE Member
SET Phone = '0000000000'
WHERE MemberID = 1;

-- Show the temporary change
SELECT MemberID, FirstName, LastName, Phone
FROM Member
WHERE MemberID = 1;

ROLLBACK TRANSACTION;

-- Show the original value restored
SELECT MemberID, FirstName, LastName, Phone
FROM Member
WHERE MemberID = 1;
GO