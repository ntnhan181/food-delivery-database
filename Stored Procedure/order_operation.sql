USE TASTIE;
-- ALTER TABLE ProviderCategory DROP COLUMN icon_url;
-- ALTER TABLE CuisineCategory DROP COLUMN icon_url;

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
		SELECT u.user_id, u.phone, ca.address, ca.city, ca.longitude, ca.latitude, ca.`type`
		FROM `User` u 
		JOIN CustomerAddress ca ON u.user_id = ca.customer_id 
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
		SELECT * 
		FROM Promotion 
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

	SELECT * FROM Ecoupon AS ec JOIN EcouponProviderDetail AS ecp ON ec.ecoupon_id = ecp.ecoupon_id
    WHERE ecp.provider_id = provider_id_ AND start_date < NOW() AND expire_date > NOW()
    ORDER BY min_order_value ASC;
    COMMIT;
End$$
DELIMITER ;

-- CALL Get_All_Promos(1000001); 
-- CALL Get_All_Ecoupon(1000001); 

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
#CALL Submit_Basic_Info_Order_Delivery(1, '1565', 1000005, '227 NVC, Px, Q5, TPHCM', '012345678', 1, 1, 'P-FREESHIP', NULL, 1, NULL, 2, 3, 100, 115);

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
#CALL Submit_Basic_Info_Order_Pickup(2, '1223', 1000005,  1, 1, NULL, NULL, 2, '4/7/2022 20:00:00', 10, 122);


DROP PROCEDURE IF EXISTS Submit_Order_Delivery_Items;
DELIMITER $$
CREATE PROCEDURE  Submit_Order_Delivery_Items(
	 user_id_ BIGINT,
 	 order_code_ VARCHAR(60)
)
Begin
	DECLARE cart_id_ BIGINT;
    DECLARE order_id_ BIGINT;
    
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

#CALL Submit_Order_Delivery_Items(1000005, '123');

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

#CALL Delete_Items_From_CartDetail(1000005);

DROP PROCEDURE IF EXISTS Get_Order_Summary;
DELIMITER $$
CREATE PROCEDURE  Get_Order_Summary(
	 order_code_ VARCHAR(60)
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
        p.payment_name, pr.promotion_id, e.ecoupon_id, os.*
        FROM `Order` o
        JOIN OrderStatus os ON o.order_id = os.order_id
        JOIN Payment p ON o.payment_id = p.payment_id
        LEFT JOIN Promotion pr ON o.promotion_id = pr.promotion_id
        LEFT JOIN Ecoupon e ON o.ecoupon_id = e.ecoupon_id
        WHERE o.order_id = order_id_;
	COMMIT;
End$$
DELIMITER ;

-- CALL Get_Order_Summary('8cc68dc0-b563-4ecb-93cf-77f0d9b87a66');

DROP PROCEDURE IF EXISTS Get_All_Products_From_Order;
DELIMITER $$
CREATE PROCEDURE  Get_All_Products_From_Order(
	 order_code_ VARCHAR(60)
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT od.*, p1.product_name, p1.price, p1.product_image, p2.provider_id, 
        p2.merchant_name, odr.stars
        FROM `Order` o
        JOIN OrderDetail od ON o.order_id = od.order_id
        LEFT JOIN OrderReview odr ON o.order_id = odr.order_id
        JOIN Product p1 ON od.product_id = p1.product_id 
        JOIN Provider p2 ON p1.provider_id = p2.provider_id
        WHERE o.order_code = order_code_;
	COMMIT;
End$$
DELIMITER ;

-- CALL Get_All_Products_From_Order('8cc68dc0-b563-4ecb-93cf-77f0d9b87a66');

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
		SELECT DISTINCT(o.order_id), o.order_code, o.total_amount, COUNT(od.order_id) AS num_items, p2.merchant_name,
        p2.address, p2.avatar, os.update_at, os.order_status_name, p.payment_name	
        FROM `Order` o
        JOIN Payment p ON o.payment_id = p.payment_id
        JOIN OrderDetail od ON o.order_id = od.order_id
        JOIN OrderStatus os ON o.order_id = os.order_id
        JOIN Product p1 ON od.product_id = p1.product_id
        JOIN Provider p2 ON p1.provider_id = p2.provider_id
        WHERE o.customer_id = customer_id_;
	COMMIT;
End$$
DELIMITER ;

-- CALL Get_Order_History_By_Customer(1000005);

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

-- CALL Update_Order_Status(11, 5, NULL, NOW());

DROP PROCEDURE IF EXISTS Get_Promotion_Detail;
DELIMITER $$
CREATE PROCEDURE Get_Promotion_Detail(
	 promotion_id_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT pr.* FROM Promotion pr WHERE pr.promotion_id = promotion_id_; 
	COMMIT;
End$$
DELIMITER ;

-- CALL Get_Promotion_Detail(1);

DROP PROCEDURE IF EXISTS Get_Ecoupon_Detail;
DELIMITER $$
CREATE PROCEDURE Get_Ecoupon_Detail(
	 ecoupon_id_ INT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT e.* FROM Ecoupon e WHERE e.ecoupon_id = ecoupon_id_; 
	COMMIT;
End$$
DELIMITER ;

-- CALL Get_Ecoupon_Detail(1);

DROP PROCEDURE IF EXISTS Update_Payment_Status;
DELIMITER $$
CREATE PROCEDURE Update_Payment_Status(
	 order_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		UPDATE `Order` SET payment_status_id = 2 WHERE order_id = order_id_; 
	COMMIT;
End$$
DELIMITER ;

-- CALL Update_Payment_Status(1);

#[provider] Get list order by provider id

DROP PROCEDURE IF EXISTS Get_List_Order_By_Provider;
DELIMITER $$
CREATE PROCEDURE Get_List_Order_By_Provider(
	 provider_id_ BIGINT
)
Begin
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		SELECT DISTINCT(od.order_id), o.order_code, o.total_amount, o.delivery_fee, o.tip, o.subtotal, 
        os.update_at, MAX(os.order_status_name), s.first_name AS shipper_first_name, s.last_name AS shipper_last_name, 
        u.first_name AS user_first_name, u.last_name AS user_last_name, odr.stars, p3.payment_name, 
        e.ecoupon_code, p4.promotion_code
        FROM Provider p1 
        JOIN Product p2 ON p1.provider_id = p2.provider_id
        JOIN OrderDetail od ON p2.product_id = od.product_id
        JOIN OrderStatus os ON od.order_id = os.order_id
        JOIN `Order` o ON od.order_id = o.order_id
        JOIN `User` u ON o.customer_id = u.user_id
        LEFT JOIN Shipper s ON o.shipper_id = s.shipper_id
        LEFT JOIN OrderReview odr ON o.order_id = odr.order_id
        JOIN Payment p3 ON o.payment_id = p3.payment_id
        LEFT JOIN Promotion p4 ON o.promotion_id = p4.promotion_id
        LEFT JOIN Ecoupon e ON o.ecoupon_id = e.ecoupon_id
        WHERE p1.provider_id = provider_id_
        GROUP BY od.order_id;
	COMMIT;
End$$
DELIMITER ;

CALL Get_List_Order_By_Provider(1000047);
