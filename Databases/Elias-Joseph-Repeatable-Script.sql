-- drop all created entities if they exist

drop table if exists class_session_member_link

drop table if exists class_session

drop table if exists class_instructor_link

drop table if exists class

drop table if exists member_check_in

drop table if exists member

drop table if exists employee

drop table if exists equipment

drop table if exists room

DROP TABLE if exists facility; 

DROP TABLE if exists membership_type; 

DROP TABLE if exists room_type; 

DROP TABLE if exists equipment_type; 

drop FUNCTION if exists membership_count

DROP VIEW IF EXISTS most_profitable_memberships;  

drop PROCEDURE if exists change_membership_type

drop PROCEDURE if exists payment_collected

drop PROCEDURE if exists hire_instructor

drop procedure if exists toggle_needs_maitenence

drop procedure if exists change_employee_position

drop function if exists active_member

drop function if exists count_room_type

-- create a table for equipment type
CREATE TABLE equipment_type(
    equipment_type_ID int identity,
    equipment_type_name varchar(30) not null,
    equipment_type_description varchar(100),
    CONSTRAINT PK_equipment_type Primary Key(equipment_type_ID),
    CONSTRAINT U1_equipment_type Unique(equipment_type_name)
)

-- create a table for room type
CREATE TABLE room_type(
    room_type_ID int identity,
    room_type_name varchar(30) not null,
    room_type_description varchar(100),
    CONSTRAINT PK_room_type PRIMARY KEY(room_type_ID),
    CONSTRAINT U1_room_type UNIQUE(room_type_name)
)

-- create a table for membership type
CREATE TABLE membership_type(
    membership_type_ID int identity,
    membership_type_name varchar(30) not null,
    upfront_cost float not null,
    recurring_cost float not null,
    payment_interval_days int,
    CONSTRAINT PK_membership_type PRIMARY KEY (membership_type_ID),
    CONSTRAINT U1_membership_type UNIQUE(membership_type_name)
)

-- create a table for facilities
CREATE TABLE facility(
    facility_ID int identity,
    facility_address varchar(50) NOT NULL,
    facility_name varchar(30),
    CONSTRAINT PK_facility PRIMARY KEY (facility_ID)
)

-- create a table for rooms
create table room(
    room_ID int identity,
    room_name varchar(30) not null,
    room_description varchar(100),
    size_sqft int not null,
    capacity int not null,
    facility_ID int not null,
    room_type_ID int not null,
    CONSTRAINT PK_room PRIMARY KEY(room_ID),
    CONSTRAINT FK1_room FOREIGN Key (facility_ID) REFERENCES facility(facility_ID),
    CONSTRAINT FK2_room FOREIGN KEY (room_type_ID) REFERENCES room_type(room_type_ID)
)

-- create a table for equipment
create table equipment(
    equipment_id int IDENTITY,
    equipment_name varchar(30) not null,
    equipment_description varchar(100),
    date_aquired datetime,
    cost float,
    out_of_order BIT not null DEFAULT 0,
    room_ID int not null,
    equipment_type_ID int not null,
    CONSTRAINT PK_equipment PRIMARY KEY(equipment_id),
    CONSTRAINT FK1_equipment FOREIGN KEY(room_ID) REFERENCES room(room_ID),
    CONSTRAINT FK2_equipment FOREIGN KEY(equipment_type_ID) REFERENCES equipment_type(equipment_type_ID)
)

-- create a table for employees
CREATE TABLE employee(
    employee_ID int identity,
    employee_first_name varchar(30) not null,
    employee_middle_initial varchar(1),
    employee_last_name varchar(30) not null,
    employee_address varchar(50) not null,
    job_title VARCHAR(30) not null,
    salary float not null,
    facility_ID int,
    CONSTRAINT PK_employee PRIMARY KEY(employee_ID),
    CONSTRAINT FK1_employee FOREIGN KEY(facility_ID) REFERENCES facility(facility_ID)
)

-- create a table for members
CREATE TABLE member(
    member_ID int identity,
    member_first_name varchar(30) not null,
    member_middle_initial varchar(1),
    member_last_name varchar(30) not null,
    member_address varchar(50) not null,
    member_start_date datetime not null default GETDATE(),
    last_payment datetime not null default GETDATE(),
    membership_type_ID int not null,
    private_instructor int,
    CONSTRAINT PK_member PRIMARY KEY(member_ID),
    CONSTRAINT FK1_member FOREIGN KEY(membership_type_ID) REFERENCES membership_type(membership_type_ID),
    CONSTRAINT FK2_member FOREIGN KEY(private_instructor) REFERENCES employee(employee_ID)
)

-- create a table for times members check in to facilities
CREATE table member_check_in(
    member_check_in_ID int identity,
    check_in_date datetime not null DEFAULT GETDATE(),
    member_ID int not null,
    facility_ID int not null,
    CONSTRAINT PK_member_check_in PRIMARY KEY(member_check_in_ID),
    CONSTRAINT FK1_member_check_in FOREIGN KEY(member_ID) REFERENCES member(member_ID),
    CONSTRAINT FK2_member_check_in FOREIGN KEY(facility_ID) REFERENCES facility(facility_ID)
)

-- create a table for classes offered
create table class(
    class_ID int identity,
    class_name varchar(30) not null,
    cost float not null,
    CONSTRAINT PK_class PRIMARY KEY(class_ID)
)

-- create a bridge table liking class and instructor
create table class_instructor_link(
    class_instructor_link_ID int identity,
    class_ID int not null,
    instructor_ID int not null,
    CONSTRAINT PK_class_instructor_link PRIMARY KEY(class_instructor_link_ID),
    CONSTRAINT FK1_class_instructor_link FOREIGN KEY(class_ID) REFERENCES class(class_ID),
    CONSTRAINT FK2_class_instructor_link FOREIGN KEY (instructor_ID) REFERENCES employee(employee_ID)
)

-- create a bridge table linking class and sessions of that class
create table class_session(
    class_session_ID int identity,
    class_session_day varchar(10) not null,
    class_session_time time not null,
    class_session_room int not null,
    class_ID int not null,
    CONSTRAINT PK_class_session PRIMARY KEY(class_session_ID),
    CONSTRAINT U1_class_session UNIQUE(class_session_day, class_session_time, class_session_room),
    CONSTRAINT FK1_class_session FOREIGN KEY(class_session_room) references room(room_ID),
    CONSTRAINT FK2_class_session FOREIGN KEY(class_ID) REFERENCES class(class_ID)
)


-- create a table linking sessions and members attending those sessions
CREATE TABLE class_session_member_link(
    class_session_member_link_ID int IDENTITY,
    class_session_ID int not null,
    member_ID int not null,
    CONSTRAINT PK_class_session_member_link PRIMARY KEY(class_session_member_link_ID),
    CONSTRAINT FK1_class_session_member_link FOREIGN KEY(class_session_ID) REFERENCES class_session(class_session_ID),
    CONSTRAINT FK2_class_session_member_link FOREIGN KEY(member_ID) REFERENCES member(member_ID)
)

GO

-- create a function that counts how many people have each type of membership
CREATE FUNCTION membership_count(@membershipID int)
RETURNS int AS
BEGIN
    DECLARE @returnValue int
    SELECT @returnValue = COUNT(membership_type_ID) from member
    WHERE member.membership_type_ID = @membershipID
    RETURN @returnValue
END
GO

-- create a view that shows how much money is earned from each membership
CREATE VIEW most_profitable_memberships AS (
    SELECT *, dbo.membership_count(membership_type_ID) as membership_count, dbo.membership_count(membership_type_ID) * recurring_cost as total_monthly_income
    from membership_type
)

GO

-- create a procedure to change someones membership
Create PROCEDURE change_membership_type(@memberID int, @new_membership_id int)
AS
BEGIN
    Update member SET membership_type_ID = @new_membership_id, last_payment = GETDATE()
    where member_ID = @memberID
END

GO

-- create a prodecure that resets the timer on someones membership
Create PROCEDURE payment_collected(@memberID int)
AS
BEGIN
    Update member SET last_payment = GETDATE()
    where member_ID = @memberID
END
GO

-- create a procedure that allows a member to hire a private instructor
CREATE Procedure hire_instructor(@memberID int, @instructorID int)
AS
BEGIN
    Update member SET private_instructor = @instructorID
    where member_ID = @memberID
END
go


-- create a procedure to set a machine to need maitenence, or no longer needs maitenence
CREATE Procedure toggle_needs_maitenence(@needs_maitenence bit, @equipment_id int)
AS
BEGIN
    Update equipment SET out_of_order = @needs_maitenence
    where equipment_id = @equipment_id
END
GO

-- create a procedure to change an employees position and salary
CREATE PROCEDURE change_employee_position(@employeeID int, @new_position varchar(30), @new_salary float, @new_facility int)
AS
BEGIN
    UPDATE employee set job_title = @new_position, salary = @new_salary, facility_ID = @new_facility
    WHERE employee_ID = @employeeID
END

--- all people in this database are fake and generated with www.fakeaddressgenerator.com

GO

-- insert some membership types and their costs
Insert into membership_type(membership_type_name, upfront_cost, recurring_cost, payment_interval_days)
values('Basic', 50.00, 20.00, 30),
      ('Premium', 100.00, 40.00, 30),
      ('No Active Membership', 0.00, 0.00, 30)

-- moving forward, all first names, last names, street names, and city names were generated from this txt document:
-- https://gist.github.com/zubietaroberto/b1e14a1f7cc307749d02c99df398c84a
-- most data (other than most of the 'type' tables) are randomly generated

-- insert some generated members
INSERT INTO member(member_first_name, member_middle_initial, member_last_name, member_address, member_start_date, membership_type_ID)
VALUES('Seth', 'K', 'Lang', 'Puerto González MO, 4576 Moorsom Street', GETDATE(), 3),
('Marissa', 'W', 'Turner', 'Wenzhou CT, 1328 Treville Road', GETDATE(), 2),
('William', 'M', 'Wells', 'Concord KY, 8367 Codrington Road', GETDATE(), 3),
('Emma', 'Z', 'White', 'St. Pomeroy MA, 1234 Moorsom Street', GETDATE(), 1),
('Wendy', 'K', 'Michaels', 'Dis AR, 7213 Tirpitz Street', GETDATE(), 3),
('Kimberly', 'O', 'Nathanson', 'New Jamestown MN, 7541 Treville Avenue', GETDATE(), 3),
('Kathleen', 'O', 'Mayfield', 'Tuscany AL, 8131 Hart Road', GETDATE(), 3),
('Amber', 'D', 'Grant', 'Olympia VA, 3584 Cunningham Street', GETDATE(), 1),
('Sibyl', 'W', 'Hawkins', 'St. Pomeroy AL, 4657 Turner Street', GETDATE(), 2),
('Donald', 'O', 'Shannon', 'Nueva Sonora WA, 3266 Hipper Avenue', GETDATE(), 3),
('Tisha', 'A', 'Roberts', 'Xianyang ME, 2732 King Road', GETDATE(), 1),
('Jennifer', 'D', 'Handler', 'New Roanoke MI, 8255 Moorsom Road', GETDATE(), 2),
('Jesse', 'K', 'Ryan', 'St. Yegorov NY, 7274 Durham Street', GETDATE(), 1),
('Teri', 'E', 'Reese', 'Karakosov KY, 1557 Halsey Road', GETDATE(), 2),
('Liam', 'Z', 'Salinger', 'Wang Tong SC, 2163 Perry Road', GETDATE(), 2),
('Alison', 'T', 'Barton', 'Nueva Sonora ME, 1448 Hawke Road', GETDATE(), 1),
('Lucy', 'D', 'Walden', 'Al-Jissa IN, 4548 King Road', GETDATE(), 3),
('Gavin', 'A', 'Samuels', 'Wenzhou KY, 7333 Doria Road', GETDATE(), 2),
('Clyde', 'Y', 'Salinger', 'Al-Matabbah ID, 8383 Laforey Street', GETDATE(), 2),
('Kieran', 'I', 'Edwards', 'New Jerusalem WV, 3754 Essen Avenue', GETDATE(), 1),
('Heidi', 'U', 'McCormick', 'Hope UT, 5258 Hargood Avenue', GETDATE(), 1),
('Bridget', 'F', 'Wade', 'Hope DE, 1643 Crutchley Avenue', GETDATE(), 2),
('Larry', 'B', 'Bergman', 'La Isabela NJ, 8267 Pound Avenue', GETDATE(), 1),
('Felicia', 'R', 'Garland', 'San Fernando WY, 1337 Kountouriotis Avenue', GETDATE(), 1),
('Alan', 'X', 'Barton', 'Nueva Sonora MO, 5352 Crutchley Road', GETDATE(), 2),
('Justin', 'Y', 'Sedgwick', 'Xianyang MO, 4638 Turner Street', GETDATE(), 1),
('Tony', 'J', 'Saxton', 'San Cristóbal CT, 7462 Jellicoe Street', GETDATE(), 1),
('Tony', 'X', 'England', 'San Lucas AR, 5732 Essen Avenue', GETDATE(), 3),
('Donna', 'L', 'Lynch', 'Nueva Sonora OR, 4335 Suffren Road', GETDATE(), 2),
('Marshall', 'T', 'Tanner', 'San Fernando WY, 7324 Kountouriotis Road', GETDATE(), 1),
('Amelia', 'Z', 'Ericson', 'Serendipity AZ, 7855 Crutchley Street', GETDATE(), 3),
('Yvette', 'Y', 'Cavanaugh', 'Al-Jissa ND, 7658 Laforey Road', GETDATE(), 1),
('Pierce', 'Y', 'Buchanan', 'Xianyang AR, 4426 Crutchley Street', GETDATE(), 3),
('Rebecca', 'F', 'Bates', 'Karakosov WA, 7862 Tyler Street', GETDATE(), 3),
('Horace', 'P', 'Baxter', 'San Lucas HI, 4232 Villeneuve Avenue', GETDATE(), 3),
('Olivia', 'W', 'Lowell', 'Salaam ME, 4472 Suffren Street', GETDATE(), 1),
('Jack', 'R', 'Ashton', 'Wang Tong NJ, 5871 Hipper Road', GETDATE(), 1),
('Geoffrey', 'W', 'Hawkins', 'Dis IL, 6288 Suffren Street', GETDATE(), 1),
('Rosemary', 'D', 'Richardson', 'Wenzhou TX, 4688 Hawke Street', GETDATE(), 3),
('Fred', 'M', 'Hargreaves', 'St. Pomeroy WI, 4866 Laforey Street', GETDATE(), 2),
('Victoria', 'P', 'Swanson', 'Anchor ME, 1147 Halsey Avenue', GETDATE(), 3),
('Karla', 'X', 'Goldberg', 'Nueva Cádiz NH, 7214 King Street', GETDATE(), 1),
('Dominic', 'N', 'Milton', 'Al-Jissa IN, 3514 Kountouriotis Road', GETDATE(), 2),
('Jasmine', 'P', 'McCoy', 'Concord FL, 8723 Potemkin Avenue', GETDATE(), 1),
('Dolores', 'Y', 'Poole', 'Las Veredas CO, 7222 Milne Street', GETDATE(), 2),
('Deanna', 'B', 'Baker', 'Nozomi AK, 4542 Durham Avenue', GETDATE(), 2),
('Gwen', 'S', 'Allenby', 'Salaam NM, 4841 Suffren Street', GETDATE(), 2),
('Harriet', 'J', 'Wells', 'La Isabela AZ, 7825 Hawke Street', GETDATE(), 3),
('Carmen', 'Z', 'Kane', 'Wenzhou NH, 6372 Kuznetsov Street', GETDATE(), 2),
('Arthur', 'Y', 'Barton', 'Spring ID, 7548 Fletcher Avenue', GETDATE(), 2),
('Vernon', 'R', 'Newman', 'Nueva Cádiz MS, 5883 Tanaka Street', GETDATE(), 3),
('Natasha', 'J', 'Hyland', 'Delgovicia OR, 1287 Hipper Avenue', GETDATE(), 2),
('Julia', 'K', 'Foster', 'Akatsuki AL, 7522 Villeneuve Avenue', GETDATE(), 3),
('George', 'D', 'Sanders', 'St. Yegorov DE, 3542 Pound Road', GETDATE(), 1),
('Caroline', 'O', 'Flint', 'Al-Matabbah AK, 8865 Beatty Street', GETDATE(), 2),
('Fiona', 'J', 'Balfour', 'Wenzhou WA, 1657 Doria Avenue', GETDATE(), 2),
('Luke', 'L', 'Lee', 'Delgovicia KS, 4475 Tirpitz Street', GETDATE(), 2),
('Charity', 'G', 'Woodard', 'San Lucas NM, 3616 Essen Avenue', GETDATE(), 3),
('Estelle', 'I', 'Sedgwick', 'St. Yegorov IL, 2687 Kountouriotis Street', GETDATE(), 3),
('Kathleen', 'T', 'Sinclair', 'Puerto González FL, 5421 Hipper Road', GETDATE(), 1),
('Nicholas', 'U', 'York', 'Anchor IL, 4181 Butakov Avenue', GETDATE(), 1),
('Jared', 'D', 'Rawson', 'Karakosov ND, 4842 Mountbatten Street', GETDATE(), 1),
('Doreen', 'O', 'Perry', 'Al-Karak ME, 1212 Morris Road', GETDATE(), 1),
('Duncan', 'H', 'Terrell', 'Al-Jissa MN, 1871 Fletcher Street', GETDATE(), 2),
('Grant', 'W', 'Young', 'New Roanoke TX, 7314 Essen Avenue', GETDATE(), 2),
('Clark', 'Q', 'Billingsley', 'Theia AK, 4712 Codrington Road', GETDATE(), 2),
('Caroline', 'M', 'Bergman', 'Akatsuki WV, 6652 Mountbatten Road', GETDATE(), 3),
('Emma', 'V', 'Balfour', 'Delgovicia KY, 8645 Pound Road', GETDATE(), 1),
('Lois', 'O', 'Parson', 'Bounty WY, 4764 Crutchley Avenue', GETDATE(), 3),
('Desmond', 'E', 'Bean', 'Thinis AZ, 2416 Yonai Avenue', GETDATE(), 2),
('Matthew', 'S', 'Ericson', 'New Roanoke MI, 8623 Milne Street', GETDATE(), 2),
('Shannon', 'M', 'Griffin', 'New Jerusalem WI, 8228 Suffren Street', GETDATE(), 3),
('Elle', 'C', 'Hyland', 'San Lucas MA, 5638 Pound Road', GETDATE(), 1),
('Natasha', 'Q', 'North', 'La Isabela MI, 6432 Milne Street', GETDATE(), 3),
('Fiona', 'L', 'Samuels', 'Al-Mada-in GA, 3567 Grasse Street', GETDATE(), 2),
('Selina', 'E', 'Mundy', 'Al-Mada-in AZ, 1235 Tirpitz Road', GETDATE(), 3),
('Samantha', 'A', 'Nathanson', 'Theia SD, 1224 Tanaka Avenue', GETDATE(), 3),
('Kevin', 'K', 'Reeves', 'Dis IA, 1314 Codrington Road', GETDATE(), 1),
('Horace', 'G', 'Garfield', 'Thinis AZ, 4517 Beatty Road', GETDATE(), 2),
('Myrna', 'H', 'Conroy', 'Theia NM, 5848 Treville Avenue', GETDATE(), 3),
('Grace', 'Q', 'Holden', 'Las Veredas WA, 2744 Byng Street', GETDATE(), 3),
('Fred', 'P', 'Arnold', 'Salaam IA, 6288 Kornilov Street', GETDATE(), 2),
('Timothy', 'O', 'Hall', 'St. Yegorov CA, 6166 Grasse Avenue', GETDATE(), 2),
('Robert', 'R', 'Weaver', 'Las Veredas MD, 4644 Spruance Road', GETDATE(), 2),
('Rachel', 'C', 'Rivers', 'San Fernando CT, 6155 Morris Street', GETDATE(), 3),
('Marshall', 'F', 'Yardley', 'Delgovicia AR, 2177 Durham Street', GETDATE(), 3),
('Earl', 'Z', 'Murray', 'Wang Tong RI, 3144 Morris Street', GETDATE(), 1),
('Eliza', 'Y', 'Scowley', 'Karakosov FL, 7848 Durham Avenue', GETDATE(), 1),
('Jane', 'O', 'Sedgwick', 'Delgovicia AL, 6436 Beatty Street', GETDATE(), 2),
('George', 'S', 'Sykes', 'Puerto González WY, 4138 Treville Street', GETDATE(), 1),
('Carol', 'S', 'Stokes', 'Dis WA, 5534 Codrington Avenue', GETDATE(), 3),
('Philip', 'O', 'McMillan', 'San Fernando UT, 7112 Hart Avenue', GETDATE(), 1),
('Frank', 'A', 'Perry', 'Tuscany WV, 1788 Laforey Avenue', GETDATE(), 1),
('Louisa', 'O', 'Abbott', 'Theia NY, 3688 Durham Road', GETDATE(), 2),
('Trevor', 'P', 'Nash', 'Xianyang VA, 2174 Laforey Street', GETDATE(), 2),
('Darcy', 'B', 'West', 'Olympia AR, 7383 Suffren Street', GETDATE(), 1),
('Wyatt', 'B', 'Roberts', 'Spring KY, 6865 Moorsom Street', GETDATE(), 2),
('Miles', 'E', 'Hendricks', 'Al-Matabbah MA, 1666 Crutchley Street', GETDATE(), 3),
('Wallace', 'X', 'Rowley', 'New Roanoke AL, 3373 Pound Street', GETDATE(), 2),
('Kayla', 'S', 'Ellis', 'New Roanoke KY, 1851 Tanaka Avenue', GETDATE(), 1)

-- insert 5 sample facilities
INSERT INTO facility(facility_address, facility_name)
VALUES('Dis CO, 1373 Hart Street', 'Dis Gym'),
('St. Pomeroy MI, 1883 Grasse Street', 'St. Pomeroy Gym'),
('Al-Karak MI, 3857 Hipper Street', 'Al-Karak Gym'),
('Serendipity HI, 3854 Byng Avenue', 'Serendipity Gym'),
('Olympia OK, 2314 Tirpitz Street', 'Olympia Gym')

-- Insert some generated employees
INSERT INTO employee(employee_first_name, employee_middle_initial, employee_last_name, employee_address, job_title, salary, facility_ID)
VALUES('Martha', 'H', 'Robertson', 'Anchor KY, 6573 Cunningham Street', 'Manager', '30.0', '1'),
('Lloyd', 'O', 'Pershing', 'San Cristóbal NC, 4886 Cunningham Street', 'HR', '20.0', '1'),
('Leah', 'J', 'Wright', 'Concord OR, 8185 Pound Road', 'Janitor', '15.0', '1'),
('Suzanne', 'N', 'Holmes', 'Hope MA, 3464 Kornilov Avenue', 'Janitor', '15.0', '1'),
('Tricia', 'K', 'Cooper', 'Karakosov NJ, 1546 Yonai Road', 'Janitor', '15.0', '1'),
('Walter', 'B', 'Pershing', 'Spring MT, 3768 Cunningham Avenue', 'Janitor', '15.0', '1'),
('Audrey', 'C', 'Franklin', 'Dis GA, 2117 Halsey Avenue', 'Janitor', '15.0', '1'),
('Ross', 'X', 'Morgan', 'Las Veredas ID, 1562 Hipper Road', 'Trainer', '20.0', '1'),
('Richard', 'G', 'Kingsford', 'Nueva Cádiz CO, 5675 Hawke Avenue', 'Trainer', '20.0', '1'),
('Harlan', 'F', 'Reaves', 'Delgovicia ME, 1715 King Avenue', 'Trainer', '20.0', '1'),
('Marissa', 'S', 'Garrovick', 'Al-Mada-in GA, 7671 Tyler Street', 'Trainer', '20.0', '1'),
('Hailey', 'B', 'Woodard', 'Nozomi IL, 7447 Codrington Avenue', 'Trainer', '20.0', '1'),
('Harry', 'P', 'North', 'Nueva Cádiz MT, 5114 Potemkin Avenue', 'Desk', '15.0', '1'),
('Marjorie', 'N', 'Goodwin', 'New Roanoke NY, 4856 Doria Avenue', 'Desk', '15.0', '1'),
('Emmett', 'X', 'Sullivan', 'Puerto González ME, 3325 Lezo Street', 'Desk', '15.0', '1'),
('Grant', 'W', 'Snow', 'New Jerusalem NE, 3883 Tirpitz Avenue', 'Manager', '30.0', '2'),
('Walter', 'W', 'Conley', 'Wang Tong TN, 3526 Kornilov Street', 'HR', '20.0', '2'),
('Kenneth', 'G', 'Winters', 'Salaam UT, 8825 Beatty Avenue', 'Janitor', '15.0', '2'),
('Irving', 'P', 'Knight', 'Al-Mada-in PA, 4455 Tyler Street', 'Janitor', '15.0', '2'),
('Tabitha', 'F', 'Wentworth', 'Wang Tong WA, 2132 Lezo Road', 'Janitor', '15.0', '2'),
('Candace', 'X', 'Parker', 'Theia DE, 1772 Milne Avenue', 'Janitor', '15.0', '2'),
('Tara', 'U', 'Balfour', 'Bounty LA, 8781 Kountouriotis Street', 'Janitor', '15.0', '2'),
('Clara', 'O', 'Wells', 'La Isabela WA, 4322 Treville Avenue', 'Trainer', '20.0', '2'),
('Adrienne', 'U', 'Howell', 'Puerto González NJ, 3417 Jellicoe Avenue', 'Trainer', '20.0', '2'),
('Brenda', 'K', 'Roswell', 'Al-Karak ME, 4734 Jellicoe Road', 'Trainer', '20.0', '2'),
('Holly', 'N', 'Turner', 'Olympia DE, 2113 Essen Avenue', 'Trainer', '20.0', '2'),
('Cassandra', 'J', 'Cook', 'Serendipity TX, 8345 Butakov Road', 'Trainer', '20.0', '2'),
('Edna', 'N', 'Sharp', 'Concord NV, 6163 Tanaka Road', 'Desk', '15.0', '2'),
('Irving', 'G', 'Newman', 'Concord MD, 6756 Villeneuve Avenue', 'Desk', '15.0', '2'),
('Penny', 'X', 'Vernon', 'Nozomi VT, 4256 Tanaka Street', 'Desk', '15.0', '2'),
('Vivian', 'U', 'Howell', 'Al-Jissa CO, 7664 Spruance Avenue', 'Manager', '30.0', '3'),
('Emma', 'B', 'Silverstone', 'San Lucas AL, 1858 Tyler Avenue', 'HR', '20.0', '3'),
('Kimberly', 'O', 'Wentworth', 'Delgovicia PA, 2516 King Road', 'Janitor', '15.0', '3'),
('Tabitha', 'J', 'Knight', 'Al-Mada-in IA, 3516 Kountouriotis Street', 'Janitor', '15.0', '3'),
('Stanley', 'X', 'Steel', 'Puerto González WY, 1445 Codrington Avenue', 'Janitor', '15.0', '3'),
('Phoebe', 'I', 'Bains', 'New Troy ND, 1668 Potemkin Avenue', 'Janitor', '15.0', '3'),
('Leah', 'D', 'Fleming', 'Wang Tong NH, 7123 Morris Avenue', 'Janitor', '15.0', '3'),
('Eleonor', 'I', 'Bergman', 'La Isabela KY, 1144 Fletcher Avenue', 'Trainer', '20.0', '3'),
('Lucy', 'B', 'Whitfield', 'Puerto González MS, 3368 Suffren Road', 'Trainer', '20.0', '3'),
('Alexander', 'R', 'Jacobs', 'New Coventry MN, 7412 Treville Avenue', 'Trainer', '20.0', '3'),
('Kierra', 'L', 'Campbell', 'Al-Matabbah WI, 8615 Pound Street', 'Trainer', '20.0', '3'),
('Dennis', 'W', 'Phillips', 'Olympia MT, 3872 Turner Road', 'Trainer', '20.0', '3'),
('Nathan', 'K', 'Bean', 'New Roanoke NH, 1347 Hart Road', 'Desk', '15.0', '3'),
('Kathleen', 'W', 'Gates', 'Nueva Cádiz OR, 4454 Moorsom Avenue', 'Desk', '15.0', '3'),
('Russell', 'I', 'Whittaker', 'Avalon MN, 5871 Lezo Avenue', 'Desk', '15.0', '3'),
('Amelia', 'P', 'Chamberlain', 'Concord MD, 6574 Moorsom Road', 'Manager', '30.0', '4'),
('Felix', 'V', 'Lockhart', 'Las Veredas KS, 5142 Crutchley Road', 'HR', '20.0', '4'),
('Carmen', 'A', 'Reese', 'St. Pomeroy KY, 4681 Turner Street', 'Janitor', '15.0', '4'),
('Patricia', 'J', 'Bellflower', 'Xianyang CT, 7516 Beatty Street', 'Janitor', '15.0', '4'),
('Marcia', 'L', 'McGillis', 'Wang Tong MO, 8477 Moorsom Street', 'Janitor', '15.0', '4'),
('Anthony', 'H', 'Nichols', 'Anchor OK, 4314 Tanaka Avenue', 'Janitor', '15.0', '4'),
('Sarah', 'I', 'Bergman', 'Al-Matabbah MS, 8761 Halsey Road', 'Janitor', '15.0', '4'),
('Dermot', 'X', 'Jackson', 'New Troy CA, 2745 Moorsom Road', 'Trainer', '20.0', '4'),
('Iris', 'Q', 'Silverman', 'Delgovicia WY, 2627 Jellicoe Road', 'Trainer', '20.0', '4'),
('Darcy', 'K', 'Jones', 'Al-Jissa SC, 2548 Tanaka Avenue', 'Trainer', '20.0', '4'),
('Carl', 'A', 'Smart', 'Hope OH, 7174 Beatty Avenue', 'Trainer', '20.0', '4'),
('Liam', 'P', 'Underwood', 'Dis MS, 6183 Lezo Avenue', 'Trainer', '20.0', '4'),
('Brianna', 'G', 'Garrovick', 'New Roanoke FL, 4465 Spruance Street', 'Desk', '15.0', '4'),
('Carmen', 'Z', 'Evans', 'San Cristóbal TX, 3432 Byng Street', 'Desk', '15.0', '4'),
('Wayne', 'H', 'Dyson', 'Concord SC, 5638 Milne Avenue', 'Desk', '15.0', '4'),
('Sarah', 'W', 'Conley', 'Wenzhou HI, 5647 Villeneuve Street', 'Manager', '30.0', '5'),
('Finn', 'Q', 'Nash', 'Al-Nuqayrah MT, 5534 Jellicoe Street', 'HR', '20.0', '5'),
('Gillian', 'B', 'Hood', 'Karakosov NH, 4841 Beatty Street', 'Janitor', '15.0', '5'),
('Elaine', 'E', 'Lawrence', 'Al-Jissa IA, 8787 Hargood Road', 'Janitor', '15.0', '5'),
('Robin', 'K', 'Potter', 'Akatsuki NJ, 6434 Tyler Road', 'Janitor', '15.0', '5'),
('Graham', 'E', 'Garland', 'Nueva Cádiz ME, 4725 Treville Road', 'Janitor', '15.0', '5'),
('Harriet', 'M', 'Milton', 'Al-Jissa MN, 4138 Tirpitz Road', 'Janitor', '15.0', '5'),
('Gwendolyn', 'S', 'Bains', 'Olympia CT, 5657 Milne Road', 'Trainer', '20.0', '5'),
('Doreen', 'E', 'Gates', 'San Cristóbal KY, 2474 Tyler Road', 'Trainer', '20.0', '5'),
('Edith', 'L', 'Wilkins', 'Nueva Sonora TN, 3287 Codrington Avenue', 'Trainer', '20.0', '5'),
('Ruth', 'K', 'Cartwright', 'Avalon PA, 3252 Turner Road', 'Trainer', '20.0', '5'),
('Tony', 'H', 'England', 'Concord NC, 1437 Essen Road', 'Trainer', '20.0', '5'),
('Skye', 'N', 'Gates', 'Wang Tong OK, 4634 Yonai Avenue', 'Desk', '15.0', '5'),
('Lois', 'L', 'Bloom', 'Avalon ID, 4266 Kuznetsov Road', 'Desk', '15.0', '5'),
('George', 'F', 'McCormick', 'Nueva Sonora GA, 6166 Durham Avenue', 'Desk', '15.0', '5')

-- insert some room types
INSERT INTO room_type(room_type_name)
VALUES('Pool'), ('Lobby'), ('Weight Room'), ('Cardio Room'), ('Studio')

-- Insert some rooms
INSERT INTO room(room_name, size_sqft, capacity, facility_ID, room_type_ID)
VALUES('Dis Lobby', 100, 30, 1, 2),
('Dis Pool', 200, 30, 1, 1),
('Dis Studio 1', 300, 40, 1, 5),
('Dis Studio 2', 300, 40, 1, 5),
('Dis Studio 3', 100, 15, 1, 5),
('Dis Weight Room 1', 300, 40, 1, 3),
('Dis Weight Room 2', 150, 20, 1, 3),
('Dis Cardio Room', 400, 20, 1, 4),
('Pomeroy Lobby', 100, 30, 2, 2),
('Pomeroy Studio', 200, 40, 2, 5),
('Pomeroy Weight Room', 400, 50, 2, 3),
('Pomeroy Cardio Room', 400, 25, 2, 4),
('Al-Karak Lobby', 100, 30, 3, 2),
('Al-Karak Weight Room 1', 300, 40, 3, 3),
('Al-Karak Weight Room 2', 150, 20, 3, 3),
('Ak-Karak Cardio Room', 400, 20, 3, 4),
('Serendipity Lobby', 100, 30, 4, 2),
('Serendipity Pool', 200, 30, 4, 1),
('Serendipity Studio 1', 300, 40, 4, 5),
('Serendipity Studio 2', 300, 40, 4, 5),
('Serendipity Studio 3', 100, 15, 4, 5),
('Serendipity Weight Room 1', 300, 40, 4, 3),
('Serendipity Weight Room 2', 150, 20, 4, 3),
('Serendipity Cardio Room', 400, 20, 4, 4),
('Olympia Lobby', 100, 30, 5, 2),
('Olympia Pool', 200, 30, 5, 1),
('Olympia Studio 1', 300, 40, 5, 5),
('Olympia Studio 2', 300, 40, 5, 5),
('Olympia Studio 3', 100, 15, 5, 5),
('Olympia Weight Room 1', 300, 40, 5, 3),
('Olympia Weight Room 2', 150, 20, 5, 3),
('Olympia Cardio Room', 400, 20, 5, 4)

-- excecute the hire_instructor procedure to give some members private instructors
EXEC hire_instructor 1, 8
EXEC hire_instructor 2, 25
EXEC hire_instructor 3, 71

-- Insert some classes
insert into class(class_name, cost)
VALUES('Basic Weight Lifting', 100.0),
('Advanced Weight Lifting', 150.0),
('Basic Biking', 100.0),
('Advanced Biking', 150.0),
('Basic Weight Lifting', 100.0),
('Advanced Weight Lifting', 150.0),
('Basic Biking', 100.0),
('Advanced Biking', 150.0)

-- insert class sessions
INSERT INTO class_session(class_session_day, class_session_time, class_session_room, class_ID)
VALUES('Monday', '19:00:00.0000000', 6, 1),
('Thursday', '19:00:00.0000000', 6, 1),
('Tuesday', '19:00:00.0000000', 6, 2),
('Friday', '19:00:00.0000000', 6, 2),
('Monday', '19:00:00.0000000', 8, 3),
('Thursday', '19:00:00.0000000', 8, 3),
('Tuesday', '19:00:00.0000000', 8, 4),
('Friday', '19:00:00.0000000', 8, 4),
('Monday', '19:00:00.0000000', 30, 5),
('Thursday', '19:00:00.0000000', 30, 5),
('Tuesday', '19:00:00.0000000', 30, 6),
('Friday', '19:00:00.0000000', 30, 6),
('Monday', '19:00:00.0000000', 32, 7),
('Thursday', '19:00:00.0000000', 32, 7),
('Tuesday', '19:00:00.0000000', 32, 8),
('Friday', '19:00:00.0000000', 32, 8)

-- insert into class_instructor_link table to assign instructors
Insert into class_instructor_link(class_ID, instructor_ID)
VALUES(1, 9), (1, 10), (2, 12), (3, 9), (4, 11), (5, 72), (6, 69), (7, 71), (7, 70), (8, 71), (8, 70)

-- insert into class_session_member_link table to assign students
INSERT INTO class_session_member_link(class_session_ID, member_ID)
VALUES(3,6),
(2,17),
(3,23),
(4,25),
(8,29),
(7,31),
(8,33),
(4,37),
(2,40),
(4,45),
(4,47),
(7,53),
(1,67),
(1,78),
(6,79),
(6,81),
(8,82),
(3,83),
(6,88),
(6,90),
(6,95)

-- insert some generated check in data
INSERT INTO member_check_in(check_in_date, member_ID, facility_ID)
VALUES('2020-05-09 17:55:16', 1, 1),
('2020-07-16 12:15:58', 1, 1),
('2020-09-20 17:15:16', 1, 1),
('2020-03-16 12:13:28', 1, 1),
('2020-07-18 13:11:14', 1, 1),
('2020-12-18 15:07:12', 1, 1),
('2020-12-27 12:30:02', 2, 2),
('2020-03-05 13:57:36', 2, 2),
('2020-04-02 19:47:53', 2, 2),
('2020-04-27 18:38:51', 2, 2),
('2020-09-21 08:01:51', 2, 2),
('2020-02-24 18:47:53', 2, 2),
('2020-03-18 14:19:02', 2, 2),
('2020-09-04 10:13:06', 3, 5),
('2020-01-25 15:05:11', 3, 5),
('2020-01-14 17:16:46', 3, 5),
('2020-09-16 18:52:29', 3, 5),
('2020-05-07 20:45:16', 3, 5),
('2020-12-05 15:10:13', 3, 5),
('2020-05-28 15:02:10', 3, 5),
('2020-03-27 17:35:56', 3, 5),
('2020-03-03 16:50:14', 4, 4),
('2020-08-13 11:55:16', 5, 3),
('2020-05-18 15:58:49', 5, 3),
('2020-07-20 15:59:10', 6, 1),
('2020-04-17 20:40:45', 6, 1),
('2020-02-18 11:07:03', 6, 1),
('2020-09-14 19:18:25', 7, 2),
('2020-02-24 14:10:50', 8, 3),
('2020-04-08 11:16:43', 8, 3),
('2020-09-21 13:17:23', 9, 2),
('2020-06-28 19:35:31', 9, 2),
('2020-10-17 11:12:34', 9, 2),
('2020-01-16 11:10:54', 10, 3),
('2020-07-21 16:23:27', 11, 4),
('2020-08-17 18:41:35', 13, 5),
('2020-08-06 11:01:16', 13, 5),
('2020-02-25 10:16:08', 16, 5),
('2020-07-16 18:47:09', 17, 1),
('2020-01-19 12:46:32', 17, 1),
('2020-01-11 16:06:48', 17, 1),
('2020-09-13 08:58:40', 17, 1),
('2020-09-21 18:13:15', 17, 1),
('2020-09-19 14:44:16', 17, 1),
('2020-11-10 15:55:40', 17, 1),
('2020-03-25 16:41:06', 17, 1),
('2020-01-15 20:19:04', 20, 2),
('2020-10-01 09:39:46', 20, 2),
('2020-06-01 17:28:19', 21, 4),
('2020-02-05 12:24:06', 21, 4),
('2020-10-08 13:43:21', 23, 1),
('2020-05-12 08:57:31', 23, 1),
('2020-10-07 13:18:33', 23, 1),
('2020-07-01 10:53:02', 25, 1),
('2020-11-21 13:02:20', 25, 1),
('2020-03-24 08:12:27', 25, 1),
('2020-01-20 13:04:38', 25, 1),
('2020-05-09 11:15:54', 25, 1),
('2020-02-20 17:06:36', 25, 1),
('2020-06-03 20:52:26', 25, 1),
('2020-09-26 15:17:47', 25, 1),
('2020-08-05 12:24:02', 25, 1),
('2020-02-09 19:15:47', 25, 1),
('2020-04-21 17:24:07', 27, 3),
('2020-07-05 13:52:03', 27, 3),
('2020-06-07 14:10:55', 27, 3),
('2020-10-14 18:25:24', 28, 4),
('2020-12-07 16:49:32', 29, 2),
('2020-07-12 10:31:15', 29, 2),
('2020-10-26 10:02:51', 29, 2),
('2020-07-04 08:03:28', 29, 2),
('2020-01-24 15:04:53', 29, 2),
('2020-01-04 16:53:42', 29, 2),
('2020-06-03 18:34:22', 29, 2),
('2020-04-22 12:19:09', 29, 2),
('2020-03-06 19:08:07', 29, 2),
('2020-09-15 19:44:30', 30, 3),
('2020-04-26 15:55:39', 30, 3),
('2020-02-07 18:49:20', 31, 2),
('2020-02-20 14:43:24', 31, 2),
('2020-04-14 10:21:16', 31, 2),
('2020-08-25 12:27:01', 31, 2),
('2020-10-15 20:04:26', 31, 2),
('2020-12-20 20:38:53', 31, 2),
('2020-07-01 13:49:41', 31, 2),
('2020-08-08 17:11:56', 31, 2),
('2020-04-08 11:12:41', 31, 2),
('2020-08-12 09:16:56', 31, 2),
('2020-01-12 08:48:38', 33, 2),
('2020-04-24 08:15:49', 33, 2),
('2020-02-06 08:18:11', 33, 2),
('2020-09-26 20:33:28', 33, 2),
('2020-04-16 16:52:31', 34, 5),
('2020-05-09 16:26:58', 34, 5),
('2020-04-01 15:49:22', 34, 5),
('2020-06-08 13:51:04', 36, 2),
('2020-04-19 17:49:42', 36, 2),
('2020-11-09 19:55:07', 36, 2),
('2020-03-20 10:00:58', 37, 1),
('2020-09-17 18:58:09', 37, 1),
('2020-06-12 14:53:19', 37, 1),
('2020-06-05 09:48:03', 37, 1),
('2020-12-14 16:47:38', 37, 1),
('2020-04-28 10:42:20', 37, 1),
('2020-03-21 08:43:05', 37, 1),
('2020-05-28 09:50:16', 37, 1),
('2020-07-11 09:10:50', 38, 5),
('2020-04-05 11:21:17', 39, 5),
('2020-10-16 15:47:48', 39, 5),
('2020-09-26 16:14:09', 40, 1),
('2020-07-08 12:04:42', 42, 1),
('2020-06-22 18:34:08', 42, 1),
('2020-02-01 17:55:14', 43, 4),
('2020-01-14 13:07:15', 43, 4),
('2020-08-05 18:33:37', 43, 4),
('2020-03-11 13:49:52', 44, 2),
('2020-04-18 08:34:51', 44, 2),
('2020-01-20 16:33:57', 45, 1),
('2020-06-21 10:06:11', 45, 1),
('2020-11-15 08:07:13', 45, 1),
('2020-12-20 09:44:51', 45, 1),
('2020-05-21 15:14:01', 45, 1),
('2020-03-10 09:28:47', 45, 1),
('2020-11-22 10:00:15', 45, 1),
('2020-03-21 11:06:06', 46, 3),
('2020-04-21 16:06:28', 47, 1),
('2020-07-16 08:17:02', 47, 1),
('2020-12-16 10:57:09', 47, 1),
('2020-07-24 15:08:12', 47, 1),
('2020-04-19 10:06:35', 47, 1),
('2020-05-25 12:10:28', 47, 1),
('2020-12-03 14:57:09', 47, 1),
('2020-05-03 20:06:43', 48, 5),
('2020-07-28 11:49:10', 48, 5),
('2020-11-08 19:30:53', 48, 5),
('2020-03-08 18:30:56', 49, 4),
('2020-11-26 17:02:56', 53, 2),
('2020-03-24 14:03:47', 53, 2),
('2020-01-21 18:07:37', 53, 2),
('2020-06-20 17:17:23', 54, 1),
('2020-03-11 19:20:10', 56, 1),
('2020-09-12 19:39:20', 57, 2),
('2020-08-25 09:07:04', 57, 2),
('2020-01-22 08:38:38', 58, 4),
('2020-09-11 13:20:15', 58, 4),
('2020-04-21 10:17:17', 58, 4),
('2020-11-16 17:48:28', 59, 3),
('2020-11-23 12:41:12', 60, 3),
('2020-08-04 08:37:18', 62, 4),
('2020-09-16 16:40:55', 62, 4),
('2020-07-10 10:26:00', 63, 2),
('2020-10-08 12:25:55', 64, 1),
('2020-05-03 15:39:12', 65, 5),
('2020-07-23 11:19:51', 65, 5),
('2020-07-27 08:47:59', 67, 1),
('2020-10-14 11:54:34', 67, 1),
('2020-07-11 16:13:23', 68, 3),
('2020-06-20 19:43:47', 68, 3),
('2020-12-11 15:10:24', 69, 3),
('2020-04-18 10:40:28', 70, 1),
('2020-09-08 17:01:28', 70, 1),
('2020-09-11 10:53:09', 71, 5),
('2020-01-10 19:41:51', 72, 4),
('2020-02-18 20:59:46', 72, 4),
('2020-02-17 10:34:14', 72, 4),
('2020-10-15 13:22:38', 75, 5),
('2020-04-20 10:05:08', 76, 5),
('2020-02-16 14:22:48', 76, 5),
('2020-07-11 17:46:33', 76, 5),
('2020-04-14 10:28:58', 77, 5),
('2020-02-17 19:24:05', 77, 5),
('2020-06-18 09:30:01', 77, 5),
('2020-08-03 20:05:40', 78, 1),
('2020-12-11 16:40:26', 78, 1),
('2020-02-19 10:06:24', 78, 1),
('2020-02-24 15:06:39', 78, 1),
('2020-01-02 10:47:00', 78, 1),
('2020-03-03 14:24:58', 78, 1),
('2020-01-06 16:53:09', 78, 1),
('2020-02-23 17:16:21', 79, 2),
('2020-08-28 10:48:45', 79, 2),
('2020-06-19 16:19:14', 79, 2),
('2020-12-15 10:32:47', 79, 2),
('2020-10-13 09:18:30', 80, 3),
('2020-01-23 16:34:41', 81, 2),
('2020-12-13 08:18:30', 81, 2),
('2020-11-18 08:00:26', 81, 2),
('2020-12-15 14:53:43', 81, 2),
('2020-04-12 18:52:39', 81, 2),
('2020-11-12 08:13:25', 82, 2),
('2020-11-23 13:13:49', 82, 2),
('2020-07-28 08:02:08', 82, 2),
('2020-11-11 16:41:07', 82, 2),
('2020-12-15 20:46:21', 82, 2),
('2020-07-19 18:07:40', 83, 1),
('2020-02-19 09:31:20', 83, 1),
('2020-10-02 08:51:27', 83, 1),
('2020-12-13 20:22:04', 83, 1),
('2020-02-13 14:06:19', 83, 1),
('2020-06-11 09:47:56', 83, 1),
('2020-10-18 13:46:48', 83, 1),
('2020-01-22 15:16:45', 83, 1),
('2020-10-10 16:14:28', 84, 5),
('2020-01-28 16:44:13', 84, 5),
('2020-02-04 14:52:40', 85, 4),
('2020-09-08 17:59:37', 87, 5),
('2020-10-03 17:17:07', 87, 5),
('2020-06-09 13:25:27', 88, 2),
('2020-05-06 08:37:04', 88, 2),
('2020-12-19 13:00:23', 88, 2),
('2020-06-06 20:40:32', 88, 2),
('2020-01-18 18:44:42', 88, 2),
('2020-05-16 13:10:04', 88, 2),
('2020-09-21 10:50:44', 88, 2),
('2020-08-23 08:01:30', 88, 2),
('2020-12-10 09:02:01', 89, 3),
('2020-06-25 20:13:22', 90, 2),
('2020-04-03 09:50:59', 90, 2),
('2020-01-16 12:48:02', 92, 3),
('2020-12-24 19:23:48', 92, 3),
('2020-10-16 20:30:14', 92, 3),
('2020-01-27 18:44:41', 93, 1),
('2020-02-09 09:53:41', 93, 1),
('2020-05-27 15:12:55', 94, 3),
('2020-03-23 13:46:27', 94, 3),
('2020-05-17 16:21:39', 95, 2),
('2020-01-28 09:17:30', 95, 2),
('2020-08-14 12:27:15', 95, 2),
('2020-11-28 10:09:33', 95, 2),
('2020-12-19 20:14:07', 95, 2),
('2020-08-20 15:26:53', 95, 2),
('2020-05-01 20:37:33', 95, 2),
('2020-06-28 18:30:54', 95, 2),
('2020-09-25 20:27:40', 96, 4),
('2020-08-27 15:55:41', 96, 4),
('2020-02-11 10:20:29', 97, 4),
('2020-11-04 13:49:15', 99, 1),
('2020-06-18 10:17:06', 99, 1),
('2020-01-17 14:32:15', 99, 1),
('2020-02-01 15:58:18', 100, 2)

-- select statements

-- look at what mempership packages are earning the most money
SELECT * from most_profitable_memberships

-- look at which facilities people are checking into
select facility.facility_name, member_first_name + ' ' + member.member_last_name as member_name
from member_check_in
join facility on member_check_in.facility_ID = facility.facility_ID
join member on member_check_in.member_ID = member.member_ID

-- does class membership and private instructors leat to more checkins
GO

CREATE FUNCTION active_member(@membershipID int)
RETURNS bit AS
BEGIN
    DECLARE @returnValue bit
    IF ((select private_instructor
        from member where member_ID = @membershipID) is not null)
    BEGIN
        select @returnValue = 1
    END

    ELSE IF((select member_ID 
             from class_session_member_link
             where member_ID = @membershipID) is not null)
    BEGIN
        select @returnValue = 1
    END

    ELSE
    BEGIN
        select @returnValue = 0
    END

    RETURN @returnValue
END
GO

select member.member_ID, dbo.active_member(member.member_ID) as active_member ,COUNT(member_check_in.member_check_in_ID) as num_checkins
from member
join member_check_in on member.member_ID = member_check_in.member_ID
group by member.member_ID

-- at what times are people likley to use the gym

select check_in_date from member_check_in

-- do different rooms improve attendance
go 
create function count_room_type(@rid int, @fid int)
RETURNS INT AS
BEGIN
    DECLARE @returnValue int
    select @returnValue = count(room_ID) from room where facility_ID = @fid and room_type_ID = @rid
    return @returnValue
END
GO

select facility.facility_ID, 
       COUNT(member_check_in.facility_ID) num_check_ins,
       dbo.count_room_type(1, facility.facility_ID) n_pools,
       dbo.count_room_type(2, facility.facility_ID) n_lobbies,
       dbo.count_room_type(3, facility.facility_ID) n_weight_rooms,
       dbo.count_room_type(4, facility.facility_ID) n_cardio_rooms,
       dbo.count_room_type(5, facility.facility_ID) n_studios
from facility
join member_check_in on facility.facility_ID = member_check_in.facility_ID
group by facility.facility_ID
