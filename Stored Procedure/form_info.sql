-- USE Tastie;
-- DROP PROCEDURE IF EXISTS Provider_Form_Info;

-- DELIMITER $$
-- Create Procedure Provider_Form_Info(
--     user_id_ BIGINT
-- )
-- Begin
-- 	DECLARE owner_id_ BIGINT;
-- 	DECLARE provider_id_ BIGINT;
--     DECLARE current_form_ SMALLINT;
-- 	DECLARE EXIT HANDLER FOR SQLEXCEPTION
-- 	BEGIN
-- 		ROLLBACK;  -- rollback any changes made in the transaction
-- 		RESIGNAL;  -- raise again the sql exception to the caller
-- 	END;
-- 	START TRANSACTION;
-- 	IF NOT EXISTS (Select user_id FROM `User` u WHERE u.user_id = user_id_)
--     THEN
-- 		SET @s = 'Account does not exist';
-- 		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = @s;
--         #RETURN
-- 	ELSE 
-- 		SELECT p.provider_id, p.current_form INTO provider_id_, current_form_ FROM `Provider` p WHERE user_id = user_id_;
-- 		SELECT p.owner_id INTO owner_id_ FROM `Provider` p WHERE p.provider_id = provider_id_ AND user_id = user_id_;

-- 			IF current_form_ = 1
-- 				THEN
-- 					SELECT  merchant_name, address, road, hotline, city_id, district_id, ward_id, latitude, longitude
-- 					FROM Provider 
-- 					WHERE provider_id = provider_id_;
-- 				
-- 			ELSEIF current_form_ = 2
-- 				THEN
-- 					SELECT p.merchant_name, p.address, p.road, p.hotline, p.city_id, p.district_id, p.ward_id, p.latitude, p.longitude, 
-- 					o.company_name, o.company_address, o.owner_name, p.tax_code, p.rush_hour,
-- 					o.email, o.owner_phone, o.owner_card_id, o.role, o.create_at, o.update_at, oci.owner_card_image
-- 					FROM Provider p JOIN `Owner` o ON p.owner_id = o.owner_id JOIN ownercardimage oci ON o.owner_id = oci.owner_id
-- 					WHERE p.provider_id = provider_id_ AND p.owner_id = owner_id_;
-- 			
-- 			ELSEIF current_form_ = 3
-- 				THEN
-- 					SELECT 	p.merchant_name, p.address, p.road, p.hotline, p.city_id, p.district_id, p.ward_id, p.latitude, p.longitude, 
-- 							p.keyword, p.description, p.avatar, p.cover_picture, p.facade_photo, p.tax_code,
-- 							o.company_name, o.company_address, o.owner_name, o.email, o.owner_phone, o.owner_card_id, 
-- 							o.role, o.create_at, o.update_at, oci.owner_card_image,
-- 							op.day, op.open_time, op.close_time,
-- 							cc.*, pc.*
-- 							
-- 					FROM Provider p JOIN `Owner` o ON p.owner_id = o.owner_id JOIN ownercardimage oci ON o.owner_id = oci.owner_id 
-- 					JOIN Operation op ON p.provider_id = op.provider_id
-- 					JOIN CuisineCategoryDetail ccd ON p.provider_id = ccd.provider_id JOIN CuisineCategory cc ON ccd.cuisine_category_id = cc.cuisine_category_id
-- 					JOIN ProviderCategoryDetail pcd ON p.provider_id = pcd.provider_id JOIN ProviderCategory pc ON pcd.provider_category_id = pc.provider_category_id
-- 					WHERE p.provider_id = provider_id_ AND p.owner_id = owner_id_;
-- 				
-- 			ELSE # current_form_ = 4
-- 					SELECT 	p.merchant_name, p.address, p.road, p.hotline, p.city_id, p.district_id, p.ward_id, p.latitude, p.longitude, 
-- 							p.keyword, p.description, p.avatar, p.cover_picture, p.facade_photo, p.tax_code, p.price_range,
-- 							o.company_name, o.company_address, o.owner_name, o.email, o.owner_phone, o.owner_card_id, 
-- 							o.role, o.create_at, o.update_at, oci.owner_card_image,
-- 							op.day, op.open_time, op.close_time,
-- 							cc.*, pc.*, mp.menu_image
-- 							
-- 					FROM Provider p JOIN `Owner` o ON p.owner_id = o.owner_id JOIN ownercardimage oci ON o.owner_id = oci.owner_id 
-- 					JOIN Operation op ON p.provider_id = op.provider_id
-- 					JOIN CuisineCategoryDetail ccd ON p.provider_id = ccd.provider_id JOIN CuisineCategory cc ON ccd.cuisine_category_id = cc.cuisine_category_id
-- 					JOIN ProviderCategoryDetail pcd ON p.provider_id = pcd.provider_id JOIN ProviderCategory pc ON pcd.provider_category_id = pc.provider_category_id
-- 					JOIN MenuPhoto mp ON p.provider_id = mp.provider_id
-- 					WHERE p.provider_id = provider_id_ AND p.owner_id = owner_id_;
-- 			END IF;
-- 	END IF;
--     COMMIT;
-- End$$
-- DELIMITER ;
-- CALL Provider_Form_Info(1000000);




--             

--     


