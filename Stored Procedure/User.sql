USE Tastie;

# Login input can be an email or a phone number.
# (phone_ or email) and password is required
# the rest of the attributes can be null
DROP PROCEDURE IF EXISTS AccountRegistration;

DELIMITER $$
Create Procedure AccountRegistration (
	IN phone_ char(10),
	IN password_ char(100),
	IN 	role_ TINYINT,  # 1 là customer, 2 là provider, 3 là shipper
	IN email_ VARCHAR(40),
	IN firstname_ nvarchar(50),
	IN lastname_ nvarchar(50),
	IN gender_ TINYINT, # 0 là nữ, 1 là nam 
	IN birthday_ date,
	IN registered_date_ date
)
Begin
	DECLARE user_id_ BIGINT;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select Email, Phone From `User` Where Email= EMAIL_ or Phone=phone_ and Password = password_)
    THEN
		Insert Into `User` 
		(phone, `password`,`role`, email, first_name, last_name, gender, birthday, registered_at)
		Values
		(phone_, password_, role_, email_, firstname_, lastname_, gender_, birthday_, registered_date_);
        
        SELECT user_id INTO user_id_ FROM `User` u WHERE u.phone = phone_ OR u.email = email_;
        
        INSERT INTO Cart(user_id) VALUES(user_id_);
	ELSE 
		SET @s = 'Account already exists';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
		
	END IF;
	COMMIT;
End$$
DELIMITER ;

-- CALL AccountRegistration ('012345689', 'ABC', 1, 'tyteo1@gmail.com','Nguyen', 'Ty', 1, '2020-3-4', CURDATE());

#-------------------------------------------

# login uses (phone and password) or (email and password)
# if using (phone and password), email can be null
DROP PROCEDURE IF EXISTS Login;
DELIMITER $$
Create Procedure Login (
	IN phone_ char(10),
	IN password_ char(20),
	IN email_ VARCHAR(40)
)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select Email, Phone From `User` Where email=email_ or phone=phone_ and `password`=password_)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
    End IF;
    
    Select * From `User` Where email=@email_ or phone=phone_ and `password`=password_;
    COMMIT;
    
End$$
DELIMITER ;

# CALL Login ('127223056', 'i87Z8UWYV0x', 'Altstadt@hubspot.com');



#--------------------------------------------
/*
userid_ is required
update phone, `password`, `role`, email, first_name, last_name, gender, birthday, and they can be null
if  any field is null, it will rollback the field from the old record

EX: 
	VALUE BEFORE u1	(1000001	Nguyen	Teo	M	1997-02-02	a@gmail.com	111	BBBBBB, ...)									
    UpdateAccount(1000001, NULL, Quang, NULL, NULL, NULL, NULL)
    
    => result : (1000001	Nguyen	Quang	M	1997-02-02	a@gmail.com	111	BBBBBB, ...)
*/

DROP PROCEDURE IF EXISTS UpdateAccount;
DELIMITER $$
Create Procedure UpdateAccount(
	IN userid_ BIGINT,
	IN phone_ CHAR(10),
	IN email_ VARCHAR(40),
	IN password_ CHAR(150),
	IN role_ TINYINT,  # 1 là customer, 2 là provider, 3 là shipper
	IN firstname_ NVARCHAR(50),
	IN lastname_ NVARCHAR(50),
	IN gender_ TINYINT, # 0 là nữ, 1 là nam 
	IN birthday_ DATE
)
BEGIN
    DECLARE phone_old CHAR(10);
	DECLARE email_old VARCHAR(40);
	DECLARE password_old CHAR(100);
	DECLARE role_old TINYINT;
	DECLARE firstname_old NVARCHAR(50);
	DECLARE lastname_old NVARCHAR(50);
-- 	DECLARE gender_old  ENUM('M', 'F');
	DECLARE gender_old TINYINT;
	DECLARE birthday_old DATE;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	SELECT u.phone, u.`password`, u.`role`, u.email, u.first_name, u.last_name, u.gender, u.birthday
    INTO phone_old, password_old, role_old, email_old, firstname_old, lastname_old, gender_old, birthday_old
    FROM `User` u WHERE user_id = userid_;
	
	IF (phone_old = NULL OR email_old = NULL OR password_old = NULL)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
    End IF;
    
	UPDATE `User`
    SET
		first_name = CASE 
						WHEN firstname_ IS NULL THEN firstname_old
						ELSE firstname_
					 END,
                    
		last_name = CASE 
						WHEN lastname_ IS NULL THEN lastname_old
						ELSE lastname_
					END,
                    
		gender = 	CASE 
						WHEN gender_ IS NULL THEN gender_old
						ELSE gender_
					END,
                    
		birthday = CASE 
						WHEN birthday_ IS NULL THEN birthday_old
						ELSE birthday_
					END,
                    
		email = 	CASE 
						WHEN email_ IS NULL THEN email_old
						ELSE email_
					END,
                    
		phone = 	CASE 
						WHEN phone_ IS NULL THEN phone_old
						ELSE phone_
					END,
                    
		`password` = CASE 
						WHEN password_ IS NULL THEN password_old
						ELSE password_
					 END, 
                     
		`role` = 	CASE 
						WHEN role_ IS NULL THEN role_old
						ELSE role_
					 END 
	Where user_id = userid_;
    COMMIT;
    
End$$
DELIMITER ;

# CALL UpdateAccount (1000001, '0345678474', 'Altstadt@hubspot.com', 'i87Z8UWYV0x', 3 ,'Adaline', 'Rolofs', 1, '1986-04-11');

#-----------------------------


