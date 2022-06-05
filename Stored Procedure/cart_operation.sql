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

-- CALL Get_Cart_Detail (1000001);

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

-- CALL Insert_Product_Into_Cart (1000005, 1000000, '?', '?', 'abc', 2, '2');


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
-- CALL Delete_Product_Into_Cart (1000005, 1000000, '1');


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
-- CALL Update_Qty_Note_Product_Into_Cart (1000005, 1000000,'mình muion61 ướng nước', 111, '2');

#---------------------------------------
-- # update prouduct into cart (value of product option: vd M, L, XL ... )
DROP PROCEDURE IF EXISTS Update_Value_Product_Into_Cart;

DELIMITER $$
CREATE PROCEDURE Update_Value_Product_Into_Cart(
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
-- CALL Update_Value_Product_Into_Cart(1000005, 1000000, '?', '?', '2');


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
-- DELIMITER ;
-- CALL Update_Label_Product_Into_Cart(1000005, 1000000, '?', '?', '2', 2);

# ----------------------------------------



