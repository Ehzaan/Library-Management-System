-- =============================================================================
--                        LIBRARY MANAGEMENT SYSTEM
-- =============================================================================


-- =============================================================================
-- SECTION 1: TABLE CREATION
-- =============================================================================

-- Creating Table: Return_Status
DROP TABLE IF EXISTS Return_Status;
CREATE TABLE Return_Status (
    return_id        VARCHAR(5)  PRIMARY KEY,
    issued_id        VARCHAR(5),
    return_book_name VARCHAR(50),
    return_date      DATE,
    return_book_isbn VARCHAR(50)
);


-- Creating Table: Members
DROP TABLE IF EXISTS Members;
CREATE TABLE members (
    member_id      VARCHAR(4),
    member_name    VARCHAR(25),
    member_address VARCHAR(50),
    reg_date       DATE
);


-- Creating Table: Issued_Status
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status (
    issued_id        VARCHAR(5)  PRIMARY KEY,
    issued_member_id VARCHAR(4),
    issued_book_name VARCHAR(50),
    issued_date      DATE,
    issued_book_isbn VARCHAR(50),
    issued_emp_id    VARCHAR(4)
);


-- Creating Table: Employees
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id    VARCHAR(4)  PRIMARY KEY,
    emp_name  VARCHAR(20),
    position  VARCHAR(20),
    salary    INT(20),
    branch_id VARCHAR(4)
);


-- Creating Table: Branch
DROP TABLE IF EXISTS branch;
CREATE TABLE branch (
    branch_id      VARCHAR(4)  PRIMARY KEY,
    manager_id     VARCHAR(4),
    branch_address VARCHAR(50),
    contact        VARCHAR(15)
);


-- Creating Table: Books
DROP TABLE IF EXISTS books;
CREATE TABLE books (
    isbn         VARCHAR(20) PRIMARY KEY,
    book_title   VARCHAR(50),
    category     VARCHAR(20),
    rental_price FLOAT,
    `status`     VARCHAR(10),
    author       VARCHAR(50),
    publisher    VARCHAR(50)
);


-- =============================================================================
-- SECTION 2: FOREIGN KEY CONSTRAINTS
-- =============================================================================

-- issued_status → employees
ALTER TABLE issued_status
ADD CONSTRAINT fk_emp_id
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

-- issued_status → books
ALTER TABLE issued_status
ADD CONSTRAINT fk_book_isbn
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

-- issued_status → members
ALTER TABLE issued_status
ADD CONSTRAINT fk_member_id
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

-- employees → branch
ALTER TABLE employees
ADD CONSTRAINT fk_branch_id
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

-- return_status → issued_status
ALTER TABLE return_status
ADD CONSTRAINT fk_issued_id
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);


-- =============================================================================
-- SECTION 3: BASIC SQL TASKS
-- =============================================================================

-- Task 1: Create a New Book Record
INSERT INTO books (isbn, book_title, category, rental_price, `status`, author, publisher)
VALUES (
    '978-1-60129-456-2',
    'To Kill a Mockingbird',
    'Classic',
    6.00,
    'yes',
    'Harper Lee',
    'J.B. Lippincott & Co.'
);


-- Task 2: Update an Existing Member's Address
UPDATE members
SET    member_address = '399 Devil St'
WHERE  member_id = 'C101';


-- Task 3: Delete a Record from issued_status
DELETE FROM issued_status
WHERE issued_id = 'IS121';


-- Task 4: Select All Books Issued by a Specific Employee (emp_id = 'E101')
SELECT *
FROM   issued_status
WHERE  issued_emp_id = 'E101';


-- Task 5: List Members Who Have Issued More Than One Book
WITH CTE_1 AS (
    SELECT issued_member_id,
           COUNT(issued_id) AS Total_Issues
    FROM   issued_status
    GROUP  BY issued_member_id
)
SELECT *
FROM   CTE_1
WHERE  Total_Issues > 1;


-- Task 6: Summary Table — Each Book and Its Total Issue Count
SELECT
    BK.book_title,
    COUNT(Isu.issued_id) AS Total_Issues
FROM  issued_status AS Isu
LEFT  JOIN books AS BK
    ON Isu.issued_book_isbn = BK.isbn
GROUP BY BK.book_title;


-- Task 7: Retrieve All Books in a Specific Category
SELECT
    category,
    COUNT(isbn) AS Total_Books
FROM  books
GROUP BY category;


-- Task 8: Find Total Rental Income by Category
SELECT
    category,
    ROUND(SUM(rental_price)) AS Rent_Price
FROM  books
GROUP BY category;


-- Task 9: List Members Who Registered in the Last 180 Days
SELECT *
FROM   members
WHERE  (CURRENT_DATE() - reg_date) <= 180;


-- Task 10: List Employees with Their Branch Manager's Name and Branch Details
SELECT
    Emp1.emp_name,
    Emp2.emp_name    AS Manager_Name,
    BR.branch_address
FROM       employees AS Emp1
LEFT JOIN  branch    AS BR
    ON  Emp1.branch_id = BR.branch_id
LEFT JOIN  employees AS Emp2
    ON  BR.manager_id = Emp2.emp_id;


-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold
WITH CTE_2 AS (
    SELECT
        book_title,
        ROUND(SUM(rental_price)) AS Rent_Price
    FROM  books
    GROUP BY book_title
)
SELECT *
FROM   CTE_2
HAVING Rent_Price > 7;


-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT
    books.book_title,
    issued_status.issued_id,
    return_status.issued_id AS Return_id
FROM       books
LEFT JOIN  issued_status
    ON  books.isbn = issued_status.issued_book_isbn
LEFT JOIN  return_status
    ON  issued_status.issued_id = return_status.issued_id
WHERE  return_status.issued_id  IS NULL
AND    issued_status.issued_id  IS NOT NULL;


-- =============================================================================
-- SECTION 4: DATA SETUP FOR ADVANCED TASKS
-- =============================================================================

-- Insert Sample Issued Records
INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES
    ('IS151', 'C118', 'The Catcher in the Rye', CURRENT_DATE() - INTERVAL 24 DAY, '978-0-553-29698-2', 'E108'),
    ('IS152', 'C119', 'The Catcher in the Rye', CURRENT_DATE() - INTERVAL 13 DAY, '978-0-553-29698-2', 'E109'),
    ('IS153', 'C106', 'Pride and Prejudice',     CURRENT_DATE() - INTERVAL  7 DAY, '978-0-14-143951-8', 'E107'),
    ('IS154', 'C105', 'The Road',                CURRENT_DATE() - INTERVAL 32 DAY, '978-0-375-50167-0', 'E101');

-- Add Book_quality Column to return_status
ALTER TABLE return_status
ADD COLUMN Book_quality VARCHAR(20) DEFAULT 'Good';

-- Mark Specific Returns as Damaged
UPDATE return_status
SET    Book_quality = 'Damaged'
WHERE  issued_id IN ('IS112', 'IS117', 'IS118');


-- =============================================================================
-- SECTION 5: ADVANCED SQL QUERIES
-- =============================================================================

-- Task 13: Identify Members with Overdue Books (30-day return period)
-- Displays member_id, member_name, book title, issue date, and days overdue
SELECT
    Mem.member_id,
    Mem.member_name,
    Isu.issued_book_name,
    Isu.issued_date,
    RS.return_date
FROM       members       AS Mem
LEFT JOIN  issued_status AS Isu
    ON  Mem.member_id = Isu.issued_member_id
LEFT JOIN  return_status AS RS
    ON  Isu.issued_id = RS.issued_id
WHERE  RS.return_date IS NULL
AND    (CURRENT_DATE() - Isu.issued_date) > 30;


-- Task 14: Update Book Status on Return (Trigger)
-- Automatically sets book status to 'Yes' when a return entry is inserted
DELIMITER $$
CREATE TRIGGER book_return
    AFTER INSERT ON return_status
    FOR EACH ROW
BEGIN
    UPDATE books
    SET    `status` = 'Yes'
    WHERE  book_title = (
        SELECT issued_book_name
        FROM   issued_status
        WHERE  issued_id = NEW.issued_id
    );
END $$
DELIMITER ;

-- Test: Insert a Return Record
INSERT INTO return_status (return_id, issued_id, return_book_name, return_date, return_book_isbn, Book_quality)
VALUES ('RS119', 'IS135', NULL, '2026-05-18', NULL, 'Good');


-- Task 15: Branch Performance Report
-- Shows total books issued, books returned, and total rental revenue per branch
SELECT
    BR.branch_address,
    COUNT(Isu.issued_id)  AS Total_Issues,
    COUNT(RS.return_id)   AS Total_Returns,
    SUM(BK.rental_price)  AS Total_Rent
FROM       branch        AS BR
LEFT JOIN  employees     AS Emp
    ON  BR.branch_id = Emp.branch_id
LEFT JOIN  issued_status AS Isu
    ON  Isu.issued_emp_id = Emp.emp_id
LEFT JOIN  books         AS BK
    ON  BK.isbn = Isu.issued_book_isbn
LEFT JOIN  return_status AS RS
    ON  Isu.issued_id = RS.issued_id
GROUP BY BR.branch_address;


-- Task 16: Active Members — Members Who Issued a Book in the Last 2 Months
SELECT Mem.member_name
FROM       members       AS Mem
LEFT JOIN  issued_status AS Isu
    ON  Mem.member_id = Isu.issued_member_id
WHERE  CURRENT_DATE() - INTERVAL 60 DAY <= issued_date;


-- Task 17: Top 3 Employees Who Processed the Most Book Issues
SELECT
    Emp.emp_name,
    COUNT(DISTINCT Isu.issued_id) AS Total_Issues,
    MAX(Emp.branch_id)            AS Branch
FROM       employees     AS Emp
LEFT JOIN  issued_status AS Isu
    ON  Emp.emp_id = Isu.issued_emp_id
GROUP BY  Emp.emp_name
ORDER BY  COUNT(Isu.issued_id) DESC
LIMIT 3;


-- Task 18: Identify Members Issuing High-Risk (Damaged) Books More Than Twice
SELECT
    Mem.member_name,
    Isu.issued_book_name,
    COUNT(Isu.issued_id) AS Damage_Count
FROM       issued_status AS Isu
LEFT JOIN  books         AS BK
    ON  BK.isbn = Isu.issued_book_isbn
LEFT JOIN  members       AS Mem
    ON  Isu.issued_member_id = Mem.member_id
LEFT JOIN  return_status AS RK
    ON  RK.issued_id = Isu.issued_id
WHERE  RK.Book_quality = 'Damaged'
GROUP BY  Mem.member_name, Isu.issued_book_name
HAVING COUNT(Isu.issued_id) > 2;


-- =============================================================================
-- SECTION 6: STORED PROCEDURE
-- =============================================================================

-- Task 19: Stored Procedure — Book Issue Management
-- Checks if a book is available (status = 'Yes'):
--   • If available  → issues the book and updates status to 'No'
--   • If unavailable → returns an error message

SELECT * FROM books;

DELIMITER $$
CREATE PROCEDURE Book_Issue (
    p_issued_id        VARCHAR(5),
    p_issued_member_id VARCHAR(4),
    p_book_id          VARCHAR(50)
)
BEGIN
    IF (SELECT `status` FROM books WHERE isbn = p_book_id) = 'Yes' THEN

        UPDATE books
        SET    `status` = 'No'
        WHERE  isbn = p_book_id;

        INSERT INTO issued_status (
            issued_id,
            issued_member_id,
            issued_book_name,
            issued_date,
            issued_book_isbn,
            issued_emp_id
        )
        VALUES (
            p_issued_id,
            p_issued_member_id,
            NULL,
            CURRENT_DATE(),
            p_book_id,
            NULL
        );

    ELSE
        SELECT CONCAT('The book of ID ', p_book_id, ' Is Unavailable') AS Error_Message;

    END IF;
END $$
DELIMITER ;

-- Test: Call the Stored Procedure
CALL Book_Issue('IS155', 'C119', '978-0-330-25864-8');