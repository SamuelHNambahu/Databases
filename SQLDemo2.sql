SELECT COUNT(*) AS TotalLoans FROM Loan;
--- Join1 books currently out
SELECT b.Title,
       m.FirstName + ' ' + m.LastName AS Member,
       s.FirstName + ' ' + s.LastName AS IssuedBy,
       l.LoanDate, l.DueDate
FROM Loan l
JOIN Book b ON l.BookID = b.BookID
JOIN Member m ON l.MemberID = m.MemberID
JOIN Staff s ON l.StaffID = s.StaffID
WHERE l.ReturnDate IS NULL
ORDER BY l.DueDate;

---join 2 every loan with its fine
SELECT l.LoanID,
       m.FirstName + ' ' + m.LastName AS Member,
       b.Title, l.DueDate, l.ReturnDate,
       f.Amount, f.PaymentDate
FROM Loan l
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book b ON l.BookID = b.BookID
LEFT JOIN Fine f ON l.LoanID = f.LoanID
ORDER BY l.LoanID;

--- Join 3 loans per category
SELECT c.CategoryName, COUNT(*) AS TotalLoans
FROM Loan l
JOIN Book b ON l.BookID = b.BookID
JOIN Category c ON b.CategoryID = c.CategoryID
GROUP BY c.CategoryName
ORDER BY TotalLoans DESC;

---subquery1 members who still owe a fine
SELECT FirstName, LastName
FROM Member
WHERE MemberID IN (SELECT MemberID FROM Loan
                   WHERE LoanID IN (SELECT LoanID FROM Fine
                                    WHERE PaymentDate IS NULL));

--- subquery 2 fines above the average
SELECT FineID, Amount, LoanID
FROM Fine
WHERE Amount > (SELECT AVG(Amount) FROM Fine);

--- subquery 3 members with no book out
SELECT FirstName, LastName
FROM Member
WHERE MemberID NOT IN (SELECT MemberID FROM Loan WHERE ReturnDate IS NULL);



--VIEWS
DROP VIEW IF EXISTS vw_CurrentLoans;
GO
CREATE VIEW vw_CurrentLoans AS
SELECT l.LoanID, b.Title,
       m.FirstName + ' ' + m.LastName AS Member,
       l.LoanDate, l.DueDate
FROM Loan l
JOIN Book b ON l.BookID = b.BookID
JOIN Member m ON l.MemberID = m.MemberID
WHERE l.ReturnDate IS NULL;
GO

DROP VIEW IF EXISTS vw_UnpaidFines;
GO
CREATE VIEW vw_UnpaidFines AS
SELECT f.FineID,
       m.FirstName + ' ' + m.LastName AS Member,
       b.Title, f.Amount, f.FineDate
FROM Fine f
JOIN Loan l ON f.LoanID = l.LoanID
JOIN Member m ON l.MemberID = m.MemberID
JOIN Book b ON l.BookID = b.BookID
WHERE f.PaymentDate IS NULL;
GO

DROP VIEW IF EXISTS vw_BookPopularity;
GO
CREATE VIEW vw_BookPopularity AS
SELECT b.BookID, b.Title, COUNT(l.LoanID) AS TimesBorrowed
FROM Book b
LEFT JOIN Loan l ON b.BookID = l.BookID
GROUP BY b.BookID, b.Title;
GO

--STORED PROCEDURES
DROP PROCEDURE IF EXISTS usp_IssueBook;
GO
CREATE PROCEDURE usp_IssueBook
    @BookID INT, @MemberID INT, @StaffID INT
AS
BEGIN
    IF (SELECT CopiesAvailable FROM Book WHERE BookID = @BookID) = 0
        PRINT 'No copies of this book are available.';
    ELSE
        INSERT INTO Loan (LoanDate, DueDate, BookID, MemberID, StaffID)
        VALUES (CAST(GETDATE() AS DATE),
                DATEADD(DAY, 14, CAST(GETDATE() AS DATE)),
                @BookID, @MemberID, @StaffID);
END;
GO

DROP PROCEDURE IF EXISTS usp_ReturnBook;
GO
CREATE PROCEDURE usp_ReturnBook
    @LoanID INT
AS
BEGIN
    UPDATE Loan
    SET ReturnDate = CAST(GETDATE() AS DATE)
    WHERE LoanID = @LoanID AND ReturnDate IS NULL;
END;
GO

DROP PROCEDURE IF EXISTS usp_MemberHistory;
GO
CREATE PROCEDURE usp_MemberHistory
    @MemberID INT
AS
BEGIN
    SELECT l.LoanID, b.Title, l.LoanDate, l.DueDate, l.ReturnDate
    FROM Loan l
    JOIN Book b ON l.BookID = b.BookID
    WHERE l.MemberID = @MemberID
    ORDER BY l.LoanDate;
END;
GO

-- TRIGGERS 
-- Trigger 1: issuing a book lowers its available copies
DROP TRIGGER IF EXISTS trg_Loan_Insert;
GO
CREATE TRIGGER trg_Loan_Insert ON Loan
AFTER INSERT
AS
BEGIN
    UPDATE Book
    SET CopiesAvailable = CopiesAvailable
        - (SELECT COUNT(*) FROM inserted WHERE inserted.BookID = Book.BookID)
    WHERE BookID IN (SELECT BookID FROM inserted);
END;
GO

-- Trigger 2: returning a book restores the copy, and a late return creates a fine (N$2 per day)
DROP TRIGGER IF EXISTS trg_Loan_Return;
GO
CREATE TRIGGER trg_Loan_Return ON Loan
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ReturnDate)
    BEGIN
        UPDATE Book
        SET CopiesAvailable = CopiesAvailable
            + (SELECT COUNT(*) FROM inserted i JOIN deleted d ON i.LoanID = d.LoanID
               WHERE i.BookID = Book.BookID
                 AND d.ReturnDate IS NULL AND i.ReturnDate IS NOT NULL)
        WHERE BookID IN (SELECT BookID FROM inserted);

        INSERT INTO Fine (Amount, FineDate, PaymentDate, LoanID)
        SELECT DATEDIFF(DAY, i.DueDate, i.ReturnDate) * 2.00, i.ReturnDate, NULL, i.LoanID
        FROM inserted i JOIN deleted d ON i.LoanID = d.LoanID
        WHERE d.ReturnDate IS NULL AND i.ReturnDate > i.DueDate;
    END
END;
GO

--- EXECUTIONS

-- VIEWS
SELECT * FROM vw_CurrentLoans;
SELECT * FROM vw_UnpaidFines;
SELECT * FROM vw_BookPopularity ORDER BY TimesBorrowed DESC;

-- PROCEDURE 3: member history (read only)
EXEC usp_MemberHistory @MemberID = 15;

-- TRIGGERS: copies BEFORE
SELECT BookID, Title, CopiesAvailable FROM Book WHERE BookID IN (3, 8);

-- PROCEDURE 1 fires trigger 1: issue book 3 to member 2
EXEC usp_IssueBook @BookID = 3, @MemberID = 2, @StaffID = 1;

-- PROCEDURE 2 fires trigger 2: return loan 57 (book 8, which is overdue)
EXEC usp_ReturnBook @LoanID = 57;

-- TRIGGERS: copies AFTER, and the fine that was created automatically
SELECT BookID, Title, CopiesAvailable FROM Book WHERE BookID IN (3, 8);
SELECT * FROM Fine WHERE LoanID = 57;
SELECT TOP 1 * FROM Loan ORDER BY LoanID DESC;

--- INDEXING EXECUTION PLAN AND OPTIMISATIONS

-- Indexes on the real tables: foreign key columns are used in joins and lookups
DROP INDEX IF EXISTS IX_Loan_MemberID ON Loan;
DROP INDEX IF EXISTS IX_Loan_BookID ON Loan;
CREATE INDEX IX_Loan_MemberID ON Loan (MemberID);
CREATE INDEX IX_Loan_BookID ON Loan (BookID);
GO

-- Large test table (100,000 loans) so the index differences are visible
DROP TABLE IF EXISTS LoanLarge;
GO
CREATE TABLE LoanLarge (
    LoanID     INT IDENTITY(1,1) PRIMARY KEY,
    LoanDate   DATE NOT NULL,
    DueDate    DATE NOT NULL,
    ReturnDate DATE,
    BookID     INT NOT NULL,
    MemberID   INT NOT NULL,
    StaffID    INT NOT NULL
);
GO
WITH Numbers AS (
    SELECT TOP 100000 CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO LoanLarge (LoanDate, DueDate, ReturnDate, BookID, MemberID, StaffID)
SELECT DATEADD(DAY, n % 700, '2024-10-01'),
       DATEADD(DAY, n % 700 + 14, '2024-10-01'),
       DATEADD(DAY, n % 700 + 14 + n % 5, '2024-10-01'),
       n % 25 + 1,
       n % 5000 + 1,
       n % 6 + 1
FROM Numbers;
GO

--- TESTS
USE LibraryDB;
GO
SET STATISTICS IO ON;
GO

PRINT '=== PLAN 1: lookup by member, BEFORE the index ===';
SELECT LoanID, LoanDate, DueDate, ReturnDate FROM LoanLarge WHERE MemberID = 1234;
GO

CREATE NONCLUSTERED INDEX IX_LoanLarge_MemberID ON LoanLarge (MemberID);
GO

PRINT '=== PLAN 2: same lookup, AFTER the index ===';
SELECT LoanID, LoanDate, DueDate, ReturnDate FROM LoanLarge WHERE MemberID = 1234;
GO

PRINT '=== PLAN 3: join and aggregation ===';
SELECT b.Title, COUNT(*) AS TimesBorrowed
FROM LoanLarge ll
JOIN Book b ON ll.BookID = b.BookID
GROUP BY b.Title
ORDER BY TimesBorrowed DESC;
GO

PRINT '=== OPTIMISATION 1 ORIGINAL: functions on the date column, no date index ===';
SELECT COUNT(*) FROM LoanLarge WHERE YEAR(LoanDate) = 2025 AND MONTH(LoanDate) = 3;
GO

CREATE NONCLUSTERED INDEX IX_LoanLarge_LoanDate ON LoanLarge (LoanDate);
GO

PRINT '=== OPTIMISATION 1 ORIGINAL AGAIN: index exists but is still scanned ===';
SELECT COUNT(*) FROM LoanLarge WHERE YEAR(LoanDate) = 2025 AND MONTH(LoanDate) = 3;
GO

PRINT '=== OPTIMISATION 1 OPTIMISED: date range ===';
SELECT COUNT(*) FROM LoanLarge WHERE LoanDate >= '2025-03-01' AND LoanDate < '2025-04-01';
GO

PRINT '=== OPTIMISATION 2 ORIGINAL: SELECT * ===';
SELECT * FROM LoanLarge WHERE MemberID = 1234;
GO

CREATE NONCLUSTERED INDEX IX_LoanLarge_MemberID_Cover
ON LoanLarge (MemberID) INCLUDE (LoanDate, DueDate, ReturnDate);
GO

PRINT '=== OPTIMISATION 2 OPTIMISED: only the needed columns, covering index ===';
SELECT LoanDate, DueDate, ReturnDate FROM LoanLarge WHERE MemberID = 1234;
GO

SET STATISTICS IO OFF;
GO

-- ===== 9. QUERY OPTIMISATION =====
-- OPTIMISATION 1: a function on a column stops SQL Server from using an index seek
-- Original (a function is applied to LoanDate, so every row must be checked)
SELECT COUNT(*) FROM LoanLarge
WHERE YEAR(LoanDate) = 2025 AND MONTH(LoanDate) = 3;
GO

-- Optimised: a plain date range lets SQL Server seek straight to March 2025
SELECT COUNT(*) FROM LoanLarge
WHERE LoanDate >= '2025-03-01' AND LoanDate < '2025-04-01';
GO

-- OPTIMISATION 2: SELECT * forces a key lookup for every row found
-- Original (the index only holds MemberID, so each row needs a lookup for the other columns)
SELECT * FROM LoanLarge WHERE MemberID = 1234;
GO

-- Optimised: ask only for the needed columns, so the index alone answers the query
SELECT LoanDate, DueDate, ReturnDate FROM LoanLarge WHERE MemberID = 1234;
GO

SET STATISTICS IO OFF;
GO

---TRANSACTIONS
---COMMIT: return a late book and pay the fine at the desk (both steps succeed together)
BEGIN TRANSACTION;
    EXEC usp_ReturnBook @LoanID = 58;
    UPDATE Fine SET PaymentDate = CAST(GETDATE() AS DATE) WHERE LoanID = 58;
COMMIT TRANSACTION;
SELECT * FROM Fine WHERE LoanID = 58;

---ROLLBACK: issue a book, then cancel before saving
BEGIN TRANSACTION;
    EXEC usp_IssueBook @BookID = 1, @MemberID = 5, @StaffID = 2;
    SELECT Title, CopiesAvailable AS CopiesInsideTransaction FROM Book WHERE BookID = 1;
ROLLBACK TRANSACTION;
SELECT Title, CopiesAvailable AS CopiesAfterRollback FROM Book WHERE BookID = 1;
GO

---concurrency (dirty read)

-- SESSION 1 (window 1): change a value but do NOT commit
BEGIN TRANSACTION;
UPDATE Book SET CopiesAvailable = CopiesAvailable - 1 WHERE BookID = 13;

-- SESSION 2 (window 2): the problem, a dirty read
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Title, CopiesAvailable FROM Book WHERE BookID = 13;   -- shows 4, a value that is not saved yet

-- SESSION 1: cancel the change
ROLLBACK TRANSACTION;

-- SESSION 2: read again
SELECT Title, CopiesAvailable FROM Book WHERE BookID = 13;   -- back to 5, so the 4 never really existed

-- THE FIX: READ COMMITTED
-- SESSION 1: change the value again, still not committed
BEGIN TRANSACTION;
UPDATE Book SET CopiesAvailable = CopiesAvailable - 1 WHERE BookID = 13;
SELECT resource_type, request_mode, request_status
FROM sys.dm_tran_locks WHERE request_session_id = @@SPID;    -- shows the exclusive (X) lock

-- SESSION 2: this now WAITS instead of reading the unsaved value
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Title, CopiesAvailable FROM Book WHERE BookID = 13;

-- SESSION 1: release the lock; session 2 now finishes and shows 5
ROLLBACK TRANSACTION;