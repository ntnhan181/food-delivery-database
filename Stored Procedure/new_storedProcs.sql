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
    
	SELECT u.user_id, u.phone, ca.address, ca.longitude, ca.latitude FROM `User` u 
    JOIN Customeraddress ca ON u.user_id = ca.customer_id 
	WHERE ca.customer_id = user_id_;

    COMMIT;
    
End$$
DELIMITER ;

-- CALL Get_Customer_Contact(1000000);

# [Provider Detail Screen]

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

	SELECT * FROM promotion WHERE promotion.provider_id = provider_id_;

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
    where ecp.provider_id = provider_id_;

    COMMIT;

End$$
DELIMITER ;

-- CALL Get_All_Promos(1000001); 
-- CALL Get_All_Ecoupon(1000001); 

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

CALL Add_Ecoupon("SALEOFF10USD", "Sale off 10 USD", 50, "Maximum 10 USD off on total amount", 20, 10, 
"2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 1, 1);
CALL Add_Ecoupon("SALEOFF20USD", "Sale off 20 USD", 50, "Maximum 20 USD off on total amount", 80, 20, 
"2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 1, 1);
CALL Add_Ecoupon("SALEOFF25USD", "Sale off 25 USD", 50, "Maximum 25 USD off on total amount", 100, 25, 
"2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 1, 1);

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

CALL Update_Ecoupon(1, "SALEOFF5USD", "Sale off 5 USD", 50, "Maximum 5 USD off on total amount", 
10, 5, "2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 2, 1, CURRENT_TIMESTAMP());

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

CALL Add_Promotion(1000000, "FREESHIP", "Sale off 2 USD", 0, "2 USD off on shipping fee", 20, 2, 
"2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 5, 1);
CALL Add_Promotion(1000001, "SALEOFF10USD", "Sale off 10 USD", 50, "Maximum 10 USD off on total amount", 50, 10, 
"2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 2, 1);

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

CALL Update_Promotion(2, 1000000, "FREESHIP", "Sale off 3 USD", 0, "3 USD off on shipping fee", 20, 3, 
"2022-03-31 12:00:00", "2022-04-30 12:00:00", 1, 300, 4, 1, CURRENT_TIMESTAMP());






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

CALL Add_Upcoming_Product(1000001, "Shaka Poke Bowl", "Salmon and tuna with burnt onion crisps, cucumbers, scallions, masago, edamame, seaweed salad, sesame seeds, and Shaka Poke sauce with your choice of base", 
16.75, "https://d1ralsognjng37.cloudfront.net/9dfd40c0-0c83-41d0-a592-fafed9e348c5.jpeg");
CALL Add_Upcoming_Product(1000000, "Gochujang Salmon & Tuna Bowl", "Salmon and tuna with cucumbers, mango, edamame, masago, kani salad, jalapeno, and burnt onion crisps with Gochujang Chili Sauce and your choice of base",
16.75, "https://d1ralsognjng37.cloudfront.net/2628c878-e3e5-499a-b88b-e3f64a9d2666.jpeg");
CALL Add_Upcoming_Product(1000002, "Two Spam Musubi", "A very popular Hawaiian snack and great for kids. Two pieces of grilled spam. Served as sushi with furikake rice and nori.", 
8.4, "https://d1ralsognjng37.cloudfront.net/1848ae7b-7ed0-4001-ab4d-b42da8092924.jpeg");
CALL Add_Upcoming_Product(1000003, "Grilled Haloumi Pita", "Grilled haloumi with lettuce, tomatoes, cucumber, onions, and your choice of sauce wrapped in a pita", 
9.45, "https://d1ralsognjng37.cloudfront.net/3527d305-b23c-4884-bd94-1367eebc3822.jpeg");
CALL Add_Upcoming_Product(1000004, "California Breakfast Quesarito", "A Quesarito, California style. Carne asada, scrambled eggs, tater tots, melted cheese, avocado, and sour cream wrapped up in a quesadilla.", 
10.5, "https://d1ralsognjng37.cloudfront.net/c6ebb0df-e86f-4fcd-9c40-d575df55e4aa.jpeg");
CALL Add_Upcoming_Product(1000005, "Ichibantei Steak", "Juicy prime Angus ribeye steak. Served with rice and salad.", 
25, "https://d1ralsognjng37.cloudfront.net/ac8a110a-eb41-47a7-9b92-96fa2dd97409.jpeg");
CALL Add_Upcoming_Product(1000001, "Loaded Bacon Tots", "Tater tots with zesty truffle aioli and bacon crumble", 
9.09, "https://tb-static.uber.com/prod/image-proc/processed_images/146a14e37b8812cb9db857ce81f84b52/859baff1d76042a45e319d1de80aec7a.jpeg");
CALL Add_Upcoming_Product(1000000, "Beef Birria Ramen", "10 Hour Slow Simmered Beef Birria ramen. Served with boiled eggs, radish, pickled onion, scallions, cilantro",
14.79, "https://tb-static.uber.com/prod/image-proc/processed_images/3271411ef2d04544fa53fbce6d8cd453/859baff1d76042a45e319d1de80aec7a.jpeg");
CALL Add_Upcoming_Product(1000002, "Bread Pudding", "Delicious, soft, and spongey pudding mixed with cake, bread, or cookies. 8 oz", 
6.49, "https://tb-static.uber.com/prod/image-proc/processed_images/54cd53919ff838c56c98e8859edf6be4/859baff1d76042a45e319d1de80aec7a.jpeg");
CALL Add_Upcoming_Product(1000003, "Chicken ＆ Shrimp Hibachi", "Our signature duet of hibachi chicken ＆ shrimp with mixed vegetables. Served with rice.", 
18.29, "https://tb-static.uber.com/prod/image-proc/processed_images/594b7f2fccb1c44536d8af013082e3fd/859baff1d76042a45e319d1de80aec7a.jpeg");

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

CALL Add_Upcoming_Product(1000001, "Galbi Combo", "BBQ short rib. Served with an assorted soon tofu.", 
31.49, "");
CALL Update_Upcoming_Product(14, 1000001, "Galbi Combo", "BBQ short rib. Served with an assorted soon tofu.", 
31.49, "https://d1ralsognjng37.cloudfront.net/1384fa4b-5a82-47a8-9676-26d3ec957e29.jpeg", current_timestamp());

-- ALTER TABLE Survey ADD UNIQUE ProviderHasUpcomingProduct (provider_id, upcoming_product_id);

# [Provider] Add survey
DROP PROCEDURE IF EXISTS Add_Survey_Question;

DELIMITER $$
CREATE PROCEDURE Add_Survey_Question(
	provider_id_ BIGINT,
	upcoming_product_id_ INT,
    question_ NVARCHAR(200),
    start_at_ TIMESTAMP,
    expire_at_ TIMESTAMP,
	choice_ NVARCHAR(200)
)
Begin
	DECLARE survey_id_ INT;
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
			VALUES(provider_id_, upcoming_product_id_, question_, start_at_, expire_at_)
            ON DUPLICATE KEY UPDATE
            provider_id = provider_id_, 
            upcoming_product_id = upcoming_product_id_, 
            question = question_, 
            start_at = start_at_, 
            expire_at = expire_at_;
            
			SELECT survey_id INTO survey_id_ FROM survey WHERE provider_id = provider_id_ 
			AND upcoming_product_id = upcoming_product_id_ ;
             
            INSERT INTO SurveyDetail(survey_id, choice) 
            VALUES (survey_id_, choice_);
--             ON DUPLICATE KEY UPDATE
--             survey_id = survey_id_, 
--             choice = choice_;
		END IF;
	COMMIT;
End$$
DELIMITER ; 

CALL Add_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00", 'Absolutely yes! I cannot wait to try this!');
CALL Add_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00", 'It seems good. I am curious about its favor.');
CALL Add_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00", 'Neutral. I am not sure.');
CALL Add_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00", 'I am not interested.');
CALL Add_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00", 'It is not my thing!');
CALL Add_Survey_Question(1000000, 2, "Are you eager to try this product?", "2022-04-01 15:00:00", "2022-04-30 15:00:00", 'Other');


DROP PROCEDURE IF EXISTS Update_Survey_Question_Choice;

DELIMITER $$
CREATE PROCEDURE Update_Survey_Question_Choice(
	provider_id_ BIGINT,
	upcoming_product_id_ INT,
    question_ NVARCHAR(200),
    start_at_ TIMESTAMP,
    expire_at_ TIMESTAMP,
	choice_ NVARCHAR(200)
)
Begin
	DECLARE survey_id_ INT;
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
			VALUES(provider_id_, upcoming_product_id_, question_, start_at_, expire_at_)
            ON DUPLICATE KEY UPDATE
            provider_id = provider_id_, 
            upcoming_product_id = upcoming_product_id_, 
            question = question_, 
            start_at = start_at_, 
            expire_at = expire_at_;
            
			SELECT survey_id INTO survey_id_ FROM survey WHERE provider_id = provider_id_ 
			AND upcoming_product_id = upcoming_product_id_ ;
             
            INSERT INTO SurveyDetail(survey_id, choice) 
            VALUES (survey_id_, choice_);
--             ON DUPLICATE KEY UPDATE
--             survey_id = survey_id_, 
--             choice = choice_;
		END IF;
	COMMIT;
End$$
DELIMITER ; 

