# Library Management System (ADBMS Project)

## Project Overview

Library Management System is an ADBMS (Advanced Database Management System) project developed in C# using Windows Forms and SQL Server database. The purpose of this project is to manage library operations digitally instead of using manual records. The system helps librarians handle books, members, book issuing, returns, and reports in an easy and organized way.

This project is useful for schools, colleges, and small libraries where book records and member information need to be maintained efficiently.

---

# Technologies Used

* C# (.NET Framework)
* Windows Forms (WinForms)
* SQL Server
* ADO.NET / Entity Framework
* Visual Studio

---

# Main Modules

## 1. Login Module

**File:** `LoginForm.cs`

This module is used for user authentication. Only authorized users can access the system.

### Features

* Username and password login
* Validation for incorrect credentials
* Secure access to dashboard

---

## 2. Dashboard Module

**File:** `DashBoard.cs`

The dashboard acts as the main control panel of the application.

### Features

* Navigation to all modules
* Quick access buttons
* User-friendly interface

---

## 3. Book Management Module

**File:** `BookForm.cs`

This module manages all book-related operations.

### Features

* Add new books
* Update existing books
* Delete books
* View all books
* Search books

### Stored Information

* Book ID
* Title
* Author
* Category
* Quantity
* Publisher

---

## 4. Member Management Module

**File:** `Member.cs`

This module stores and manages member details.

### Features

* Add members
* Update member records
* Delete members
* View member list

### Stored Information

* Member ID
* Name
* Contact Number
* Address
* Email

---

## 5. Issue Book Module

**File:** `IssueBook.cs`

This module is responsible for issuing books to library members.

### Features

* Issue books to members
* Save issue date
* Check available books
* Maintain issue records

---

## 6. Return Book Module

**File:** `ReturnBook.cs`

This module handles the returning process of books.

### Features

* Return issued books
* Update book quantity
* Store return records
* Manage return dates

---

## 7. Report Module

**File:** `Report.cs`

This module generates reports related to books and members.

### Features

* View issued books report
* View returned books report
* Display member details
* Display book details

---

# ADBMS Concepts Used

This project is based on Advanced Database Management System concepts.

### Concepts Implemented

* Relational Database Design
* Primary Keys and Foreign Keys
* CRUD Operations
* Stored Procedures
* SQL Queries
* Data Validation
* Normalization
* Entity Relationships
* Record Searching and Filtering
* Database Connectivity using ADO.NET

---

# Database

**Database File:** `Librarydb.sql`

The SQL file contains:

* Database creation queries
* Table creation scripts
* Relationships between tables
* Sample structure for library records

### Main Tables

* Books
* Members
* IssueBooks
* ReturnBooks
* Login

---

# Database Connection

**File:** `DBAccess.cs`

This class is used for handling database operations.

### Responsibilities

* SQL Server connection
* Executing queries
* Fetching records
* Inserting and updating data

---

# Project Workflow

1. User logs into the system.
2. Dashboard opens after successful login.
3. Librarian can manage books and members.
4. Books can be issued to members.
5. Returned books are updated in the system.
6. Reports can be generated anytime.

---

# Advantages of the System

* Reduces manual work
* Fast data searching
* Easy record management
* Improves accuracy
* Saves time
* Organized library operations

---

# How to Run the Project

1. Open the solution file in Visual Studio.
2. Restore NuGet packages if required.
3. Create the database using `Librarydb.sql` in SQL Server.
4. Update the connection string if needed.
5. Build and run the project.

---

# Future Improvements

* Fine calculation for late returns
* Barcode integration
* Online book reservation
* Admin and user roles
* Email notifications
* Cloud database support

---

# Conclusion

Library Management System is a simple and effective application for managing library records digitally. It provides all basic functionalities required in a library such as managing books, handling members, issuing books, returning books, and generating reports. The system improves efficiency and reduces the chances of errors in record management.
