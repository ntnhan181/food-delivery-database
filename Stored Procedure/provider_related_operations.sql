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

-- CALL UpdateProvider(1000001, 1, 'Monday', '08:00:00', '020:00:00', '3.4', NOW());
-- CALL UpdateProvider(1000001, 1, 'Tuesday', '08:00:00', '020:00:00', '3.4', NOW());



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
-- CALL Update_Product_Status(1000047, 1000000, 2, NOW());

# ===============================================provider promotion===============================

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

# CALL Add_Promotion(1000000, 'P_FREESHIP1', 'Sale off 2 USD', 0, '2 USD off on shipping fee', 20, 2, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 5, 1);
# CALL Add_Promotion(1000001, 'P_SALEOFF10USD1', 'Sale off 10 USD', 50, 'Maximum 10 USD off on total amount', 50, 10, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 2, 1);

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

-- CALL Update_Promotion(3, 1000000, 'P_FREESHIP', 'Sale off 3 USD', 0, '3 USD off on shipping fee', 20, 3, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 4, 1, CURRENT_TIMESTAMP());

# ========================================UPCOMMING PRODUCT================================================

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

-- CALL Add_Upcoming_Product(1000001, 'Shaka Poke Bowl', 'Salmon and tuna with burnt onion crisps, cucumbers, scallions, masago, edamame, seaweed salad, sesame seeds, and Shaka Poke sauce with your choice of base', 16.75, 'https://d1ralsognjng37.cloudfront.net/9dfd40c0-0c83-41d0-a592-fafed9e348c5.jpeg');
-- CALL Add_Upcoming_Product(1000000, 'Gochujang Salmon & Tuna Bowl', 'Salmon and tuna with cucumbers, mango, edamame, masago, kani salad, jalapeno, and burnt onion crisps with Gochujang Chili Sauce and your choice of base',16.75, 'https://d1ralsognjng37.cloudfront.net/2628c878-e3e5-499a-b88b-e3f64a9d2666.jpeg');
-- CALL Add_Upcoming_Product(1000002, 'Two Spam Musubi', 'A very popular Hawaiian snack and great for kids. Two pieces of grilled spam. Served as sushi with furikake rice and nori.', 8.4, 'https://d1ralsognjng37.cloudfront.net/1848ae7b-7ed0-4001-ab4d-b42da8092924.jpeg');
-- CALL Add_Upcoming_Product(1000003, 'Grilled Haloumi Pita', 'Grilled haloumi with lettuce, tomatoes, cucumber, onions, and your choice of sauce wrapped in a pita', 9.45, 'https://d1ralsognjng37.cloudfront.net/3527d305-b23c-4884-bd94-1367eebc3822.jpeg');
-- CALL Add_Upcoming_Product(1000004, 'California Breakfast Quesarito', 'A Quesarito, California style. Carne asada, scrambled eggs, tater tots, melted cheese, avocado, and sour cream wrapped up in a quesadilla.', 10.5, 'https://d1ralsognjng37.cloudfront.net/c6ebb0df-e86f-4fcd-9c40-d575df55e4aa.jpeg');
-- CALL Add_Upcoming_Product(1000005, 'Ichibantei Steak', 'Juicy prime Angus ribeye steak. Served with rice and salad.', 25, 'https://d1ralsognjng37.cloudfront.net/ac8a110a-eb41-47a7-9b92-96fa2dd97409.jpeg');
-- CALL Add_Upcoming_Product(1000001, 'Loaded Bacon Tots', 'Tater tots with zesty truffle aioli and bacon crumble', 9.09, 'https://tb-static.uber.com/prod/image-proc/processed_images/146a14e37b8812cb9db857ce81f84b52/859baff1d76042a45e319d1de80aec7a.jpeg');
-- CALL Add_Upcoming_Product(1000000, 'Beef Birria Ramen', '10 Hour Slow Simmered Beef Birria ramen. Served with boiled eggs, radish, pickled onion, scallions, cilantro',14.79, 'https://tb-static.uber.com/prod/image-proc/processed_images/3271411ef2d04544fa53fbce6d8cd453/859baff1d76042a45e319d1de80aec7a.jpeg');
-- CALL Add_Upcoming_Product(1000002, 'Bread Pudding', 'Delicious, soft, and spongey pudding mixed with cake, bread, or cookies. 8 oz', 6.49, 'https://tb-static.uber.com/prod/image-proc/processed_images/54cd53919ff838c56c98e8859edf6be4/859baff1d76042a45e319d1de80aec7a.jpeg');
-- CALL Add_Upcoming_Product(1000003, 'Chicken ＆ Shrimp Hibachi', 'Our signature duet of hibachi chicken ＆ shrimp with mixed vegetables. Served with rice.', 18.29, 'https://tb-static.uber.com/prod/image-proc/processed_images/594b7f2fccb1c44536d8af013082e3fd/859baff1d76042a45e319d1de80aec7a.jpeg');

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

-- CALL Add_Upcoming_Product(1000001, 'Galbi Combo', 'BBQ short rib. Served with an assorted soon tofu.', 31.49, '');
-- CALL Update_Upcoming_Product(11, 1000001, 'Galbi Combo', 'BBQ short rib. Served with an assorted soon tofu.', 31.49, 'https://d1ralsognjng37.cloudfront.net/1384fa4b-5a82-47a8-9676-26d3ec957e29.jpeg', current_timestamp());
DROP PROCEDURE IF EXISTS Get_Upcoming_Products_By_Provider;
DELIMITER $$
CREATE PROCEDURE Get_Upcoming_Products_By_Provider(
	provider_id_ BIGINT
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		SELECT up.* FROM UpcomingProduct up WHERE up.provider_id = provider_id_;
    COMMIT;
End$$
DELIMITER ; 

CALL Get_Upcoming_Products_By_Provider(1000003);

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
            
			SELECT survey_id INTO survey_id_ FROM Survey WHERE provider_id = provider_id_ 
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

-- CALL Add_Survey_Question(1000000, 2, 'Are you eager to try this product?', '2022-04-01 15:00:00', '2022-04-30 15:00:00', 'Absolutely yes! I cannot wait to try this!');
-- CALL Add_Survey_Question(1000000, 2, 'Are you eager to try this product?', '2022-04-01 15:00:00', '2022-04-30 15:00:00', 'It seems good. I am curious about its favor.');
-- CALL Add_Survey_Question(1000000, 2, 'Are you eager to try this product?', '2022-04-01 15:00:00', '2022-04-30 15:00:00', 'Neutral. I am not sure.');
-- CALL Add_Survey_Question(1000000, 2, 'Are you eager to try this product?', '2022-04-01 15:00:00', '2022-04-30 15:00:00', 'I am not interested.');
-- CALL Add_Survey_Question(1000000, 2, 'Are you eager to try this product?', '2022-04-01 15:00:00', '2022-04-30 15:00:00', 'It is not my thing!');
-- CALL Add_Survey_Question(1000000, 2, 'Are you eager to try this product?', '2022-04-01 15:00:00', '2022-04-30 15:00:00', 'Other');


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
            
			SELECT survey_id INTO survey_id_ FROM Survey WHERE provider_id = provider_id_ 
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

DROP PROCEDURE IF EXISTS Provider_Register_Ecoupon;
DELIMITER $$
CREATE PROCEDURE Provider_Register_Ecoupon(
	ecoupon_id_ BIGINT,
    provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		INSERT INTO EcouponProviderDetail(ecoupon_id, provider_id) 
        VALUES(ecoupon_id_, provider_id_);
    COMMIT;
End$$
DELIMITER ; 
-- CALL Provider_Register_Ecoupon(2, 1000001);

DROP PROCEDURE IF EXISTS Get_Today_Offer_Provider_List;
DELIMITER $$
CREATE PROCEDURE Get_Today_Offer_Provider_List()
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT DISTINCT(p.provider_id) FROM Provider p
        LEFT JOIN Discount d ON p.provider_id = d.provider_id
        LEFT JOIN EcouponProviderDetail epd ON p.provider_id = epd.provider_id
        LEFT JOIN Ecoupon e ON epd.ecoupon_id = e.ecoupon_id
        LEFT JOIN Promotion pm ON p.provider_id = pm.provider_id
        WHERE (NOW() >= e.start_date AND NOW() <= e.expire_date) 
        OR (NOW() >= pm.start_at AND NOW() <= pm.expire_at)
        OR (NOW() >= d.start_at AND NOW() <= d.expire_at);
    COMMIT;
End$$
DELIMITER ;

-- CALL Get_Today_Offer_Provider_List();

-- ALTER TABLE Discount MODIFY COLUMN discount_description NVARCHAR(200);

DROP PROCEDURE IF EXISTS Add_Discount;
DELIMITER $$
CREATE PROCEDURE Add_Discount(
	provider_id_ BIGINT,
    discount_value_ FLOAT,
    discount_description_ NVARCHAR(200),
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
		INSERT INTO Discount(provider_id, discount_value, discount_description, start_at, expire_at)
        VALUES(provider_id_, discount_value_, discount_description_, start_at_, expire_at_);
    COMMIT;
End$$
DELIMITER ;
-- CALL Add_Discount(1000000, 0.2, 'Discount for specified products', '2022-05-17 07:00:00', '2022-06-17 07:00:00');

DROP PROCEDURE IF EXISTS Update_Discount;
DELIMITER $$
CREATE PROCEDURE Update_Discount(
	discount_id_ BIGINT,
	provider_id_ BIGINT,
    discount_value_ FLOAT,
    discount_description_ NVARCHAR(200),
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
		UPDATE Discount
        SET
			provider_id = provider_id_, 
			discount_value = discount_value_, 
			discount_description = discount_description_, 
			start_at = start_at_, 
			expire_at = expire_at_
        WHERE discount_id = discount_id_;
    COMMIT;
End$$


-- CALL Update_Discount(1, 1000000, 0.3, N'Discount for specified products', '2022-05-17 07:00:00', '2022-06-17 07:00:00');

DROP PROCEDURE IF EXISTS Get_All_Discounts;
DELIMITER $$
CREATE PROCEDURE Get_All_Discounts(
	provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT * FROM Discount d WHERE d.provider_id = provider_id_;
    COMMIT;
End $$
DELIMITER ;

-- CALL Get_All_Discounts(1000000);

DROP PROCEDURE IF EXISTS Apply_Discount_To_Product;
DELIMITER $$
CREATE PROCEDURE Apply_Discount_To_Product(
	product_id_ BIGINT,
    discount_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    IF EXISTS (SELECT d.expire_at FROM Discount d WHERE d.discount_id = discount_id_ AND d.expire_at > NOW())
    THEN 
		START TRANSACTION;
			UPDATE Product p 
			SET p.discount_id = discount_id_ 
			WHERE p.product_id = product_id_;
		COMMIT;
	ELSE 
		SET @s = 'Discount was expired';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
	END IF;
End$$
DELIMITER ;
-- CALL Apply_Discount_To_Product(1000000, 1);

DROP PROCEDURE IF EXISTS Remove_Discount_From_Product;
DELIMITER $$
CREATE PROCEDURE Remove_Discount_From_Product(
	product_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		UPDATE Product p 
		SET p.discount_id = NULL 
		WHERE p.product_id = product_id_;
	COMMIT;
End$$
DELIMITER ;

-- CALL Remove_Discount_From_Product(1000000);

-- Business Insights
DROP PROCEDURE IF EXISTS Get_Provider_Revenue_By_Time;
DELIMITER $$
CREATE PROCEDURE Get_Provider_Revenue_By_Time(
	provider_id_ BIGINT,
	start_month INT,
    end_month INT,
    year_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT SUM(result.total_amount) AS total_revenue FROM
			(SELECT DISTINCT(o.order_id), o.total_amount FROM `Order` o 
			JOIN PaymentStatus ps ON o.order_id = ps.order_id
            JOIN OrderDetail od ON o.order_id = od.order_id
            JOIN Product p ON od.product_id = p.product_id
			WHERE MONTH(ps.update_at) >= start_month AND MONTH(ps.update_at) <= end_month AND YEAR(ps.update_at) = year_
			AND ps.`status` = 2 AND p.provider_id = provider_id_) AS result;  
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Provider_Revenue_By_Time(1000018, 1, 6, 2022);

DROP PROCEDURE IF EXISTS Get_Provider_Num_Orders_By_Time;
DELIMITER $$
CREATE PROCEDURE Get_Provider_Num_Orders_By_Time(
	provider_id_ BIGINT,
	start_month INT,
    end_month INT,
    year_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT COUNT(DISTINCT(o.order_id)) AS total_num_orders FROM `Order` o 
        JOIN PaymentStatus ps ON o.order_id = ps.order_id
        JOIN OrderDetail od ON o.order_id = od.order_id
		JOIN Product p ON od.product_id = p.product_id
        WHERE MONTH(ps.update_at) >= start_month AND MONTH(ps.update_at) <= end_month AND 
        YEAR(ps.update_at) = year_ AND p.provider_id = provider_id_;
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Provider_Num_Orders_By_Time(1000018, 1, 2, 2022);

DROP PROCEDURE IF EXISTS Get_Top_Product_By_Unit_By_Provider;
DELIMITER $$
CREATE PROCEDURE Get_Top_Product_By_Unit_By_Provider(
	provider_id_ BIGINT,
	start_month INT,
    end_month INT,
    year_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT res.product_id, res.product_name, sum(res.quantity) AS total_quantity FROM
			(SELECT od.order_id, od.product_id, od.quantity, p.product_name FROM OrderDetail od
			JOIN PaymentStatus ps ON od.order_id = ps.order_id
			JOIN Product p ON od.product_id = p.product_id
			WHERE MONTH(ps.update_at) >= start_month AND MONTH(ps.update_at) <= end_month AND 
			YEAR(ps.update_at) = year_ AND p.provider_id = provider_id_
			GROUP BY od.order_id, od.product_id) AS res
			GROUP BY res.product_id
		ORDER BY total_quantity DESC
		LIMIT 20;        
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Top_Product_By_Unit_By_Provider(1000018, 1, 4, 2022);

DROP PROCEDURE IF EXISTS Get_Top_Product_By_Sales_By_Provider;
DELIMITER $$
CREATE PROCEDURE Get_Top_Product_By_Sales_By_Provider(
	provider_id_ BIGINT,
	start_month INT,
    end_month INT,
    year_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT res.product_id, res.product_name, sum(res.product_sales) AS total_sales FROM
			(SELECT od.order_id, od.product_id, p.product_name, od.quantity*p.price AS product_sales FROM OrderDetail od
			JOIN PaymentStatus ps ON od.order_id = ps.order_id
			JOIN Product p ON od.product_id = p.product_id
			WHERE MONTH(ps.update_at) >= start_month AND MONTH(ps.update_at) <= end_month AND 
			YEAR(ps.update_at) = year_ AND p.provider_id = provider_id_
			GROUP BY od.order_id, od.product_id) AS res
			GROUP BY res.product_id
		ORDER BY total_sales DESC 
		LIMIT 20;        
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Top_Product_By_Sales_By_Provider(1000018, 1, 4, 2022);

DROP PROCEDURE IF EXISTS Get_Voucher_Claims;
DELIMITER $$
CREATE PROCEDURE Get_Voucher_Claims(
	provider_id_ BIGINT,
    start_date_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT COUNT(*) FROM `Order` o 
        JOIN PaymentStatus ps ON o.order_id = ps.order_id
        JOIN OrderDetail od ON o.order_id = od.order_id
        JOIN Product p ON od.product_id = p.product_id
        WHERE p.provider_id = provider_id_ AND ps.update_at <= NOW() AND ps.update_at >= start_date_
        AND ps.`status` = 2 AND (p.discount_id IS NOT NULL OR o.promotion_id IS NOT NULL);
    COMMIT;
End $$
DELIMITER ;

DROP PROCEDURE IF EXISTS Get_Voucher_Cost;
DELIMITER $$
CREATE PROCEDURE Get_Voucher_Cost(
	provider_id_ BIGINT,
    start_date_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT * FROM `Order` o 
        JOIN PaymentStatus ps ON o.order_id = ps.order_id
        JOIN Promotion p2 ON o.promotion_id = p2.promotion_id
		JOIN OrderDetail od ON o.order_id = od.order_id
		JOIN Product p ON p.product_id = od.product_id
		LEFT JOIN Discount d ON d.discount_id = p.discount_id
        WHERE p.provider_id = provider_id_ AND ps.update_at <= NOW() AND ps.update_at >= start_date_
        AND ps.`status` = 2 AND (p.discount_id IS NOT NULL OR o.promotion_id IS NOT NULL);
    COMMIT;
End $$
DELIMITER ;

DROP PROCEDURE IF EXISTS Get_Num_Order_By_Provider;
DELIMITER $$
CREATE PROCEDURE Get_Num_Order_By_Provider(
	provider_id_ BIGINT,
    start_date_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT COUNT(DISTINCT(o.order_id)) AS total_num_orders FROM `Order` o 
        JOIN PaymentStatus ps ON o.order_id = ps.order_id 
		JOIN OrderDetail od ON o.order_id = od.order_id
        JOIN Product p ON od.product_id = p.product_id
        WHERE ps.update_at >= start_date_ AND ps.update_at <= NOW() 
        AND ps.`status` = 2 AND p.provider_id = provider_id_;
    COMMIT;
End $$
DELIMITER ;

DROP PROCEDURE IF EXISTS Get_Num_Orders_Inclu_Vouchers_By_Provider;
DELIMITER $$
CREATE PROCEDURE Get_Num_Orders_Inclu_Vouchers_By_Provider(
	provider_id_ BIGINT,
    start_date_ TIMESTAMP
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT * FROM `Order` o  
		JOIN Promotion p2 ON o.promotion_id = p2.promotion_id
		JOIN OrderDetail od ON o.order_id = od.order_id
		JOIN Product p ON p.product_id = od.product_id
		LEFT JOIN Discount d ON d.discount_id = p.discount_id
        JOIN PaymentStatus ps ON o.order_id = ps.order_id 
        WHERE ps.update_at >= start_date_ AND ps.update_at <= NOW() 
        AND ps.`status` = 2 AND p.provider_id = provider_id_;
    COMMIT;
End $$
DELIMITER ;
