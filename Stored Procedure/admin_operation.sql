USE Tastie;

-- Nhớ chạy đoạn này 
-- ALTER TABLE `Admin` DROP COLUMN user_id;
-- ALTER TABLE `Admin` ADD COLUMN `email` VARCHAR(40);
-- ALTER TABLE `Admin` ADD COLUMN `password` VARCHAR(20);

DROP PROCEDURE IF EXISTS Admin_Login;
DELIMITER $$
CREATE PROCEDURE Admin_Login (
	email_ VARCHAR(40),
    password_ VARCHAR(20)
)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
	IF NOT EXISTS (SELECT `email` FROM `Admin` WHERE `email` = email_)
    THEN
		SET @s = 'Account does not exist';
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
	ELSEIF EXISTS (SELECT `email` FROM `Admin` WHERE `email` = email_ AND `password`!= password_)
    THEN
		SET @s = 'Wrong password';
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
    ELSE
		SELECT * FROM `Admin` WHERE email = email_ AND `password`= password_;
    END IF;
    COMMIT;
End$$
DELIMITER ;

-- CALL Admin_Login('admin123@tastie.com', '123abc');

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

-- CALL Add_Ecoupon('E_SALEOFF10USD', 'Sale off 10 USD', 50, 'Maximum 10 USD off on total amount', 20, 10, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 1, 1);
-- CALL Add_Ecoupon('E_SALEOFF20USD', 'Sale off 20 USD', 50, 'Maximum 20 USD off on total amount', 80, 20, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 1, 1);
-- CALL Add_Ecoupon('E_SALEOFF25USD', 'Sale off 25 USD', 50, 'Maximum 25 USD off on total amount', 100, 25, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 1, 1);

-- INSERT INTO ecouponproviderdetail(ecoupon_id, provider_id) VALUES  (1, 1000001), (2, 1000001), (3, 1000001);



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
			update_at = NOW()
        WHERE ecoupon_id = ecoupon_id_;
	COMMIT;
End$$
DELIMITER ;

-- CALL Update_Ecoupon(1, 'SALEOFF5USD', 'Sale off 5 USD', 50, 'Maximum 5 USD off on total amount', 10, 5, '2022-03-31 12:00:00', '2022-04-30 12:00:00', 1, 300, 2, 1, CURRENT_TIMESTAMP());

#[Admin] Remove User

DROP PROCEDURE IF EXISTS Remove_User;

DELIMITER $$
CREATE PROCEDURE Remove_User(
	user_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		UPDATE `User` SET 
        user_status = 2,
        delete_at = NOW()
        WHERE user_id = user_id_;
    COMMIT;
End$$
DELIMITER ;

-- CALL Remove_User(1000002);

#[Admin] Remove Provider
DROP PROCEDURE IF EXISTS Remove_Provider;

DELIMITER $$
CREATE PROCEDURE Remove_Provider(
	provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		UPDATE Provider SET 
        `status` = 3, 
        delete_at = NOW()
        WHERE provider_id = provider_id_;
    COMMIT;
End$$
DELIMITER ;

-- CALL Remove_Provider(1000002);

#[Admin] Get top providers by revenue
DROP PROCEDURE IF EXISTS Get_Top_Providers_By_Revenue;
DELIMITER $$
CREATE PROCEDURE Get_Top_Providers_By_Revenue(
	start_month INT,
    end_month INT,
    year_ INT,
    limit_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT temp.provider_id, temp.merchant_name, SUM(temp.revenue) as revenue, temp.order_id
		FROM (
			SELECT distinct(o.order_id), pv.provider_id, pv.merchant_name, o.total_amount AS revenue
			FROM `Order` o  JOIN OrderDetail od ON o.order_id = od.order_id
							JOIN Product pd ON od.product_id = pd.product_id 
							JOIN Provider pv ON pd.provider_id = pv.provider_id
							JOIN PaymentStatus ps ON o.order_id = ps.order_id
			WHERE MONTH(ps.update_at) >= start_month 
					AND MONTH(ps.update_at) <= end_month 
					AND YEAR(ps.update_at) = year_
					AND ps.`status` = 2
			GROUP BY o.order_id, pd.product_id
		) AS temp
		GROUP BY temp.provider_id
		ORDER BY SUM(temp.revenue) DESC
		LIMIT limit_;
    COMMIT;
End$$
DELIMITER ;

-- CALL Get_Top_Providers_By_Revenue(4, 4, 2022, 20);

#[Admin] Get top providers by sales : num_orders
DROP PROCEDURE IF EXISTS Get_Top_Providers_By_Sales;
DELIMITER $$
CREATE PROCEDURE Get_Top_Providers_By_Sales(
	start_month INT,
    end_month INT,
    year_ INT,
    limit_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		SELECT temp.provider_id, temp.merchant_name, COUNT(temp.order_id) AS num_sales
		FROM (
			SELECT distinct(o.order_id), pv.provider_id, pv.merchant_name
			FROM `Order` o  JOIN OrderDetail od ON o.order_id = od.order_id
							JOIN Product pd ON od.product_id = pd.product_id 
							JOIN Provider pv ON pd.provider_id = pv.provider_id
							JOIN PaymentStatus ps ON o.order_id = ps.order_id
			WHERE MONTH(ps.update_at) >= start_month 
					AND MONTH(ps.update_at) <= end_month 
					AND YEAR(ps.update_at) = year_
					AND ps.`status` = 2
			GROUP BY o.order_id, pd.product_id
		) AS temp
		GROUP BY temp.provider_id
		ORDER BY num_sales DESC
		LIMIT limit_;
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Top_Providers_By_Sales(3, 6, 2022, 20);

#[Admin] Get key metrics
DROP PROCEDURE IF EXISTS Get_Total_Revenue_By_Time;
DELIMITER $$
CREATE PROCEDURE Get_Total_Revenue_By_Time(
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
			WHERE MONTH(ps.update_at) >= start_month AND MONTH(ps.update_at) <= end_month AND YEAR(ps.update_at) = year_
			AND ps.`status` = 2) AS result;  
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Total_Revenue_By_Time(3, 6, 2022);

DROP PROCEDURE IF EXISTS Get_Num_Orders_By_Time;
DELIMITER $$
CREATE PROCEDURE Get_Num_Orders_By_Time(
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
        WHERE MONTH(ps.update_at) >= start_month AND MONTH(ps.update_at) <= end_month AND YEAR(ps.update_at) = year_;
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_Num_Orders_By_Time(3, 6, 2022);

DROP PROCEDURE IF EXISTS Admin_Response_Provider_Request;
DELIMITER $$
CREATE PROCEDURE Admin_Response_Provider_Request(
    provider_id_ BIGINT,
    status_ TINYINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
    START TRANSACTION;
		UPDATE Provider p SET `status` = status_ WHERE p.provider_id = provider_id_;
    COMMIT;
End$$
DELIMITER ; 


