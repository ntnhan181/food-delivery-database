Use Tastie;

-- ALTER TABLE `User` ADD COLUMN avatar VARCHAR(150);

# [provider]
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
        SELECT DISTINCT(odr.order_review_id), odr.order_id, odr.create_at, odr.content, odr.image, odr.stars, u.first_name, u.last_name, u.avatar 
        FROM OrderReview odr 
		LEFT JOIN `Order` o ON odr.order_id = o.order_id  
		LEFT JOIN `User` u ON o.customer_id = u.user_id
		JOIN OrderDetail od ON o.order_id = od.order_id  
		JOIN Product p1 ON od.product_id = p1.product_id
		JOIN Provider p2 ON p1.provider_id = p2.provider_id
		WHERE p1.provider_id = provider_id_;
	END IF;
    COMMIT;
End$$
DELIMITER ;
-- CALL Get_List_Review(1000061);
-- CALL Get_List_Review(1000047);


# [customer reviews order]
DROP PROCEDURE IF EXISTS Add_Order_Review;

DELIMITER $$
CREATE PROCEDURE Add_Order_Review(
    order_id_ BIGINT,
    create_at_ TIMESTAMP,
    content_ VARCHAR(150),
    image_ VARCHAR(300),
    stars_ TINYINT
)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		INSERT INTO OrderReview(order_id, create_at, content, image, stars)
        VALUES(order_id_, create_at_, content_, image_, stars_);	
    COMMIT;
End$$
DELIMITER ;

-- CALL Add_Order_Review(1, NOW(), '', '', 5);

DROP PROCEDURE IF EXISTS Add_Shipper_Review;

DELIMITER $$
CREATE PROCEDURE Add_Shipper_Review(
    order_id_ BIGINT,
    create_at_ TIMESTAMP,
    content_ VARCHAR(150),
    stars_ TINYINT
)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the caller
    END;
	START TRANSACTION;
		INSERT INTO ShipperReview(order_id, create_at, content, stars)
        VALUES(order_id_, create_at_, content_, stars_);	
    COMMIT;
End$$
DELIMITER ;

-- CALL Add_Shipper_Review(1, NOW(), '', 5);
