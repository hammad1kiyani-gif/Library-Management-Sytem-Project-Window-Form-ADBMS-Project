create database LibraryManagementDB
use LibraryManagementDB
--table 1 userlogin

create table UserLogin
(
UserID int identity(1,1) primary key,
UserName varchar(50) not null unique,
Password varchar(100) not null,
LoginTime datetime,
LogoutTime datetime
)

--table 2 books

create table Books
(
BookID int identity(1,1) primary key,
Title varchar(200) not null,
BookName varchar(200) not null,
Author varchar(100) not null,
Quantity int not null check(Quantity >= 0)
)

--table 3 members

create table Members
(
MemberID int identity(1,1) primary key,
Name varchar(100) not null,
Gmail varchar(150) not null unique,
PhoneNo varchar(20) not null
)

--table 4 issuedbooks

create table IssuedBooks
(
IssueID int identity(1,1) primary key,
MemberID int not null,
BookID int not null,
IssueDate datetime not null default getdate(),
DueDate datetime not null,
Status varchar(20) not null default 'Issued'
check(Status in ('Issued','Returned','Overdue')),
foreign key(MemberID) references Members(MemberID),
foreign key(BookID) references Books(BookID)
)

--table 5 returnbook

create table ReturnBook
(
ReturnID int identity(1,1) primary key,
IssueID int not null unique,
MemberID int not null,
BookID int not null,
ReturnDate datetime not null default getdate(),
Fine decimal(10,2) not null default 0.00 check(Fine >= 0),
Status varchar(20) not null default 'Returned'
check(Status in ('Returned','Lost')),
foreign key(IssueID) references IssuedBooks(IssueID),
foreign key(MemberID) references Members(MemberID),
foreign key(BookID) references Books(BookID)
)

--table 6 activitylog (for dashboard recent activity)
-- this table stores every issue and return action automatically
-- BookTitle | Member | Action | Date

create table ActivityLog
(
ActivityID int identity(1,1) primary key,
BookTitle varchar(200) not null,
MemberName varchar(100) not null,
Action varchar(20) not null check(Action in ('Issued','Returned')),
ActivityDate datetime not null default getdate()
)


-- stored procedures

-- login

create procedure sp_LoginUser
@UserName varchar(50),
@Password varchar(100)
as
begin
	select UserID, UserName from UserLogin
	where UserName = @UserName and Password = @Password

	if @@ROWCOUNT > 0
	begin
		update UserLogin set LoginTime = getdate()
		where UserName = @UserName
	end
end
go

-- logout

create procedure sp_LogoutUser
@UserName varchar(50)
as
begin
	update UserLogin set LogoutTime = getdate()
	where UserName = @UserName
end
go

-- add book

create procedure sp_AddBook
@Title varchar(200),
@BookName varchar(200),
@Author varchar(100),
@Quantity int
as
begin
	insert into Books(Title, BookName, Author, Quantity)
	values(@Title, @BookName, @Author, @Quantity)
end
go

-- update book

create procedure sp_UpdateBook
@BookID int,
@Title varchar(200),
@BookName varchar(200),
@Author varchar(100),
@Quantity int
as
begin
	update Books
	set Title = @Title, BookName = @BookName,
	Author = @Author, Quantity = @Quantity
	where BookID = @BookID
end
go

-- delete book

create procedure sp_DeleteBook
@BookID int
as
begin
	if exists(select 1 from IssuedBooks where BookID = @BookID and Status = 'Issued')
	begin
		raiserror('Cannot delete book it is currently issued', 16, 1)
		return
	end
	delete from Books where BookID = @BookID
end
go

-- view all books

create procedure sp_GetAllBooks
as
begin
	select BookID, Title, BookName, Author, Quantity from Books
end
go

-- add member

create procedure sp_AddMember
@Name varchar(100),
@Gmail varchar(150),
@PhoneNo varchar(20)
as
begin
	insert into Members(Name, Gmail, PhoneNo)
	values(@Name, @Gmail, @PhoneNo)
end
go

-- update member

create procedure sp_UpdateMember
@MemberID int,
@Name varchar(100),
@Gmail varchar(150),
@PhoneNo varchar(20)
as
begin
	update Members
	set Name = @Name, Gmail = @Gmail, PhoneNo = @PhoneNo
	where MemberID = @MemberID
end
go

-- delete member

create procedure sp_DeleteMember
@MemberID int
as
begin
	if exists(select 1 from IssuedBooks where MemberID = @MemberID and Status = 'Issued')
	begin
		raiserror('Cannot delete member has books that are not returned', 16, 1)
		return
	end
	delete from Members where MemberID = @MemberID
end
go

-- view all members

create procedure sp_GetAllMembers
as
begin
	select MemberID, Name, Gmail, PhoneNo from Members
end
go

-- issue book

create procedure sp_IssueBook
@MemberID int,
@BookID int,
@DueDate datetime
as
begin
	if not exists(select 1 from Books where BookID = @BookID and Quantity > 0)
	begin
		raiserror('Book is not available', 16, 1)
		return
	end
	insert into IssuedBooks(MemberID, BookID, IssueDate, DueDate, Status)
	values(@MemberID, @BookID, getdate(), @DueDate, 'Issued')
end
go

-- view issued books

create procedure sp_GetIssuedBooks
as
begin
	select ib.IssueID, m.MemberID, m.Name as MemberName,
	b.Title as BookName, ib.DueDate, ib.Status
	from IssuedBooks ib
	join Members m on ib.MemberID = m.MemberID
	join Books b on ib.BookID = b.BookID
	where ib.Status = 'Issued'
end
go

-- return book

create procedure sp_ReturnBook
@IssueID int,
@Fine decimal(10,2)
as
begin
	if not exists(select 1 from IssuedBooks where IssueID = @IssueID and Status = 'Issued')
	begin
		raiserror('No active issue record found', 16, 1)
		return
	end

	declare @MemberID int, @BookID int
	select @MemberID = MemberID, @BookID = BookID
	from IssuedBooks where IssueID = @IssueID

	insert into ReturnBook(IssueID, MemberID, BookID, ReturnDate, Fine, Status)
	values(@IssueID, @MemberID, @BookID, getdate(), @Fine, 'Returned')

	update IssuedBooks set Status = 'Returned' where IssueID = @IssueID
end
go

-- search issued books by member (for return book form)

create procedure sp_SearchIssuedByMember
@MemberID int
as
begin
	select ib.IssueID, m.Name as MemberName,
	b.Title as BookName, ib.DueDate,
	dbo.fn_CalculateFine(ib.IssueID) as Fine
	from IssuedBooks ib
	join Members m on ib.MemberID = m.MemberID
	join Books b on ib.BookID = b.BookID
	where ib.MemberID = @MemberID and ib.Status = 'Issued'
end
go

-- view returned books

create procedure sp_GetReturnedBooks
as
begin
	select rb.ReturnID, m.Name as MemberName,
	b.Title as BookName, rb.Fine,
	ib.DueDate, rb.ReturnDate, rb.Status
	from ReturnBook rb
	join Members m on rb.MemberID = m.MemberID
	join Books b on rb.BookID = b.BookID
	join IssuedBooks ib on rb.IssueID = ib.IssueID
end
go

-- get recent activity for dashboard
-- shows last 20 actions (issued or returned)

create procedure sp_GetRecentActivity
as
begin
	select top 20 BookTitle, MemberName, Action, ActivityDate
	from ActivityLog
	order by ActivityDate desc
end
go


-- functions

-- calculate fine rs.10 per day

create function dbo.fn_CalculateFine(@IssueID int)
returns decimal(10,2)
as
begin
	declare @DueDate datetime
	select @DueDate = DueDate from IssuedBooks
	where IssueID = @IssueID and Status = 'Issued'

	if @DueDate is null return 0.00

	return case
		when getdate() > @DueDate
		then cast(datediff(day, @DueDate, getdate()) * 10.00 as decimal(10,2))
		else 0.00
	end
end
go

-- count how many books a member currently has

create function dbo.fn_MemberIssuedCount(@MemberID int)
returns int
as
begin
	declare @Count int
	select @Count = count(*) from IssuedBooks
	where MemberID = @MemberID and Status = 'Issued'
	return isnull(@Count, 0)
end
go

-- check if book is available

create function dbo.fn_IsBookAvailable(@BookID int)
returns bit
as
begin
	declare @Qty int
	select @Qty = Quantity from Books where BookID = @BookID
	if isnull(@Qty, 0) > 0 return 1
	return 0
end
go


-- triggers

-- decrease quantity when book issued
-- also logs to activitylog for dashboard

create trigger trg_AfterIssue
on IssuedBooks
after insert
as
begin
	update Books set Quantity = Quantity - 1
	from Books b inner join inserted i on b.BookID = i.BookID

	insert into ActivityLog(BookTitle, MemberName, Action, ActivityDate)
	select b.Title, m.Name, 'Issued', getdate()
	from inserted i
	join Books b on i.BookID = b.BookID
	join Members m on i.MemberID = m.MemberID
end
go

-- increase quantity when book returned
-- also logs to activitylog for dashboard

create trigger trg_AfterReturn
on ReturnBook
after insert
as
begin
	update Books set Quantity = Quantity + 1
	from Books b inner join inserted i on b.BookID = i.BookID

	insert into ActivityLog(BookTitle, MemberName, Action, ActivityDate)
	select b.Title, m.Name, 'Returned', getdate()
	from inserted i
	join Books b on i.BookID = b.BookID
	join Members m on i.MemberID = m.MemberID
end
go

-- block issue if book out of stock

create trigger trg_PreventZeroIssue
on IssuedBooks
instead of insert
as
begin
	if exists(
		select 1 from Books b
		inner join inserted i on b.BookID = i.BookID
		where b.Quantity <= 0
	)
	begin
		raiserror('Book is out of stock cannot issue', 16, 1)
		rollback
		return
	end
	insert into IssuedBooks(MemberID, BookID, IssueDate, DueDate, Status)
	select MemberID, BookID, IssueDate, DueDate, Status from inserted
end
go

-- block delete member if they have issued books

create trigger trg_PreventMemberDelete
on Members
instead of delete
as
begin
	if exists(
		select 1 from IssuedBooks ib
		inner join deleted d on ib.MemberID = d.MemberID
		where ib.Status = 'Issued'
	)
	begin
		raiserror('Cannot delete member they have books not returned', 16, 1)
		rollback
	end
	else
		delete from Members where MemberID in (select MemberID from deleted)
end
go

-- auto mark overdue

create trigger trg_MarkOverdue
on IssuedBooks
after update
as
begin
	update IssuedBooks set Status = 'Overdue'
	where Status = 'Issued' and DueDate < getdate()
end
go


-- cursor for overdue books report

create procedure sp_OverdueBooksReport
as
begin
	declare @IssueID int
	declare @MemberName varchar(100)
	declare @BookTitle varchar(200)
	declare @DueDate datetime
	declare @Fine decimal(10,2)

	declare cur_Overdue cursor for
		select ib.IssueID, m.Name, b.Title, ib.DueDate
		from IssuedBooks ib
		join Members m on ib.MemberID = m.MemberID
		join Books b on ib.BookID = b.BookID
		where ib.Status = 'Issued' and ib.DueDate < getdate()
		order by ib.DueDate

	open cur_Overdue
	fetch next from cur_Overdue into @IssueID, @MemberName, @BookTitle, @DueDate

	while @@FETCH_STATUS = 0
	begin
		set @Fine = dbo.fn_CalculateFine(@IssueID)

		update IssuedBooks set Status = 'Overdue' where IssueID = @IssueID

		print 'Member: ' + @MemberName +
		' | Book: ' + @BookTitle +
		' | Due Date: ' + convert(varchar, @DueDate, 103) +
		' | Fine: Rs.' + cast(@Fine as varchar)

		fetch next from cur_Overdue into @IssueID, @MemberName, @BookTitle, @DueDate
	end

	close cur_Overdue
	deallocate cur_Overdue
end
go

-- check all tables

////////////////////////////////////////

select name as TableName, create_date, modify_date
from sys.tables
order by create_date


-- check all stored procedures

select name as ProcedureName, create_date, modify_date
from sys.procedures
order by create_date


-- check all functions

select name as FunctionName, type_desc, create_date, modify_date
from sys.objects
where type in ('FN', 'IF', 'TF')
order by create_date


-- check all triggers

select name as TriggerName, parent_id,
object_name(parent_id) as OnTable,
create_date, modify_date
from sys.triggers
order by create_date


-- check all at once (combined view)

select name, type_desc, create_date
from sys.objects
where type in ('U','P','FN','TR')
order by type_desc, name


-- to see columns of a specific table

exec sp_help 'UserLogin'
exec sp_help 'Books'
exec sp_help 'Members'
exec sp_help 'IssuedBooks'
exec sp_help 'ReturnBook'
exec sp_help 'ActivityLog'


-- to see the code inside a procedure

exec sp_helptext 'sp_LoginUser'
exec sp_helptext 'sp_IssueBook'
exec sp_helptext 'sp_ReturnBook'


-- to see the code inside a function

exec sp_helptext 'fn_CalculateFine'
exec sp_helptext 'fn_MemberIssuedCount'
exec sp_helptext 'fn_IsBookAvailable'


-- to see the code inside a trigger

exec sp_helptext 'trg_AfterIssue'
exec sp_helptext 'trg_AfterReturn'


-- test login procedure

exec sp_LoginUser 'admin', 'Admin@123'


-- test function manually

select dbo.fn_IsBookAvailable(1) as IsAvailable
select dbo.fn_MemberIssuedCount(1) as IssuedCount
select dbo.fn_CalculateFine(1) as Fine


-- test recent activity

exec sp_GetRecentActivity


-- test overdue cursor

exec sp_OverdueBooksReport
create procedure sp_AutoAssignBook
@MemberID int
as
begin
	declare @BookID int
	declare @BookTitle varchar(200)
 
	-
	select top 1 @BookID = BookID, @BookTitle = Title
	from Books
	where Quantity > 0
	order by BookID
 
	-- if no book is available then stop
	if @BookID is null
	begin
		print 'No book available to assign'
		return
	end
	create procedure sp_AutoAssignBook
@MemberID int
as
begin
	declare @BookID int
	declare @BookTitle varchar(200)
 
	-- find first available book that has quantity
	select top 1 @BookID = BookID, @BookTitle = Title
	from Books
	where Quantity > 0
	order by BookID
 
	-- if no book is available then stop
	if @BookID is null
	begin
		print 'No book available to assign'
		return
	end
 
	-- issue the book to new member
	insert into IssuedBooks(MemberID, BookID, IssueDate, DueDate, Status)
	values(@MemberID, @BookID, getdate(), dateadd(day, 14, getdate()), 'Issued')
 
	print 'Book auto assigned: ' + @BookTitle
end
go
 
 
-- step 2: new trigger on Members table
-- fires automatically after any new member is added
-- calls sp_AutoAssignBook with the new member id
 
create trigger trg_AutoAssignBookOnNewMember
on Members
after insert
as
begin
	declare @NewMemberID int
 
	select @NewMemberID = MemberID from inserted
 
	exec sp_AutoAssignBook @NewMemberID
end
go
 
 
-- step 3: new procedure to check
-- which book was auto assigned to member
-- call this after adding member to show result
 
create procedure sp_GetAutoAssignedBook
@MemberID int
as
begin
	select top 1
	ib.IssueID,
	m.Name as MemberName,
	b.Title as BookTitle,
	b.Author,
	ib.IssueDate,
	ib.DueDate,
	ib.Status
	from IssuedBooks ib
	join Members m on ib.MemberID = m.MemberID
	join Books b on ib.BookID = b.BookID
	where ib.MemberID = @MemberID
	order by ib.IssueID desc
end
go