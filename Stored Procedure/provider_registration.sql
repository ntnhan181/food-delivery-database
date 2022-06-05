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

# CALL ProviderUpdate_Form0(1000001, NOW(), NOW());
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

# CALL ProviderUpdate_Form1(1000001, N'Shop của Trung', N'227 NVC, Px, Q5, TPHCM', 'NVC','123456', 3, 4, 22, 324332,323432, NOW(), NOW());


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

# BUG ERROR SYNTAX
# CALL ProviderUpdate_Form2(1000000,N'CTTNHH 1 ','227NVC',N'Shop của Trunggg3', 'email3','21331223','2d32f113223', 1,NOW(), NOW(),'image1', 'image2', '123');
#--------------------------------------------------------------------------------------------------

#form 3 (get provider_categories)
DROP PROCEDURE IF EXISTS Get_Provider_Categories;
DELIMITER $$
Create Procedure Get_Provider_Categories ()
BEGIN
    SELECT * FROM ProviderCategory;
End$$
DELIMITER ;

# CALL Get_Provider_Categories();

#form 3 (get cuisine_categories)
DROP PROCEDURE IF EXISTS Get_Cuisine_Categories;
DELIMITER $$
Create Procedure Get_Cuisine_Categories ()
BEGIN
	
    SELECT * FROM CuisineCategory;
    
End$$
DELIMITER ;

# ## CALL Get_Cuisine_Categories();

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
# CALL ProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Monday', '08:00:00', '020:00:00', '16:00:00', NOW(), NOW());
# CALL ProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Tuseday', '01:20:00', '23:00:00', '19:00:00', NOW(), NOW());
# CALL ProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Wednesday', '00:00:00', '00:00:00', '00:00:00', NOW(), NOW());
# CALL ProviderUpdate_Form3 (1000000, N'Đẹp,hay lắm', N'tuyệt zời', 'abc', 'abc', 'abc', 'Sunday', '00:00:00', '00:00:00', '10:00:00', NOW(), NOW());

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
# CALL  Update_CuisineCategory_Form3(1000000, 1000001);
# CALL  Update_CuisineCategory_Form3(1000000, 1000002);
## CALL  Update_CuisineCategory_Form3(1000000, 1000003);


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

# CALL  Update_ProviderCategory_Form3(1000000, 1000001);
# CALL  Update_ProviderCategory_Form3(1000000, 1000002);
# CALL  Update_ProviderCategory_Form3(1000000, 1000003);


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
# CALL ProviderUpdate_Form4(1000000, 2000, 'abc', 2, NOW());

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

# CALL ProviderUpdate_Form5(1000000, '213123','2024-3-5','abc','abc','abc','abc','abc', 2, NOW());

