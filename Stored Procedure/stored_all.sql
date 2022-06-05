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

# # CALLAccountRegistration ('012345689', 'ABC', 1, 'tyteo1@gmail.com','Nguyen', 'Ty', 1, '2020-3-4', CURDATE());

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

## # CALLLogin ('1111111111', 'AAAAAA', NULL);



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
	IN phone_ char(10),
	IN email_ VARCHAR(40),
	IN password_ char(150),
	IN 	role_ TINYINT,  # 1 là customer, 2 là provider, 3 là shipper
	IN firstname_ nvarchar(50),
	IN lastname_ nvarchar(50),
	IN gender_ TINYINT, # 0 là nữ, 1 là nam 
	IN birthday_ date

)
BEGIN

    
    DECLARE phone_old char(10);
	DECLARE email_old VARCHAR(40);
	DECLARE password_old char(100);
	DECLARE role_old TINYINT;
	DECLARE firstname_old nvarchar(50);
	DECLARE lastname_old nvarchar(50);
	DECLARE gender_old  ENUM('M', 'F');
	DECLARE birthday_old date;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	SELECT u.phone, u.`password`, u.`role`, u.email, u.first_name, u.last_name, u.gender, u.birthday
    INTO phone_old, password_old, role_old, email_old, firstname_old, lastname_old, gender_old, birthday_old
    FROM `User` u WHERE user_id = userid_;
	
    -- 	IF NOT EXISTS (Select Email, Phone From `User` Where (email=email_ or phone=phone_ and `password`=password_) OR user_id = userid_) 
	IF (phone_old = NULL or email_old = NULL or password_old = NULL)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
    End IF;
    

	#select phone_old, password_old, role_old, email_old, firstname_old, lastname_old, gender_old, birthday_old;


	UPDATE `user`
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


## # CALLUpdateAccount (1000000, NULL, NULL, 'BBBBBB', NULL ,'abc', NULL, NULL, NULL);

SELECT * FROM `user` where user_id = 1000001;
#-----------------------------


USE Tastie;

DROP PROCEDURE IF EXISTS UpdateProvider;
DELIMITER $$
Create Procedure UpdateProvider (
	provider_id_ BIGINT,
	status_ TINYINT, #(1 open, 2 closed, 3 busy, -1 lock)
    day_ NVARCHAR(20) , 
    open_time_ TIME, 
    close_time_ TIME, 
    #rush_hour_ TIME,
    estimated_cooking_time_ VARCHAR(50),
    update_at_ TIMESTAMP
)
Begin
-- 	DECLARE temp_status TINYINT;
-- 	SELECT `status` INTO temp_status FROM Provider WHERE provider_id = provider_id_;
-- 	SET status_ = IFNULL(status_, temp_status);
--     END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE  
		IF ISNULL(status_)
		THEN
			SELECT `status` INTO status_ FROM Provider WHERE provider_id = provider_id_;
		END IF;
        
        # insert/update operation
		Insert Into Operation (provider_id, `day`, open_time, close_time, update_at) 
			Values (provider_id_, day_, open_time_,close_time_, update_at_) 
        ON DUPLICATE KEY UPDATE
			provider_id = provider_id, 
            `day` = day_, 
            open_time = open_time_, 
            close_time = close_time_,  
            update_at = update_at_;
		
        UPDATE Provider SET
			status = status_,
			estimated_cooking_time = estimated_cooking_time_,
			update_at = update_at_
        WHERE provider_id = provider_id_;

	END IF;
    COMMIT;
End$$
DELIMITER ;

# # CALLUpdateProvider(1000001, 1, 'Monday', '08:00:00', '020:00:00', '3.4', NOW());
-- # # CALLUpdateProvider(1000001, 1, 'Tuesday', '08:00:00', '020:00:00', '3.4', NOW());



DROP PROCEDURE IF EXISTS Update_Product_Status;

DELIMITER $$
CREATE PROCEDURE Update_Product_Status(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
	 product_status_ TINYINT,  # 0 là lock by admin, 1 là available, 2 là sold out, 3 là lock by provider, -1 là bị xóa
     update_at_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;

	ELSE 
		UPDATE Product SET
			product_status =  product_status_,
			update_at = update_at_
		WHERE product_id = product_id_;
    END IF;
    COMMIT;

End$$
DELIMITER ; 
# # CALLUpdate_Product_Status(1000001, 1000001, 2, NOW());

USE Tastie;



#-------------------------------------------------

#-------------------------------------------------
DROP PROCEDURE IF EXISTS Get_List_Product;

DELIMITER $$
CREATE PROCEDURE Get_List_Product(
	provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		SELECT  m.menu_id, m.name as menu_name, m.position as menu_position,
				p.*, 
				-- fc.food_category_id, fc.food_category_name, 
-- 				mfc.main_food_category_name, mfc.main_food_category_id,
				po.label, po.value, 
				po.price AS ProductOptionPrice, po.option_description, po.is_required AS Option_Required
                
				FROM Product p  LEFT JOIN MenuCategoryDetail md ON p.product_id = md.product_id
						JOIN MenuCategory m ON md.menu_id = m.menu_id
                        
                        -- JOIN FoodCategoryDetail fcd ON p.product_id = fcd.product_id
--                         LEFT JOIN FoodCategory fc ON fcd.food_category_id = fc.food_category_id
--                         
--                         JOIN MainFoodCategoryDetail mfcd ON p.product_id = mfcd.product_id
-- 						JOIN MainFoodCategory mfc ON mfcd.main_food_category_id = mfc.main_food_category_id
                        
                        LEFT JOIN ProductOption po ON  p.product_id = po.product_id
                        
		WHERE p.provider_id = provider_id_;
        
	END IF;
    COMMIT;
End$$
DELIMITER ;

# # CALLget_list_product(1000000);




#-----------------------------------------------------------------------------


#Get food category
# SELECT * FROM FoodCategory;

# Get menu category
DROP PROCEDURE IF EXISTS GetMenuItems;

DELIMITER $$
CREATE PROCEDURE GetMenuItems(
	provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		SELECT * FROM menucategory WHERE provider_id = provider_id_;
        
	END IF;
    COMMIT;
End$$
DELIMITER ;

## # CALLGetMenuItems(1000000);

#-----------------------------------------------------------------------------------
#***
# add product
DROP PROCEDURE IF EXISTS AddProduct;

DELIMITER $$
CREATE PROCEDURE AddProduct(
	provider_id_ BIGINT,
	product_name_ NVARCHAR(90), 
	product_status_ TINYINT,  # -1 là bị xóa, 0 là lock by admin, 1 là available, 2 là sold out, 3 là lock by provider
	`description_` TEXT, 
	price_ INT, 
	quantity_ INT,
	-- menu_id_ INT,
-- 	food_category_id_ INT,
-- 	main_food_category_id_ INT,
-- 	label_ NVARCHAR(100),
-- 	value_ NVARCHAR(100),
-- 	option_price_ INT,
	create_at_ DATE,
	update_at_ TIMESTAMP
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
    ELSE
		INSERT INTO Product (product_name, product_status, `description`, price, 
							quantity, create_at, update_at, provider_id) 
		VALUES (product_name_, product_status_, `description_`, price_ , 
				quantity_, create_at_, update_at_, provider_id_);

-- 		INSERT ProductOption(product_id, label, `value`, price)
-- 			VALUES(product_id_, label_, value_, option_price_)
--         ON DUPLICATE KEY UPDATE
-- 			product_id = product_id_,
-- 			label = label_, 
-- 			`value` = value_,
-- 			price = option_price_;
	END IF;
    COMMIT;
    
End$$
DELIMITER ;

# # CALLAddProduct( 1000000, N'banh trang2', 1,N'ngonn', 100, 20, NOW(), NOW());    


#------
#UPDATE PRODUCT 
DROP PROCEDURE IF EXISTS UpdateProduct;

DELIMITER $$
CREATE PROCEDURE UpdateProduct(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
     product_name_ NVARCHAR(90), 
	 product_status_ TINYINT,  # -1 là bị xóa, 0 là lock by admin, 1 là available, 2 là sold out, 3 là lock by provider
    `description_` TEXT, 
     price_ INT, 
     product_image_ VARCHAR(150),
     quantity_ INT,
     update_at_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 
		UPDATE Product SET
			product_id = product_id_, 
			product_name = product_name_, 
			`description` = `description_`, 
			price = price_, 
            position = 1,
			product_status =  product_status_,
			product_image = product_image_,
			quantity = quantity_, 
			update_at = update_at_
		WHERE product_id = product_id_;
    END IF;
    COMMIT;
    
End$$
DELIMITER ;

## # CALLUpdateProduct(1000000, 1000000, N'banh trang', 1,N'ngonn', 100, product_image, 20, NOW());

#--------------------
# choose main food category (insert/update)
DROP PROCEDURE IF EXISTS Update_Product_Main_Category;
DELIMITER $$
CREATE PROCEDURE Update_Product_Main_Category(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
     main_food_category_id_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 
		IF EXISTS (SELECT * FROM MainFoodCategoryDetail WHERE main_food_category_id = main_food_category_id_ AND product_id = product_id_ )
        THEN
			DELETE FROM MainFoodCategoryDetail WHERE main_food_category_id = main_food_category_id_ AND product_id = product_id_ ;
        END IF;
    
		# choose main food category
        INSERT INTO MainFoodCategoryDetail (main_food_category_id, product_id) 
		VALUES (main_food_category_id_, product_id_)
		ON DUPLICATE KEY UPDATE
		main_food_category_id = main_food_category_id_, 
		product_id = product_id_;
	END IF;
    COMMIT;
    
End$$
DELIMITER ;
# # CALLUpdate_Product_Main_Category(1000000, 1000000, 1000000);



# --------------------------
# choose food category (insert/update)
DROP PROCEDURE IF EXISTS Update_Product_Category;
DELIMITER $$
CREATE PROCEDURE Update_Product_Category(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
     food_category_id_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 
		IF EXISTS (SELECT * FROM FoodCategoryDetail WHERE food_category_id = food_category_id_ AND product_id = product_id_ )
        THEN
			DELETE FROM FoodCategoryDetail WHERE food_category_id = food_category_id_ AND product_id = product_id_ ;
        END IF;
    
		# choose food category
        INSERT INTO FoodCategoryDetail (food_category_id, product_id) 
		VALUES (food_category_id_, product_id_)
		ON DUPLICATE KEY UPDATE
		food_category_id = food_category_id_, 
		product_id = product_id_;
	END IF;
    COMMIT;
    
End$$
DELIMITER ;
## # CALLUpdate_Product_Category(1000000, 1000000, 1000001);

# choose menu category (insert/update)
DROP PROCEDURE IF EXISTS Update_Product_Menu_Category;
DELIMITER $$
CREATE PROCEDURE Update_Product_Menu_Category(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
     menu_id_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 
		# choose menu category
		INSERT INTO MenuCategoryDetail (menu_id, product_id) 
			VALUES (menu_id_, product_id_)
		ON DUPLICATE KEY UPDATE
			menu_id = menu_id_, 
            product_id = product_id_;
	END IF;
    COMMIT;
    
End$$
DELIMITER ;
## # CALLUpdate_Product_Menu_Category(1000000, 1000000, 1000004);





# -------------------------------------------------------------------------------
# insert/update product option
DROP PROCEDURE IF EXISTS Add_Product_Option;
DELIMITER $$
CREATE PROCEDURE Add_Product_Option(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
     label_ NVARCHAR(100),
     value_ NVARCHAR(100),
	 price_ FLOAT,
	 option_description_ NVARCHAR(100), 
	 is_required_ BOOLEAN # 0 là not required, 1 là required
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
	END IF;
    
    IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
    
	ELSE 
		INSERT ProductOption(product_id, label, `value`, price, option_description, is_required)
		VALUES(product_id_, label_, value_, price_, option_description_, is_required_)
        ON DUPLICATE KEY UPDATE
        product_id = product_id_,
        label = label_, 
        `value` = value_,
        price = price_,
		option_description = option_description_,
		is_required = is_required_;
        
	END IF;
    COMMIT;
End$$
DELIMITER ;

# # CALLAdd_Product_Option(1000000, 1000000, 'Size', 'S', 10, 'ngon', 1);
# # CALLAdd_Product_Option(1000000, 1000001, 'Size', 'S', 10, 'ngon', 1);

# # CALLAdd_Product_Option(1000000, 1000000, 'Size', 'S', 20, N'dở', 0);


DROP PROCEDURE IF EXISTS Remove_Product;
DELIMITER $$
CREATE PROCEDURE Remove_Product(
	 #provider_id_ BIGINT,
	 product_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 		
		DELETE FROM MenuCategoryDetail WHERE product_id=product_id_;
		DELETE FROM MainFoodCategoryDetail WHERE product_id=product_id_;
		DELETE FROM FoodCategoryDetail WHERE product_id=product_id_;
		DELETE FROM ProductOption WHERE product_id=product_id_;
        # topping
        
		DELETE FROM Product WHERE product_id=product_id_;
	END IF;
    COMMIT;
End$$
DELIMITER ;

# # CALLRemove_Product(1000000);

##--------------------------------------------------


DROP PROCEDURE IF EXISTS Add_Product_Into_Menu;
DELIMITER $$
CREATE PROCEDURE Add_Product_Into_Menu(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
     menu_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 
		INSERT menucategorydetail(product_id, menu_id)
		VALUES(product_id_, menu_id_)
        ON DUPLICATE KEY UPDATE
		product_id = product_id_,
        menu_id = menu_id_;
        
	END IF;
    COMMIT;
End$$
DELIMITER ;
# # CALLAdd_Product_Into_Menu(1000001,1000003,1000002);



DROP PROCEDURE IF EXISTS Add_Menu_Category;
DELIMITER $$
CREATE PROCEDURE Add_Menu_Category(
	 provider_id_ BIGINT,
     menu_name_ NVARCHAR(100)
	 
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		INSERT INTO MenuCategory (provider_id, `name`, position) VALUES (provider_id_ , menu_name_, 1);  # tạm thời cho position là 1
        
	END IF;
    COMMIT;
End$$
DELIMITER ;

# # CALLAdd_Menu_Category(1000001, 'ngo221nw ngon');

#UPDATE PRODUCT STATUS
DROP PROCEDURE IF EXISTS UpdateProductStatus;

DELIMITER $$
CREATE PROCEDURE UpdateProductStatus(
	 provider_id_ BIGINT,
	 product_id_ BIGINT, 
	 product_status_ TINYINT,  # 0 là lock by admin, 1 là available, 2 là sold out, 3 là lock by provider
     update_at_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	END IF;
	IF NOT EXISTS (Select p.product_id FROM Product p WHERE p.product_id = product_id_)
    THEN
		SET @s1 = 'Error from product ID';
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = @s1;
        
	ELSE 
		UPDATE Product SET
			product_status =  product_status_,
			update_at = update_at_
		WHERE product_id = product_id_;
    END IF;
    COMMIT;
    
End$$
DELIMITER ;


Use Tastie;

DROP PROCEDURE IF EXISTS Get_List_Review;

DELIMITER $$
CREATE PROCEDURE Get_List_Review(
	provider_id_ BIGINT
)

BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (SELECT p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		SELECT o.*, u.first_name, u.last_name, u.avatar FROM OrderReview AS o 
        LEFT JOIN `User` as u 
        ON o.customer_id = u.user_id 
        WHERE p.provider_id = provider_id_;
	END IF;
    COMMIT;
End$$
DELIMITER ;

USE Tastie;
DROP PROCEDURE IF EXISTS Provider_Form_Info;

DELIMITER $$
Create Procedure Provider_Form_Info(
    user_id_ BIGINT
)
Begin
	DECLARE owner_id_ BIGINT;
	DECLARE provider_id_ BIGINT;
    DECLARE current_form_ SMALLINT;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;  -- rollback any changes made in the transaction
		RESIGNAL;  -- raise again the sql exception to the caller
	END;
	START TRANSACTION;
	IF NOT EXISTS (Select user_id FROM `User` u WHERE u.user_id = user_id_)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		SELECT p.provider_id, p.current_form INTO provider_id_, current_form_ FROM `Provider` p WHERE user_id = user_id_;
		SELECT p.owner_id INTO owner_id_ FROM `Provider` p WHERE p.provider_id = provider_id_ AND user_id = user_id_;

			IF current_form_ = 1
				THEN
					SELECT  merchant_name, address, road, hotline, city_id, district_id, ward_id, latitude, longitude
					FROM Provider 
					WHERE provider_id = provider_id_;
				
			ELSEIF current_form_ = 2
				THEN
					SELECT p.merchant_name, p.address, p.road, p.hotline, p.city_id, p.district_id, p.ward_id, p.latitude, p.longitude, 
					o.company_name, o.company_address, o.owner_name, p.tax_code, p.rush_hour,
					o.email, o.owner_phone, o.owner_card_id, o.role, o.create_at, o.update_at, oci.owner_card_image
					FROM Provider p JOIN `Owner` o ON p.owner_id = o.owner_id JOIN ownercardimage oci ON o.owner_id = oci.owner_id
					WHERE p.provider_id = provider_id_ AND p.owner_id = owner_id_;
			
			ELSEIF current_form_ = 3
				THEN
					SELECT 	p.merchant_name, p.address, p.road, p.hotline, p.city_id, p.district_id, p.ward_id, p.latitude, p.longitude, 
							p.keyword, p.description, p.avatar, p.cover_picture, p.facade_photo, p.tax_code,
							o.company_name, o.company_address, o.owner_name, o.email, o.owner_phone, o.owner_card_id, 
							o.role, o.create_at, o.update_at, oci.owner_card_image,
							op.day, op.open_time, op.close_time,
							cc.*, pc.*
							
					FROM Provider p JOIN `Owner` o ON p.owner_id = o.owner_id JOIN ownercardimage oci ON o.owner_id = oci.owner_id 
					JOIN Operation op ON p.provider_id = op.provider_id
					JOIN CuisineCategoryDetail ccd ON p.provider_id = ccd.provider_id JOIN CuisineCategory cc ON ccd.cuisine_category_id = cc.cuisine_category_id
					JOIN ProviderCategoryDetail pcd ON p.provider_id = pcd.provider_id JOIN ProviderCategory pc ON pcd.provider_category_id = pc.provider_category_id
					WHERE p.provider_id = provider_id_ AND p.owner_id = owner_id_;
				
			ELSE # current_form_ = 4
					SELECT 	p.merchant_name, p.address, p.road, p.hotline, p.city_id, p.district_id, p.ward_id, p.latitude, p.longitude, 
							p.keyword, p.description, p.avatar, p.cover_picture, p.facade_photo, p.tax_code, p.price_range,
							o.company_name, o.company_address, o.owner_name, o.email, o.owner_phone, o.owner_card_id, 
							o.role, o.create_at, o.update_at, oci.owner_card_image,
							op.day, op.open_time, op.close_time,
							cc.*, pc.*, mp.menu_image
							
					FROM Provider p JOIN `Owner` o ON p.owner_id = o.owner_id JOIN ownercardimage oci ON o.owner_id = oci.owner_id 
					JOIN Operation op ON p.provider_id = op.provider_id
					JOIN CuisineCategoryDetail ccd ON p.provider_id = ccd.provider_id JOIN CuisineCategory cc ON ccd.cuisine_category_id = cc.cuisine_category_id
					JOIN ProviderCategoryDetail pcd ON p.provider_id = pcd.provider_id JOIN ProviderCategory pc ON pcd.provider_category_id = pc.provider_category_id
					JOIN MenuPhoto mp ON p.provider_id = mp.provider_id
					WHERE p.provider_id = provider_id_ AND p.owner_id = owner_id_;
			END IF;
	END IF;
    COMMIT;
End$$
DELIMITER ;
# # CALLProvider_Form_Info(1000000);


USE TASTIE;

# [customer] Get provider categories 
DROP PROCEDURE IF EXISTS Get_Provider_Categories;

DELIMITER $$
CREATE PROCEDURE Get_Provider_Categories(
	 provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Error from provider ID';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN	
	ELSE 
		SELECT pc.*
        FROM Provider p JOIN ProviderCategoryDetail pd ON p.provider_id = pd.provider_id
						JOIN ProviderCategory pc ON pd.provider_category_id = pc.provider_category_id
		WHERE p.provider_id = provider_id_;
    END IF;
    COMMIT;
    
End$$
DELIMITER ;

# # CALLGet_Provider_Categories(1000001)

USE Tastie;

#ALTER TABLE CartDetail DROP COLUMN update_at;
#ALTER TABLE CartDetail ADD COLUMN item_code VARCHAR(150) NOT NULL;
#alter table CartDetail drop primary key, add primary key(cart_id, product_id, label, `value`, item_code);


# total price
# get cart items
DROP PROCEDURE IF EXISTS Get_Cart_Detail;

DELIMITER $$
CREATE PROCEDURE Get_Cart_Detail(
	user_id_ BIGINT
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
    
	IF NOT EXISTS (Select u.user_id FROM `User` u WHERE u.user_id = user_id_)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
        SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
        
        SELECT p.provider_id, pv.merchant_name, pv.latitude as provider_latitude, pv.longitude as provider_longitude,
        cd.cart_id, cd.product_id, cd.label as label_product_option_in_cart, cd.value as value_product_option_in_cart, 
        cd.quantity as product_quantity_in_cart, cd.special_instruction,
        p.product_name, p.description, p.price as product_price, p.product_image,
        po.price as product_option_price,
        cd.item_code
        FROM CartDetail cd JOIN Product p ON cd.product_id = p.product_id
        JOIN ProductOption po ON cd.product_id = po.product_id AND cd.label LIKE po.label AND cd.value LIKE po.value
        JOIN Provider pv ON p.provider_id = pv.provider_id
        WHERE cd.cart_id = cart_id_;
       #GROUP BY cd.product_id, cd.quantity, cd.special_instruction, cd.update_at;
	END IF;
    COMMIT;
End$$
DELIMITER ;

# # CALLGet_Cart_Detail (1000001);


-- DROP PROCEDURE IF EXISTS Get_Cart_Detail_Tyding_Table;

-- DELIMITER $$
-- CREATE PROCEDURE Get_Cart_Detail_Tyding_Table(
-- 	user_id_ BIGINT
-- )
-- Begin
-- 	DECLARE cart_id_ BIGINT;
--     DECLARE EXIT HANDLER FOR SQLEXCEPTION
--     BEGIN
--         ROLLBACK;  -- rollback any changes made in the transaction
--         RESIGNAL;  -- raise again the sql exception to the # CALLer
--     END;
-- 	START TRANSACTION;
--     
-- 	IF NOT EXISTS (Select u.user_id FROM `User` u WHERE u.user_id = user_id_)
--     THEN
-- 		SET @s = 'Account does not exist';
-- 		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
--         #RETURN
-- 	ELSE 
--         SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
--         
--         DROP TEMPORARY TABLE IF EXISTS temp_cart_item;
--         CREATE TEMPORARY TABLE temp_cart_item 
-- 			SELECT p.provider_id, pv.merchant_name, pv.latitude as provider_latitude, pv.longitude as provider_longitude,
-- 				cd.cart_id, cd.product_id, cd.label as label_product_option_in_cart, cd.value as value_product_option_in_cart, 
-- 				cd.quantity as product_quantity_in_cart, cd.special_instruction,
-- 				p.product_name, p.description, p.price as product_price, p.product_image,
-- 				po.price as product_option_price,
-- 				cd.update_at
-- 			FROM CartDetail cd JOIN Product p ON cd.product_id = p.product_id
-- 				JOIN ProductOption po ON cd.product_id = po.product_id AND cd.label LIKE po.label AND cd.value LIKE po.value
-- 				JOIN Provider pv ON p.provider_id = pv.provider_id
-- 			WHERE cd.cart_id = cart_id_;
-- 		   #GROUP BY cd.product_id, cd.quantity, cd.special_instruction, cd.update_at;
--            
--                    
-- 			SET @sql = NULL;
-- 			SELECT
-- 			  GROUP_CONCAT(DISTINCT
-- 				CONCAT(
-- 				  'MAX(IF(tci.label_product_option_in_cart = ''',
-- 				  label_product_option_in_cart,
-- 				  ''', tci.value_product_option_in_cart, NULL)) AS ',
-- 				  label_product_option_in_cart
-- 				)
-- 			  ) INTO @sql
-- 			FROM temp_cart_item;

-- 			SET @sql = CONCAT('SELECT 	tci.product_id,
-- 										tci.product_name,
-- 										tci.description, tci.merchant_name, tci.provider_latitude, tci.provider_longitude,
-- 										tci.cart_id, tci.product_id, tci.product_quantity_in_cart, tci.special_instruction,
-- 										tci.product_name, tci.description, tci.product_price, tci.product_image,
-- 										tci.product_option_price, tci.update_at,', @sql, ' 
-- 							FROM temp_cart_item tci
-- 							GROUP BY tci.update_at');

-- 			PREPARE stmt FROM @sql;
-- 			EXECUTE stmt;
-- 			DEALLOCATE PREPARE stmt;
-- 	END IF;
--     COMMIT;
-- End$$
-- DELIMITER ;

-- # # CALLGet_Cart_Detail_Tyding_Table (1000009);




#---------------------------------------
-- # insert and update protuduct into cart
DROP PROCEDURE IF EXISTS Insert_Product_Into_Cart;

DELIMITER $$
CREATE PROCEDURE Insert_Product_Into_Cart(
	user_id_ BIGINT,
    product_id_ BIGINT,
	label_ NVARCHAR(100),
    value_ NVARCHAR(100),
    special_instruction_ NVARCHAR(150),
    quantity_ INT,
    item_code_ VARCHAR(150)
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
        
        INSERT CartDetail(cart_id, product_id, label, value, special_instruction, quantity, item_code) VALUES
        (cart_id_, product_id_, label_, value_, special_instruction_, quantity_, item_code_);
		COMMIT;
End$$
DELIMITER ;

START TRANSACTION;
# # CALLInsert_Product_Into_Cart (1000001, 1000005, 'Size', 'XL', 'abc', 2, '2');
# # CALLInsert_Product_Into_Cart (1000001, 1000005, 'Egg', 'Yes', 'abc', 2, '2');
# # CALLInsert_Product_Into_Cart (1000001, 1000005, 'Rong Biển', 'Yes', 'abc', 12, '1');
# # CALLInsert_Product_Into_Cart (1000001, 1000005, 'Sườn Thêm', 'Yes', 'abc', 2, '1');
COMMIT;

# ----------------------------------------
-- # delete protuduct into cart
DROP PROCEDURE IF EXISTS Delete_ProDuct_Into_Cart;

DELIMITER $$
CREATE PROCEDURE Delete_ProDuct_Into_Cart(
	user_id_ BIGINT,
    product_id_ BIGINT,

	item_code_ VARCHAR(150)
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
    
	IF NOT EXISTS (Select u.user_id FROM `User` u WHERE u.user_id = user_id_)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
        SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
        DELETE FROM CartDetail WHERE cart_id = cart_id_ AND item_code = item_code_ AND product_id = product_id_;
	END IF;
    COMMIT;
End$$
DELIMITER ;
# # CALLDelete_Product_Into_Cart (1000001, 1000000, '1');

#---------------------------------------
-- # update prouduct into cart (special_instruction, quantity)
DROP PROCEDURE IF EXISTS Update_Qty_Note_Product_Into_Cart;

DELIMITER $$
CREATE PROCEDURE Update_Qty_Note_Product_Into_Cart(
	user_id_ BIGINT,
    product_id_ BIGINT,
    special_instruction_ NVARCHAR(150),
    quantity_ INT,
    item_code_ VARCHAR(150)
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
		
        IF (quantity_ = 0)
        THEN
			-- DELETE FROM CartDetail 
--             WHERE cart_id = cart_id_ AND item_code = item_code_ AND product_id = product_id_ AND label = label_ AND value = value_;		
			CALL Delete_Product_Into_Cart (cart_id_, user_id_, item_code_);
		ELSE 		
			UPDATE CartDetail SET
				special_instruction = special_instruction_, 
				quantity = quantity_
	--             label = label_,
	--             value = value_,
	--             item_code = item_code_,
	--             product_id = product_id_,
	--             cart_id = cart_id_
			#WHERE cart_id = cart_id_ AND  product_id = product_id_ AND label = label_ AND value = value_ AND update_at = pre_update_at;
			WHERE cart_id = cart_id_ AND item_code = item_code_ AND product_id = product_id_;
		END IF;
		COMMIT;
End$$
DELIMITER ;
# # CALLUpdate_Qty_Note_Product_Into_Cart (1000001, 1000005,'mình muion61 ướng nước', 111, '2');

#---------------------------------------
-- # update prouduct into cart (value of product option: vd M, L, XL ... )
DROP PROCEDURE IF EXISTS Update_Additional_Opt_Product_Into_Cart;

DELIMITER $$
CREATE PROCEDURE Update_Additional_Opt_Product_Into_Cart(
	user_id_ BIGINT,
    product_id_ BIGINT,
	label_ NVARCHAR(100),
	value_ NVARCHAR(100),
    item_code_ VARCHAR(150)
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
		UPDATE CartDetail SET
			`value` = value_
        WHERE cart_id = cart_id_ AND item_code = item_code_ AND product_id = product_id_ AND label = label_;
		COMMIT;
End$$
DELIMITER ;
# # CALLUpdate_Additional_Opt_Product_Into_Cart (1000001, 1000005, 'Size', 'L', '2');


#---------------------------------------
-- # update prouduct into cart (Size, Sugar, ...)
DROP PROCEDURE IF EXISTS Update_Label_Product_Into_Cart;

DELIMITER $$
CREATE PROCEDURE Update_Label_Product_Into_Cart(
	user_id_ BIGINT,
    product_id_ BIGINT,
	label_ NVARCHAR(100),
	value_ NVARCHAR(100),
    item_code_ VARCHAR(150),
    `type` TINYINT
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE special_instruction_ NVARCHAR(150);
    DECLARE quantity_ INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;        
		SELECT cart_id INTO cart_id_  FROM Cart Where user_id = user_id_;
		SELECT MAX(quantity) INTO quantity_  FROM CartDetail Where cart_id = cart_id_ AND product_id = product_id_ AND item_code = item_code_;
		SELECT MAX(special_instruction) INTO special_instruction_  FROM CartDetail Where cart_id = cart_id_ AND product_id = product_id_ AND item_code = item_code_;

        IF (`type` = 1)
        THEN
			INSERT CartDetail(cart_id, product_id, label, value, quantity, special_instruction, item_code) VALUES
			(cart_id_, product_id_, label_, value_, quantity_, special_instruction_, item_code_);        
		ELSE # type = 2
			DELETE FROM CartDetail 
            WHERE cart_id = cart_id_ AND item_code = item_code_ AND product_id = product_id_ AND label = label_ AND value = value_;
		END IF;
		COMMIT;
End$$
DELIMITER ;
# # CALLUpdate_Label_Product_Into_Cart(1000001, 1000005, N'Rong Biển', 'Yes', '2', 2);




USE Tastie;

#-------------------------------------------------
### INSERT Shop 
## bổ sung user_zô insert luôn  -> done
DROP PROCEDURE IF EXISTS ProviderUpdate_Form0;

DELIMITER $$
CREATE PROCEDURE ProviderUpdate_Form0(
	user_id_ BIGINT,
	registered_at_ TIMESTAMP, 
	update_at_ TIMESTAMP
)
Begin
	DECLARE owner_id_ BIGINT;
    DECLARE provider_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
    
	IF NOT EXISTS (Select u.user_id FROM `User` u WHERE u.user_id = user_id_)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
        
		Insert Into `Provider` (user_id, registered_at, update_at) 
        Values (user_id_, registered_at_, update_at_)
        ON DUPLICATE KEY UPDATE
		user_id = user_id_, 
        registered_at = registered_at_, 
        update_at = update_at_;
        
		SELECT p.provider_id INTO provider_id_ FROM `Provider` p 
        WHERE p.user_id = user_id_ AND p.update_at = update_at_;

		INSERT INTO `Owner` (update_at, owner_card_id)
        VALUES (update_at_, provider_id_)
        ON DUPLICATE KEY UPDATE
        update_at = update_at_,
        owner_card_id = provider_id_;
        
        SELECT owner_id INTO owner_id_ FROM `Owner` o WHERE o.owner_card_id = provider_id_ AND o.update_at = update_at;
        UPDATE Provider SET
        owner_id = owner_id_
        WHERE provider_id = provider_id_;

	END IF;
    COMMIT;
End$$
DELIMITER ;

# # # CALLProviderUpdate_Form0(1000000, NOW(), NOW());
#-------------------------------------------------
#form 1
DROP PROCEDURE IF EXISTS ProviderUpdate_Form1;
DELIMITER $$
Create Procedure ProviderUpdate_Form1 (
	provider_id_ BIGINT,
	merchant_name_ NVARCHAR(120),
    address_ NVARCHAR(150),
    road_ NVARCHAR(100),
    hotline_ VARCHAR(12),
    city_id_ INT,
    district_id_ INT, 
    ward_id_ INT,
	latitude_ VARCHAR(20), 
    longitude_ VARCHAR(20),
    registered_at_ TIMESTAMP,
    update_at_ TIMESTAMP
)

Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		UPDATE Provider SET
			merchant_name = merchant_name_,
			address = address_,
			road = road_,
			hotline = hotline,
			city_id = city_id_ ,
			district_id = district_id_ ,
			ward_id = ward_id_ ,
			latitude = latitude_ ,
			longitude = longitude_,
            registered_at = registered_at_,
            update_at = update_at_,
            current_form = 1
		WHERE provider_id = provider_id_;
		
	END IF;
    COMMIT;
End$$
DELIMITER ;

# # # CALLProviderUpdate_Form1(1000000, N'Shop của Trung', N'227 NVC, Px, Q5, TPHCM', 'NVC','123456', 3, 4, 22, 324332,323432, NOW(), NOW());


#----------------------------------------------------------------------------------------------------
# viết chung 1 form cho 2 loại owner
# form 2
DROP PROCEDURE IF EXISTS ProviderUpdate_Form2;

DELIMITER $$
Create Procedure ProviderUpdate_Form2(
	provider_id_ BIGINT,
    company_name_ NVARCHAR(150),
    company_address_ NVARCHAR(150), 
	owner_name_ NVARCHAR(100), 
    email_ VARCHAR(90),
	owner_phone_ VARCHAR(12), 
    owner_card_id_ VARCHAR(20),
    role_ TINYINT,  # đổi thành register_as
	create_at_ TIMESTAMP, 
    update_at_ TIMESTAMP,
    owner_card_image1 VARCHAR(120), #image
	owner_card_image2 VARCHAR(120), #image
    tax_code_ VARCHAR(50)
)
Begin
	DECLARE owner_id_ BIGINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF EXISTS (Select o.owner_card_id FROM `Owner` o WHERE o.owner_card_id = owner_card_id_)
    THEN
		SET @s = 'Owner already exists';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		Insert Into `Owner` (owner_name, email, owner_phone, owner_card_id, `role`,create_at, update_at) 
        Values (owner_name_, email_, owner_phone_, owner_card_id_, role_ ,create_at_, update_at_)
        ON DUPLICATE KEY UPDATE
        owner_name = owner_name_, 
        email = email_, 
        owner_phone = owner_phone_, 
        owner_card_id = owner_card_id_, 
        `role` = role_,
        update_at = update_at_;
        
		SELECT o.owner_id INTO owner_id_ 
		FROM `owner` o
		WHERE o.owner_card_id = owner_card_id_ AND o.update_at = update_at_;
        
        
        #insert image
        Insert Into `OwnerCardImage` (owner_id, owner_card_image) 
        Values  (owner_id_, owner_card_image1),
				(owner_id_, owner_card_image2);
        
        
        # update provider info
        UPDATE Provider 
        SET owner_id = owner_id_, current_form = 2, tax_code = tax_code_, update_at = update_at_
        WHERE provider_id = provider_id_;

	END IF;
    COMMIT;
End$$
DELIMITER ;

# # # CALLProviderUpdate_Form2(1000000,N'CTTNHH 1 ','227NVC',N'Shop của Trunggg3', 'email3','21331223','2d32f113223', 1,NOW(), NOW(),'image1', 'image2', '123');
#--------------------------------------------------------------------------------------------------

#form 3 (get provider_categories)
DROP PROCEDURE IF EXISTS Get_Provider_Categories;
DELIMITER $$
Create Procedure Get_Provider_Categories ()
BEGIN
    SELECT * FROM ProviderCategory;
End$$
DELIMITER ;

# ## # # CALLGet_Provider_Categories();

#form 3 (get cuisine_categories)
DROP PROCEDURE IF EXISTS Get_Cuisine_Categories;
DELIMITER $$
Create Procedure Get_Cuisine_Categories ()
BEGIN
	
    SELECT * FROM CuisineCategory;
    
End$$
DELIMITER ;

# ## # # CALLGet_Cuisine_Categories();

-- #form 3 (main)
DROP PROCEDURE IF EXISTS ProviderUpdate_Form3;

DELIMITER $$
Create Procedure ProviderUpdate_Form3 (
# provider
	provider_id_ BIGINT,
	keyword_ NVARCHAR(120), 
    description_ NVARCHAR(200),
    avatar_ VARCHAR(120), 
    cover_picture_ VARCHAR(120), 
    facade_photo_ VARCHAR(120), 
    
# operation
    day_ NVARCHAR(20) , 
    open_time_ TIME, 
    close_time_ TIME, 
    rush_hour_ TIME, # provider
	create_at_ TIMESTAMP, 
    update_at_ TIMESTAMP
    #delete_at DATE
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
        # update provider info in form 3
        UPDATE Provider SET 
        keyword = keyword_, 
        `description` = description_, 
        avatar = avatar_, 
        cover_picture = cover_picture_, 
        facade_photo = facade_photo_,
		rush_hour = rush_hour_,
        update_at = update_at_,
        current_form = 3
        WHERE provider_id = provider_id_;
            
        # insert operation
		Insert Into Operation (provider_id, `day`, open_time, close_time, create_at, update_at) 
			Values (provider_id_, day_, open_time_,close_time_,create_at_, update_at_) 
        ON DUPLICATE KEY UPDATE
			provider_id = provider_id, 
            `day` = day_, 
            open_time = open_time_, 
            close_time = close_time_,  
			create_at = create_at_, 
            update_at = update_at_;
	END IF;
    COMMIT;
End$$
DELIMITER ;

#provider_category/ cuisine_category
# # # CALLProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Monday', '08:00:00', '020:00:00', '16:00:00', NOW(), NOW());
# # # CALLProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Tuseday', '01:20:00', '23:00:00', '19:00:00', NOW(), NOW());
# # # CALLProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Wednesday', '00:00:00', '00:00:00', '00:00:00', NOW(), NOW());
# # # CALLProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Sunday', '00:00:00', '00:00:00', '10:00:00', NOW(), NOW());

# choose cuisine category
DROP PROCEDURE IF EXISTS Update_CuisineCategory_Form3;
DELIMITER $$
Create Procedure Update_CuisineCategory_Form3 (
	provider_id_ BIGINT,
	cuisine_category_id_ INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		IF EXISTS (SELECT * FROM CuisineCategoryDetail WHERE cuisine_category_id = cuisine_category_id_ AND provider_id = provider_id_)
        THEN
			DELETE FROM CuisineCategoryDetail WHERE cuisine_category_id = cuisine_category_id_ AND provider_id = provider_id_;
        END IF;
		#Chose to cuisine_category
		INSERT INTO CuisineCategoryDetail(cuisine_category_id, provider_id)
			VALUES (cuisine_category_id_, provider_id_)
        ON DUPLICATE KEY UPDATE
			cuisine_category_id = cuisine_category_id_,
			provider_id = provider_id_;
		
	END IF;
    COMMIT;
End$$
DELIMITER ;
# # # CALL Update_CuisineCategory_Form3(1000000, 1000001);
# # # CALL Update_CuisineCategory_Form3(1000000, 1000002);
## # # CALL Update_CuisineCategory_Form3(1000000, 1000003);


# choose Provider category
DROP PROCEDURE IF EXISTS Update_ProviderCategory_Form3;
DELIMITER $$
Create Procedure Update_ProviderCategory_Form3 (
	provider_id_ BIGINT,
	provider_category_id_ INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		IF EXISTS (SELECT * FROM ProviderCategoryDetail WHERE provider_category_id = provider_category_id_ AND provider_id = provider_id_)
        THEN
			DELETE FROM ProviderCategoryDetail WHERE provider_category_id = provider_category_id_ AND provider_id = provider_id_;
        END IF;
    
        #Chose to provider_category
		INSERT INTO ProviderCategoryDetail(provider_category_id, provider_id)
			VALUES (provider_category_id_, provider_id_)
		ON DUPLICATE KEY UPDATE
			provider_category_id = provider_category_id_,
			provider_id = provider_id_;
	END IF;
	COMMIT;
End$$
DELIMITER ;

# # # CALL Update_ProviderCategory_Form3(1000000, 1000001);
# # # CALL Update_ProviderCategory_Form3(1000000, 1000002);
## # # CALL Update_ProviderCategory_Form3(1000000, 1000003);


#----------------------------------------------------------------
# form 4 (main)
DROP PROCEDURE IF EXISTS ProviderUpdate_Form4;

DELIMITER $$
Create Procedure ProviderUpdate_Form4 (
	provider_id_ BIGINT,
	price_range_ INT,   # đổi thành VARCHAR
    menu_image_ VARCHAR(120),
    delivery_mode_ TINYINT,
	update_at_ TIMESTAMP
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		UPDATE Provider SET
        price_range = price_range_, current_form = 4, delivery_mode = delivery_mode_, update_at = update_at_
        WHERE provider_id = provider_id_;
        
        INSERT INTO MenuPhoto(provider_id, menu_image) VALUES
        (provider_id_, menu_image_) 
        ON DUPLICATE KEY UPDATE
        menu_image = menu_image_,
        provider_id = provider_id_;
        
	END IF;
	COMMIT;
End$$
DELIMITER ;
# # # CALLProviderUpdate_Form4(1000000, 2000, 'abc', 2, NOW());

#-------------------------------------------------------------
-- #form 5 (main)
DROP PROCEDURE IF EXISTS ProviderUpdate_Form5;

DELIMITER $$
Create Procedure ProviderUpdate_Form5 (
	provider_id_ BIGINT,
	bank_id_card_number_ NVARCHAR(30),
    date_of_issue_ DATE,
    bank_beneficiary_name_ NVARCHAR(120),
    bank_account_number_ VARCHAR(30),
    bank_name_ NVARCHAR(90),
    bank_province_ NVARCHAR(50),
    bank_branch_ NVARCHAR(60),
    user_role_ TINYINT,   # 1 là customer, 2 là provider, 3 là shipper
	update_at_ TIMESTAMP

)
BEGIN
	DECLARE user_id_ BIGINT;
    DECLARE owner_id_ BIGINT;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (Select p.provider_id FROM Provider p WHERE p.provider_id = provider_id_)
    THEN
		SET @s = 'Provider does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
        #RETURN
	ELSE 
		SELECT user_id INTO user_id_ FROM Provider WHERE provider_id = provider_id_;
		UPDATE `user` SET `role` = user_role_
        WHERE user_id = user_id_;
        
        SELECT p.owner_id INTO owner_id_ FROM `Provider` p WHERE p.provider_id = provider_id_ AND user_id = user_id_;
        
		UPDATE `Owner` SET
			bank_id_card_number = bank_id_card_number_, 
			date_of_issue = date_of_issue_ ,
			bank_beneficiary_name = bank_beneficiary_name_,
			bank_account_number = bank_account_number_, 
			bank_name = bank_name_, 
			bank_province = bank_province_, 
			bank_branch = bank_branch_ 
		WHERE owner_id = owner_id_;
        
		UPDATE Provider SET current_form = 5, update_at = update_at_ WHERE provider_id = provider_id_;
	END IF;
	COMMIT;
End$$
DELIMITER ;

# # # CALLProviderUpdate_Form5(1000000, '213123','2024-3-5','abc','abc','abc','abc','abc', 2, NOW());

USE TASTIE;

# [Customer] get_customer_contact (for checkout)

DROP PROCEDURE IF EXISTS Get_Customer_Contact;

DELIMITER $$
CREATE PROCEDURE Get_Customer_Contact(
	 user_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
    
	SELECT u.user_id, u.phone, ca.address, ca.longitude, ca.latitude FROM `user` u 
    JOIN customeraddress ca ON u.user_id = ca.customer_id 
	WHERE ca.customer_id = user_id_;

    COMMIT;
    
End$$
DELIMITER ;

-- # # CALLGet_Customer_Contact(1000000);

# [Provider Detail Screen]

# [Provider Detail Screen] / order check out / prder detail
DROP PROCEDURE IF EXISTS Get_All_Promos;
DELIMITER $$
CREATE PROCEDURE Get_All_Promos(
	 provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT * 
		FROM promotion 
		WHERE promotion.provider_id = provider_id_ AND start_at < NOW() AND expire_at > NOW()
		ORDER BY min_order_value ASC;
    COMMIT;

End$$
DELIMITER ;

# CALL Get_All_Promos(1000001); 


DROP PROCEDURE IF EXISTS Get_All_Ecoupon;
DELIMITER $$
CREATE PROCEDURE Get_All_Ecoupon(
	 provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	SELECT * FROM ecoupon as ec join ecouponproviderdetail as ecp on ec.ecoupon_id = ecp.ecoupon_id
    WHERE ecp.provider_id = provider_id_ AND start_date < NOW() AND expire_date > NOW()
    ORDER BY min_order_value ASC;
    COMMIT;

-- # # CALLGet_All_Promos(1000001); 
-- # # CALLGet_All_Ecoupon(1000001); 

# [Admin] Create ecoupon
DROP PROCEDURE IF EXISTS Add_Ecoupon;

DELIMITER $$
CREATE PROCEDURE Add_Ecoupon(
	ecoupon_code_ VARCHAR(30),
    ecoupon_name_ NVARCHAR(50),
	ecoupon_value_ FLOAT,
    ecoupon_description_ NVARCHAR(200),
    min_order_value_ FLOAT,
    max_discount_value_ FLOAT,
	start_date_ TIMESTAMP,
    expire_date_ TIMESTAMP,
    payment_method_id_ TINYINT,
    limited_offer_ INT,
    weekly_usage_limit_per_user_ TINYINT,
    delivery_mode_ TINYINT
)
Begin
	DECLARE ecoupon_status_ TINYINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        SET ecoupon_status_ = 1;
        INSERT INTO Ecoupon(ecoupon_code, ecoupon_name, ecoupon_value, ecoupon_description, 
        min_order_value, max_discount_value, start_date, expire_date, payment_method_id,
        limited_offer, weekly_usage_limit_per_user, delivery_mode, ecoupon_status) 
        VALUES (ecoupon_code_, ecoupon_name_, ecoupon_value_, ecoupon_description_, 
        min_order_value_, max_discount_value_, start_date_, expire_date_, payment_method_id_,
        limited_offer_, weekly_usage_limit_per_user_, delivery_mode_, ecoupon_status_);
	COMMIT;
End$$
DELIMITER ;

# CALLAdd_Ecoupon("SALEOFF10USD", "Sale off 10 USD", 50, "Maximum 10 USD off on total amount", 20, 10, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 1, 1);
# CALLAdd_Ecoupon("SALEOFF20USD", "Sale off 20 USD", 50, "Maximum 20 USD off on total amount", 80, 20, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 1, 1);
# CALLAdd_Ecoupon("SALEOFF25USD", "Sale off 25 USD", 50, "Maximum 25 USD off on total amount", 100, 25, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 1, 1);

# [Admin] Update ecoupon
DROP PROCEDURE IF EXISTS Update_Ecoupon;

DELIMITER $$
CREATE PROCEDURE Update_Ecoupon(
	ecoupon_id_ BIGINT,
	ecoupon_code_ VARCHAR(30),
    ecoupon_name_ NVARCHAR(50),
	ecoupon_value_ FLOAT,
    ecoupon_description_ NVARCHAR(200),
    min_order_value_ FLOAT,
    max_discount_value_ FLOAT,
	start_date_ TIMESTAMP,
    expire_date_ TIMESTAMP,
    payment_method_id_ TINYINT,
    limited_offer_ INT,
    weekly_usage_limit_per_user_ TINYINT,
    delivery_mode_ TINYINT,
    update_at_ TIMESTAMP
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        UPDATE Ecoupon
        SET 
			ecoupon_code = ecoupon_code_, 
			ecoupon_name = ecoupon_name_,
			ecoupon_value = ecoupon_value_, 
			ecoupon_description = ecoupon_description_, 
			min_order_value = min_order_value_, 
			max_discount_value = max_discount_value_, 
			start_date = start_date_, 
			expire_date = expire_date_, 
			payment_method_id = payment_method_id_,
			limited_offer = limited_offer_, 
			weekly_usage_limit_per_user = weekly_usage_limit_per_user_, 
			delivery_mode = delivery_mode_,
			update_at = update_at_
        WHERE ecoupon_id = ecoupon_id_;
	COMMIT;
End$$
DELIMITER ;

# CALLUpdate_Ecoupon(1, "SALEOFF5USD", "Sale off 5 USD", 50, "Maximum 5 USD off on total amount", 10, 5, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 2, 1, CURRENT_TIMESTAMP());

# Provider register ecoupon 

# [Provider] Add promotion
DROP PROCEDURE IF EXISTS Add_Promotion;

DELIMITER $$
CREATE PROCEDURE Add_Promotion(
	provider_id_ BIGINT,
	promotion_code_ VARCHAR(30),
    promotion_name_ NVARCHAR(50),
	promotion_value_ FLOAT,
    promotion_description_ NVARCHAR(200),
    min_order_value_ FLOAT,
    max_discount_value_ FLOAT,
	start_at_ TIMESTAMP,
    expire_at_ TIMESTAMP,
    payment_method_id_ TINYINT,
    limited_offer_ INT,
    weekly_usage_limit_per_user_ TINYINT,
    delivery_mode_ TINYINT
)
Begin
	DECLARE promotion_status_ TINYINT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        SET promotion_status_ = 1;
        INSERT INTO Promotion(provider_id, promotion_code, promotion_name, promotion_value, 
        promotion_description, min_order_value, max_discount_value, start_at, expire_at, 
        payment_method_id, limited_offer, weekly_usage_limit_per_user, delivery_mode, 
        promotion_status) 
        VALUES (provider_id_, promotion_code_, promotion_name_, promotion_value_, 
        promotion_description_, min_order_value_, max_discount_value_, start_at_, 
        expire_at_, payment_method_id_, limited_offer_, weekly_usage_limit_per_user_, 
        delivery_mode_, promotion_status_);
	COMMIT;
End$$
DELIMITER ;

# CALLAdd_Promotion(1000000, "FREESHIP", "Sale off 2 USD", 0, "2 USD off on shipping fee", 20, 2, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 5, 1);
# CALLAdd_Promotion(1000001, "SALEOFF10USD", "Sale off 10 USD", 50, "Maximum 10 USD off on total amount", 50, 10, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 2, 1);

# [Provider] Update promotion
DROP PROCEDURE IF EXISTS Update_Promotion;

DELIMITER $$
CREATE PROCEDURE Update_Promotion(
	promotion_id_ BIGINT,
	provider_id_ BIGINT,
	promotion_code_ VARCHAR(30),
    promotion_name_ NVARCHAR(50),
	promotion_value_ FLOAT,
    promotion_description_ NVARCHAR(200),
    min_order_value_ FLOAT,
    max_discount_value_ FLOAT,
	start_at_ TIMESTAMP,
    expire_at_ TIMESTAMP,
    payment_method_id_ TINYINT,
    limited_offer_ INT,
    weekly_usage_limit_per_user_ TINYINT,
    delivery_mode_ TINYINT, 
    update_at_ TIMESTAMP
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
    UPDATE Promotion
        SET 
			provider_id = provider_id_,
			promotion_code = promotion_code_, 
			promotion_name = promotion_name_,
			promotion_value = promotion_value_, 
			promotion_description = promotion_description_, 
			min_order_value = min_order_value_, 
			max_discount_value = max_discount_value_, 
			start_at = start_at_, 
			expire_at = expire_at_, 
			payment_method_id = payment_method_id_,
			limited_offer = limited_offer_, 
			weekly_usage_limit_per_user = weekly_usage_limit_per_user_, 
			delivery_mode = delivery_mode_,
			update_at = update_at_
        WHERE promotion_id = promotion_id_ AND provider_id = provider_id_;
	COMMIT;
End$$
DELIMITER ;

# CALLUpdate_Promotion(2, 1000000, "FREESHIP", "Sale off 3 USD", 0, "3 USD off on shipping fee", 20, 3, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 4, 1, CURRENT_TIMESTAMP());

# [Provider] Insert upcoming product information
DROP PROCEDURE IF EXISTS Add_Upcoming_Product;

DELIMITER $$
CREATE PROCEDURE Add_Upcoming_Product(
	provider_id_ BIGINT,
    product_name_ NVARCHAR(50),
    product_description_ NVARCHAR(200),
    estimated_price_ FLOAT,
    product_image_ VARCHAR(300)
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		INSERT INTO UpcomingProduct(provider_id, product_name, product_description, estimated_price,
        product_image)
        VALUES(provider_id_, product_name_, product_description_, estimated_price_, product_image_);
	COMMIT;
End$$
DELIMITER ; 

# CALLAdd_Upcoming_Product(1000001, "Shaka Poke Bowl", "Salmon and tuna with burnt onion crisps, cucumbers, scallions, masago, edamame, seaweed salad, sesame seeds, and Shaka Poke sauce with your choice of base", 16.75, "https://d1ralsognjng37.cloudfront.net/9dfd40c0-0c83-41d0-a592-fafed9e348c5.jpeg");
# CALLAdd_Upcoming_Product(1000000, "Gochujang Salmon & Tuna Bowl", "Salmon and tuna with cucumbers, mango, edamame, masago, kani salad, jalapeno, and burnt onion crisps with Gochujang Chili Sauce and your choice of base",16.75, "https://d1ralsognjng37.cloudfront.net/2628c878-e3e5-499a-b88b-e3f64a9d2666.jpeg");
# CALLAdd_Upcoming_Product(1000002, "Two Spam Musubi", "A very popular Hawaiian snack and great for kids. Two pieces of grilled spam. Served as sushi with furikake rice and nori.", 8.4, "https://d1ralsognjng37.cloudfront.net/1848ae7b-7ed0-4001-ab4d-b42da8092924.jpeg");
# CALLAdd_Upcoming_Product(1000003, "Grilled Haloumi Pita", "Grilled haloumi with lettuce, tomatoes, cucumber, onions, and your choice of sauce wrapped in a pita", 9.45, "https://d1ralsognjng37.cloudfront.net/3527d305-b23c-4884-bd94-1367eebc3822.jpeg");
# CALLAdd_Upcoming_Product(1000004, "California Breakfast Quesarito", "A Quesarito, California style. Carne asada, scrambled eggs, tater tots, melted cheese, avocado, and sour cream wrapped up in a quesadilla.", 10.5, "https://d1ralsognjng37.cloudfront.net/c6ebb0df-e86f-4fcd-9c40-d575df55e4aa.jpeg");
# CALLAdd_Upcoming_Product(1000005, "Ichibantei Steak", "Juicy prime Angus ribeye steak. Served with rice and salad.", 25, "https://d1ralsognjng37.cloudfront.net/ac8a110a-eb41-47a7-9b92-96fa2dd97409.jpeg");
# CALLAdd_Upcoming_Product(1000001, "Loaded Bacon Tots", "Tater tots with zesty truffle aioli and bacon crumble", 9.09, "https://tb-static.uber.com/prod/image-proc/processed_images/146a14e37b8812cb9db857ce81f84b52/859baff1d76042a45e319d1de80aec7a.jpeg");
# CALLAdd_Upcoming_Product(1000000, "Beef Birria Ramen", "10 Hour Slow Simmered Beef Birria ramen. Served with boiled eggs, radish, pickled onion, scallions, cilantro",14.79, "https://tb-static.uber.com/prod/image-proc/processed_images/3271411ef2d04544fa53fbce6d8cd453/859baff1d76042a45e319d1de80aec7a.jpeg");
# CALLAdd_Upcoming_Product(1000002, "Bread Pudding", "Delicious, soft, and spongey pudding mixed with cake, bread, or cookies. 8 oz", 6.49, "https://tb-static.uber.com/prod/image-proc/processed_images/54cd53919ff838c56c98e8859edf6be4/859baff1d76042a45e319d1de80aec7a.jpeg");
# CALLAdd_Upcoming_Product(1000003, "Chicken ＆ Shrimp Hibachi", "Our signature duet of hibachi chicken ＆ shrimp with mixed vegetables. Served with rice.", 18.29, "https://tb-static.uber.com/prod/image-proc/processed_images/594b7f2fccb1c44536d8af013082e3fd/859baff1d76042a45e319d1de80aec7a.jpeg");

# [Provider] Update upcoming product
DROP PROCEDURE IF EXISTS Update_Upcoming_Product;

DELIMITER $$
CREATE PROCEDURE Update_Upcoming_Product(
	upcoming_product_id_ INT,
	provider_id_ BIGINT,
    product_name_ NVARCHAR(50),
    product_description_ NVARCHAR(200),
    estimated_price_ FLOAT,
    product_image_ VARCHAR(300),
    update_at_ TIMESTAMP
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
        IF NOT EXISTS (Select up.upcoming_product_id FROM UpcomingProduct up WHERE up.upcoming_product_id = upcoming_product_id_)
		THEN
			SET @s = 'Product does not exist';
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
			#RETURN
		ELSE 
			UPDATE UpcomingProduct SET
			product_name = product_name_, 
			product_description = product_description_, 
			estimated_price = estimated_price_,
			product_image = product_image_,
			update_at = update_at_
			WHERE provider_id = provider_id_ AND upcoming_product_id = upcoming_product_id_;
		END IF;
    COMMIT;
End$$
DELIMITER ; 

# CALLAdd_Upcoming_Product(1000001, "Galbi Combo", "BBQ short rib. Served with an assorted soon tofu.", 31.49, "");
# CALLUpdate_Upcoming_Product(14, 1000001, "Galbi Combo", "BBQ short rib. Served with an assorted soon tofu.", 31.49, "https://d1ralsognjng37.cloudfront.net/1384fa4b-5a82-47a8-9676-26d3ec957e29.jpeg", current_timestamp());

# [Provider] Add survey
DROP PROCEDURE IF EXISTS Add_Survey_Question;

DELIMITER $$
CREATE PROCEDURE Add_Survey_Question(
	provider_id_ BIGINT,
	upcoming_product_id_ INT,
    question_ NVARCHAR(200),
    start_at_ TIMESTAMP,
    expire_at_ TIMESTAMP
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		IF NOT EXISTS (Select up.upcoming_product_id FROM UpcomingProduct up WHERE up.upcoming_product_id = upcoming_product_id_)
		THEN
			SET @s = 'Product does not exist';
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
			#RETURN
		ELSE 
			INSERT INTO Survey(provider_id, upcoming_product_id, question, start_at, expire_at)
			VALUES(provider_id_, upcoming_product_id_, question_, start_at_, expire_at_);
		END IF;
	COMMIT;
End$$
DELIMITER ; 

# # CALLAdd_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00");

# [Provider] Update survey response
DROP PROCEDURE IF EXISTS Add_Survey_Choices;

DELIMITER $$
CREATE PROCEDURE Add_Survey_Choices(
	survey_id_ INT,
    choice_ NVARCHAR(200)
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		IF NOT EXISTS (Select s.survey_id FROM Survey s WHERE s.survey_id = survey_id_)
		THEN
			SET @s = 'Survey does not exist';
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
			#RETURN
		ELSE
			INSERT INTO SurveyDetail(survey_id, choice)
            VALUES(survey_id_, choice_);
		END IF;
	COMMIT;
End$$
DELIMITER ; 


# https://stackoverflow.com/questions/18883601/function-to-calculate-distance-between-two-coordinates
# https://stackoverflow.com/questions/19412462/getting-distance-between-two-points-based-on-latitude-longitude

USE TASTIE;


# get all provider near by ...
DROP PROCEDURE IF EXISTS Get_All_Provider;

DELIMITER $$
CREATE PROCEDURE Get_All_Provider(
	 user_id_ BIGINT
--     user_longitude VARCHAR (50),
--     user_latitude VARCHAR (50)
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
	-- IF NOT EXISTS (Select u.user_id FROM `User` u WHERE u.user_id = user_id_)
--     THEN
-- 		SET @s = 'User is not true';
-- 		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
--         #RETURN
-- 	END IF;
--     IF ISNULL(user_longitude) AND ISNULL(user_latitude)
--     THEN
--      	SELECT longitude INTO user_longitude FROM CustomerAddress ca WHERE ca.customer_id = user_id_ LIMIT 1;
--  		SELECT latitude INTO user_latitude FROM CustomerAddress ca WHERE ca.customer_id = user_id_ LIMIT 1;
-- 	END IF;
		
	SELECT * FROM Provider;
	
    COMMIT;
End$$
DELIMITER ;
# # CALLGet_All_Provider();

#----------------------------


USE TASTIE;

# [Customer] get_customer_contact (for checkout)

DROP PROCEDURE IF EXISTS Get_Customer_Contact;

DELIMITER $$
CREATE PROCEDURE Get_Customer_Contact(
	 user_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
    
	SELECT u.user_id, u.phone, ca.address, ca.longitude, ca.latitude FROM `user` u 
    JOIN customeraddress ca ON u.user_id = ca.customer_id 
	WHERE ca.customer_id = user_id_;

    COMMIT;
    
End$$
DELIMITER ;

-- CALL Get_Customer_Contact(1000000);

# [Provider Detail Screen] / order check out / prder detail
DROP PROCEDURE IF EXISTS Get_All_Promos;
DELIMITER $$
CREATE PROCEDURE Get_All_Promos(
	 provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	SELECT * FROM promotion WHERE promotion.provider_id = provider_id_ AND start_at < NOW() AND expire_at > NOW();

    COMMIT;

End$$
DELIMITER ;

DROP PROCEDURE IF EXISTS Get_All_Ecoupon;
DELIMITER $$
CREATE PROCEDURE Get_All_Ecoupon(
	 provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;

	SELECT * FROM ecoupon as ec join ecouponproviderdetail as ecp on ec.ecoupon_id = ecp.ecoupon_id
    where ecp.provider_id = provider_id_ AND start_date < NOW() AND expire_date > NOW();
    COMMIT;
End$$
DELIMITER ;

CALL Get_All_Promos(1000001); 
CALL Get_All_Ecoupon(1000001); 

#=================================Place Order=============================================
# chưa có shipper_id
# delivery mode là delivery
# chỉ dc áp dụng 1 trong 2 (nếu chọn promotion_code thì ko dc chọn ecoupon_code và ngược lại)
DROP PROCEDURE IF EXISTS Submit_Basic_Info_Order_Delivery;
DELIMITER $$
CREATE PROCEDURE  Submit_Basic_Info_Order_Delivery(
     delivery_mode_ TINYINT,   # 1: Delivery, 2: pickup. trong stored này mặc định truyền 1 
 	 order_code_ VARCHAR(60),
     user_id_ BIGINT,
	 customer_address_ NVARCHAR(250),
     customer_phone_ VARCHAR(10),
     payment_id_ TINYINT, # 1 là cash, 2 là momo, ...
     payment_status_ TINYINT, #1: chưa thanh toán, 2: đã thanh toán 
     promotion_code_ VARCHAR(30), # P .... 
     ecoupon_code_ VARCHAR(30), # E .... 
     delivery_method_id_ TINYINT, # 1: standard/ 2: schedule
     schedule_time_ VARCHAR(50),  # # delivery_method_id_ = 1 thì field này là NULL, 2 thì là khoảng thời gian ngta nhập
	 tip_ FLOAT,
     delivery_fee_ FLOAT,
     subtotal_ FLOAT, 
     total_amount_ FLOAT
)
Begin
	DECLARE promotion_id_ BIGINT;
	DECLARE ecoupon_id_ BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT promotion_id INTO promotion_id_ FROM Promotion WHERE promotion_code = promotion_code_;
		SELECT ecoupon_id INTO ecoupon_id_ FROM Ecoupon WHERE ecoupon_code = ecoupon_code_;
        
        IF delivery_method_id_ = 2 # 2: schedule
        THEN 
			INSERT INTO `Order` (customer_id, payment_id, order_code, payment_status_id, promotion_id, ecoupon_id, customer_address, 
			customer_phone, delivery_method_id, delivery_fee, tip, subtotal, total_amount, delivery_mode, schedule_time)
			VALUES (user_id_, payment_id_, order_code_, payment_status_, promotion_id_, ecoupon_id_, customer_address_, 
			customer_phone_, delivery_method_id_, delivery_fee_, tip_, subtotal_, total_amount_, delivery_mode_, schedule_time_);
		ELSE  # 1: standard
			INSERT INTO `Order` (customer_id, payment_id, order_code, payment_status_id, promotion_id, ecoupon_id, customer_address, 
			customer_phone, delivery_method_id, delivery_fee, tip, subtotal, total_amount, delivery_mode)
			VALUES (user_id_, payment_id_, order_code_, payment_status_, promotion_id_, ecoupon_id_, customer_address_, 
			customer_phone_, delivery_method_id_, delivery_fee_, tip_, subtotal_, total_amount_, delivery_mode_);
		END IF;
    COMMIT;
End$$
DELIMITER ; 
# phần tử thứ 8 nếu là 1 thì cái thứ 9 truyền NULL
# 	.................	2 thì truyền cái khoảng thời gian người ta đặt 
CALL Submit_Basic_Info_Order_Delivery(1, '123', 1000005, '227 NVC, Px, Q5, TPHCM', '012345678', 1, 1, 'P-FREESHIP', NULL, 1, NULL, 2, 3, 10, 122);


# chưa có shipper_id
# delivery mode là pick up
# chỉ dc áp dụng 1 trong 2 (nếu chọn promotion_code thì ko dc chọn ecoupon_code và ngược lại)
DROP PROCEDURE IF EXISTS Submit_Basic_Info_Order_Pickup;
DELIMITER $$
CREATE PROCEDURE  Submit_Basic_Info_Order_Pickup(
	 delivery_mode_ TINYINT,   # 1: Delivery, 2: pickup. trong stored này mặc định truyền 2
 	 order_code_ VARCHAR(60),
     user_id_ BIGINT,
     payment_id_ TINYINT, # 1 là cash, 2 là momo, ...
     payment_status_ TINYINT, #1: chưa thanh toán, 2: đã thanh toán 
     promotion_code_ VARCHAR(30),
     ecoupon_code_ VARCHAR(30),
	 delivery_method_id_ TINYINT, # 1: standard/ 2: schedule
     schedule_time_ VARCHAR(50),  # delivery_method_id_ = 1 thì field này là NULL, 2 thì là khoảng thời gian ngta nhập
     subtotal_ FLOAT, 
     total_amount_ FLOAT
)
Begin
	DECLARE promotion_id_ BIGINT;
	DECLARE ecoupon_id_ BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT promotion_id INTO promotion_id_ FROM Promotion WHERE promotion_code = promotion_code_;
		SELECT ecoupon_id INTO ecoupon_id_ FROM Ecoupon WHERE ecoupon_code = ecoupon_code_;
		IF delivery_method_id_ = 2
        THEN
			INSERT INTO `Order` (customer_id, payment_id, order_code, payment_status_id, promotion_id, ecoupon_id,
			delivery_method_id, subtotal, total_amount, delivery_mode, schedule_time)
			VALUES (user_id_, payment_id_, order_code_, payment_status_, promotion_id_, ecoupon_id_,
			delivery_method_id_, subtotal_, total_amount_, delivery_mode_, schedule_time_);
		ELSE
			INSERT INTO `Order` (customer_id, payment_id, order_code, payment_status_id, promotion_id, ecoupon_id,
			delivery_method_id, subtotal, total_amount, delivery_mode)
			VALUES (user_id_, payment_id_, order_code_, payment_status_, promotion_id_, ecoupon_id_,
			delivery_method_id_, subtotal_, total_amount_, delivery_mode_);
		END IF;
        
    COMMIT;
End$$
DELIMITER ;
CALL Submit_Basic_Info_Order_Pickup(2, '1223', 1000005,  1, 1, NULL, NULL, 2, '4/7/2022 20:00:00', 10, 122);


DROP PROCEDURE IF EXISTS Submit_Order_Delivery_Items;
DELIMITER $$
CREATE PROCEDURE  Submit_Order_Delivery_Items(
	 user_id_ BIGINT,
 	 order_code_ VARCHAR(60)
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE order_id_ BIGINT;
--     DECLARE quantity_ INT;
--     DECLARE special_instruction_ NVARCHAR(150) DEFAULT '';
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT cart_id INTO cart_id_ FROM Cart WHERE user_id = user_id_;
        SELECT order_id INTO order_id_ FROM `Order` WHERE order_code = order_code_;
		INSERT INTO OrderDetail (order_id, product_id, label, `value`, quantity, special_instruction, item_code)
		SELECT order_id_, cd.product_id, cd.label, cd.value, cd.quantity, cd.special_instruction, order_id_
		FROM CartDetail cd;
        INSERT INTO OrderStatus (order_id, update_at, order_status_name) VALUES(order_id_, NOW(), 1);
    COMMIT;
End$$
DELIMITER ;

CALL Submit_Order_Delivery_Items(1000005, '123');

# -------------------
# sau khi place order => xóa các item trong cart đã dc chuyển qua order
# set order_status = 1
DROP PROCEDURE IF EXISTS Delete_Items_From_CartDetail;
DELIMITER $$
CREATE PROCEDURE  Delete_Items_From_CartDetail(
	 user_id_ BIGINT
)
Begin
	DECLARE cart_id_ BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT cart_id INTO cart_id_ FROM Cart WHERE user_id = user_id_;
		DELETE FROM CartDetail WHERE cart_id = cart_id_;
        
        # UPDATE OrderStatus SET order_status_name = 1, update_at = NOW() WHERE order_id = order_id_;  
        COMMIT;
End$$
DELIMITER ;

CALL Delete_Items_From_CartDetail(1000005);

DROP PROCEDURE IF EXISTS Get_Order_Summary;
DELIMITER $$
CREATE PROCEDURE  Get_Order_Summary(
	 order_code_ BIGINT
)
Begin
    DECLARE order_id_ BIGINT;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT order_id INTO order_id_ FROM `Order` WHERE order_code = order_code_;
		SELECT o.order_code, o.delivery_fee, o.tip, o.subtotal, o.total_amount, o.customer_phone, o.customer_address, 
        p.payment_name, pr.*, e.*, os.*
        FROM `order` o
        JOIN OrderStatus os ON o.order_id = os.order_id
        JOIN Payment p ON o.payment_id = p.payment_id
        LEFT JOIN Promotion pr ON o.promotion_id = pr.promotion_id
        LEFT JOIN Ecoupon e ON o.ecoupon_id = e.ecoupon_id
        WHERE o.order_id = order_id_;
	COMMIT;
End$$
DELIMITER ;

CALL Get_Order_Summary('123');

DROP PROCEDURE IF EXISTS Get_All_Products_From_Order;
DELIMITER $$
CREATE PROCEDURE  Get_All_Products_From_Order(
	 order_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT od.*,
        p1.product_name, p1.price, p1.product_image, COUNT(od.order_id) AS num_items, p2.merchant_name
        FROM OrderDetail od
        JOIN Product p1 ON od.product_id = p1.product_id 
        JOIN Provider p2 ON p1.provider_id = p2.provider_id
        WHERE od.order_id = order_id_;
	COMMIT;
End$$
DELIMITER ;

CALL Get_All_Products_From_Order(11);

DROP PROCEDURE IF EXISTS Get_Order_History_By_Customer;
DELIMITER $$
CREATE PROCEDURE Get_Order_History_By_Customer(
	 customer_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT o.order_id, o.order_code, o.total_amount, COUNT(od.order_id) AS num_items, p2.merchant_name,
        p2.address, p2.avatar, os.update_at, os.order_status_name
        FROM `Order` o
        JOIN OrderDetail od ON o.order_id = od.order_id
        JOIN OrderStatus os ON o.order_id = os.order_id
        JOIN Product p1 ON od.product_id = p1.product_id
        JOIN Provider p2 ON p1.provider_id = p2.provider_id
        WHERE o.customer_id = customer_id_ AND (os.order_status_name = 5 OR os.order_status_name = 6);
	COMMIT;
End$$
DELIMITER ;

CALL Get_Order_History_By_Customer(1000005);


# [system]
DROP PROCEDURE IF EXISTS Get_Shipper_Info;
DELIMITER $$
CREATE PROCEDURE Get_Shipper_Info(
	 shipper_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT s.first_name, s.last_name, s.phone_number, s.license_plate, s.avatar
        FROM Shipper s
        WHERE s.shipper_id = shipper_id_;
	COMMIT;
End$$
DELIMITER ;
-- ----------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS Update_Order_Status;
DELIMITER $$
CREATE PROCEDURE Update_Order_Status(
	 order_id_ BIGINT,
     status_ TINYINT, #1: Submitted, 2: Assigned, 3: Confirmed, 4: Picked, 5: Completed, 6: Canceled
     shipper_id_ BIGINT, #status = 3, 4, 5 => shipper_id_ = null
     update_at_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
     IF NOT EXISTS (SELECT o.order_id FROM `Order` o WHERE o.order_id = order_id_) THEN
			SET @s = 'Order does not exist';
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
			#RETURN
	 ELSE
		IF status_ = 2 THEN # customer mới place order và tìm dc shipper cho order đó.
			UPDATE `Order` SET shipper_id = shipper_id_ WHERE order_id = order_id_;
		END IF;
		INSERT INTO OrderStatus (order_id, update_at, order_status_name) VALUES (order_id_, update_at_, status_);        
	END IF;
	COMMIT;
End$$
DELIMITER ;

CALL Update_Order_Status(11, 5, NULL, NOW());