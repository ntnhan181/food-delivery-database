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

-- CALL Get_Provider_Categories(1000001);

# [customer] Add address
DROP PROCEDURE IF EXISTS Add_Customer_Address;
DELIMITER $$
CREATE PROCEDURE Add_Customer_Address(
	 customer_id_ BIGINT,
     address_ VARCHAR(150),
     city_ VARCHAR(35),
     type_ TINYINT,
     longitude_ VARCHAR(50),
     latitude_ VARCHAR(50)
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		INSERT INTO CustomerAddress(customer_id, address, city, `type`, longitude, latitude)
        VALUES(customer_id_, address_, city_, type_, longitude_, latitude_);
    COMMIT;
    
End$$
DELIMITER ;

-- CALL Add_Customer_Address(1000001, '277 Nguyen Van Cu, Ward 4, District 5', 'Ho Chi Minh', 3, '106.6827237020004', '10.76237118021896');

# [customer] Update address
DROP PROCEDURE IF EXISTS Update_Customer_Address;
DELIMITER $$
CREATE PROCEDURE Update_Customer_Address(
	 customer_id_ BIGINT,
     address_ VARCHAR(150),
     city_ VARCHAR(35),
     type_ TINYINT,
     longitude_ VARCHAR(50),
     latitude_ VARCHAR(50)
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		UPDATE CustomerAddress SET
        address = address_, 
        city = city_, 
        `type` = type_, 
        longitude = longitude_, 
        latitude = latitude_
	WHERE customer_id = customer_id_;
    COMMIT;
    
End$$
DELIMITER ;

-- CALL Update_Customer_Address(1000001, '277 Nguyen Van Cu, Ward 4, District 5', 'Ho Chi Minh', 1, '106.6827237020004', '10.76237118021896');

DROP PROCEDURE IF EXISTS Add_To_Favorite;
DELIMITER $$
CREATE PROCEDURE Add_To_Favorite(
	user_id_ BIGINT,
    provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		INSERT INTO FavoriteRestaurant(customer_id, provider_id) 
        VALUES(user_id_, provider_id_);
    COMMIT;
    
End$$
DELIMITER ;
-- CALL Add_To_Favorite(1000001, 1000000);

DROP PROCEDURE IF EXISTS Remove_From_Favorite;
DELIMITER $$
CREATE PROCEDURE Remove_From_Favorite(
	user_id_ BIGINT,
    provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		DELETE FROM FavoriteRestaurant
        WHERE customer_id = user_id_ AND provider_id = provider_id_;
    COMMIT;
End$$
DELIMITER ;
-- CALL Remove_From_Favorite(1000001, 1000000);

DROP PROCEDURE IF EXISTS Get_Favorite_Restaurant_By_Customer;
DELIMITER $$
CREATE PROCEDURE Get_Favorite_Restaurant_By_Customer(
	user_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT fr.provider_id FROM FavoriteRestaurant fr
        WHERE customer_id = user_id_;
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Favorite_Restaurant_By_Customer(1000001);

DROP PROCEDURE IF EXISTS Get_Provider_By_Ecoupon;
DELIMITER $$
CREATE PROCEDURE Get_Provider_By_Ecoupon(
	ecoupon_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT p.provider_id, p.merchant_name, p.longitude, p.latitude, p.estimated_cooking_time, 
        p.`status`, p.rating, p.avatar, p.price_range FROM EcouponProviderDetail epd 
        JOIN Provider p ON epd.provider_id = p.provider_id 
        WHERE epd.ecoupon_id = ecoupon_id_;
    COMMIT;
End$$
DELIMITER ;

DROP PROCEDURE IF EXISTS Get_Order_To_Rate;
DELIMITER $$
CREATE PROCEDURE Get_Provider_By_Ecoupon(
	ecoupon_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT p.provider_id, p.merchant_name, p.longitude, p.latitude, p.estimated_cooking_time, 
        p.`status`, p.rating, p.avatar, p.price_range FROM EcouponProviderDetail epd 
        JOIN Provider p ON epd.provider_id = p.provider_id 
        WHERE epd.ecoupon_id = ecoupon_id_;
    COMMIT;
End$$
DELIMITER ;