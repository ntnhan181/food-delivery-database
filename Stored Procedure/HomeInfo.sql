USE Tastie;


# get all provider near by ...
DROP PROCEDURE IF EXISTS Get_All_Provider;

DELIMITER $$
CREATE PROCEDURE Get_All_Provider(
-- 	 user_id_ BIGINT
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
-- 		SET @s = 'User is not true';
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
CALL Get_All_Provider();

#----------------------------

DROP PROCEDURE IF EXISTS Get_Provider_By_Provider_Category;

DELIMITER $$
CREATE PROCEDURE Get_Provider_By_Provider_Category(
	provider_category_id_ INT
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		IF NOT EXISTS (Select pc.provider_category_id FROM ProviderCategory pc WHERE pc.provider_category_id = provider_category_id_)
		THEN
			SET @s = 'Category does not exist';
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
			#RETURN
		ELSE
			SELECT p.provider_id FROM Provider p 
            JOIN ProviderCategoryDetail pcd ON p.provider_id = pcd.provider_id
            WHERE pcd.provider_category_id = provider_category_id_;
		END IF;
	COMMIT;
End$$
DELIMITER ; 

-- CALL Get_Provider_By_Provider_Category(1000000);

DROP PROCEDURE IF EXISTS Get_Provider_By_Cuisine_Category;

DELIMITER $$
CREATE PROCEDURE Get_Provider_By_Cuisine_Category(
	cuisine_category_id_ INT
)
Begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- rollback any changes made in the transaction
        RESIGNAL;  -- raise again the sql exception to the # CALLer
    END;
	START TRANSACTION;
		IF NOT EXISTS (SELECT c.cuisine_category_id FROM CuisineCategory c WHERE c.cuisine_category_id = cuisine_category_id_)
		THEN
			SET @s = 'Category does not exist';
			SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
			#RETURN
		ELSE
			SELECT p.provider_id FROM Provider p 
            JOIN CuisineCategoryDetail ccd ON p.provider_id = ccd.provider_id
            WHERE ccd.cuisine_category_id = cuisine_category_id_;
		END IF;
	COMMIT;
End$$
DELIMITER ; 

-- CALL Get_Provider_By_Cuisine_Category(1000000);

