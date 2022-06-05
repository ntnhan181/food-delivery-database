USE Tastie;

ALTER TABLE Product ADD FULLTEXT (product_name);

SELECT * FROM Product WHERE MATCH(product_name) against('pizza  chesse' IN NATURAL LANGUAGE MODE);


DROP PROCEDURE IF EXISTS Search_Product;
DELIMITER $$
CREATE PROCEDURE Search_Product(
	 search_key NVARCHAR(100)
)
Begin
	SELECT DISTINCT(provider_id) FROM Product WHERE MATCH(product_name) against(search_key);
End$$
DELIMITER ;

CALL Search_Product('chick');
