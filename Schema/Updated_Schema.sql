USE Tastie;

CREATE TABLE FavoriteRestaurant(
	customer_id BIGINT,
    provider_id BIGINT,
    PRIMARY KEY(customer_id, provider_id)
);

CREATE TABLE Survey(
	survey_id INT AUTO_INCREMENT PRIMARY KEY,
    provider_id BIGINT,
    upcoming_product_id INT,
    question NVARCHAR(200),
    start_at TIMESTAMP,
    expire_at TIMESTAMP
);

CREATE TABLE SurveyDetail(
	survey_id INT,
    choice NVARCHAR(200)
);

CREATE TABLE UpcomingProduct(
	upcoming_product_id INT AUTO_INCREMENT PRIMARY KEY,
    provider_id BIGINT,
    product_name NVARCHAR(50),
    product_description NVARCHAR(200),
    estimated_price FLOAT,
    product_image VARCHAR(300)
);

CREATE TABLE UpcomingProductReview(
	upcoming_product_id INT,
    customer_id BIGINT,
    response NVARCHAR(150),
    create_at TIMESTAMP
);


CREATE TABLE Banner(
	banner_id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
	title VARCHAR(100),
    subtitle TEXT,
    title_color VARCHAR(10),
    subtitle_color varchar(10),
    background_image_url VARCHAR(120)
);

# Chưa dùng admin
CREATE TABLE admin(
	admin_id  INT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT
);

CREATE TABLE Ecoupon(
	ecoupon_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    ecoupon_name NVARCHAR(50),
    ecoupon_description NVARCHAR(200),
    ecoupon_value FLOAT,
    ecoupon_code VARCHAR(30), #E
    min_order_value FLOAT,
    max_discount_value FLOAT,
	limited_offer INT,
    payment_method_id TINYINT,
    weekly_usage_limit_per_user TINYINT,
    start_date TIMESTAMP,
    expire_date TIMESTAMP,
    delivery_mode TINYINT,
    ecoupon_status TINYINT,
    update_at TIMESTAMP,
    delete_at TIMESTAMP
);

CREATE TABLE EcouponProviderDetail(
	ecoupon_id BIGINT,
    provider_id BIGINT NOT NULL
);


CREATE TABLE Cart(
	cart_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    cart_state TINYINT, # 1 là active
    total_price FLOAT
);

CREATE TABLE CartDetail(
	cart_id BIGINT,
    product_id BIGINT,
    item_code VARCHAR(150) NOT NULL DEFAULT '?',
	label NVARCHAR(100) NOT NULL,
    `value` NVARCHAR(100) NOT NULL,
    quantity INT,
    special_instruction NVARCHAR(150)
);
-- ALTER TABLE CartDetail ALTER label SET DEFAULT '?';
-- ALTER TABLE CartDetail ALTER `value` SET DEFAULT '?';

CREATE TABLE `Order`( 
	order_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT,
    payment_id INT,
    shipper_id BIGINT,
    order_code varchar(60) UNIQUE NOT NULL, # order code is visible to customer, i.e #FR12UX02
    payment_status_id INT,
    promotion_id INT, # pending, lack of promotion table
    ecoupon_id BIGINT,
    customer_address NVARCHAR(250),
    customer_phone VARCHAR(10),
    delivery_method_id INT, # 1: standard, 2: priority, 3: schedule
    delivery_fee FLOAT,
    tip FLOAT, # optional
    subtotal FLOAT,
    total_amount FLOAT,
    delivery_mode TINYINT,
	schedule_time VARCHAR(50) # null if the delivery method is not "schedule"
);

CREATE TABLE OrderStatus(
	order_id BIGINT,
    update_at TIMESTAMP NOT NULL,
    order_status_name TINYINT
);
CREATE TABLE OrderDetail(
	order_id BIGINT,
    product_id BIGINT,
	label NVARCHAR(100) NOT NULL,
    `value` NVARCHAR(100) NOT NULL,
    quantity INT,
    special_instruction NVARCHAR(150),
    item_code VARCHAR(150)
);

CREATE TABLE Payment(
	payment_id INT PRIMARY KEY AUTO_INCREMENT,
    payment_name varchar(20)
);

CREATE TABLE PaymentStatus(
	order_id BIGINT, # 
	`status` TINYINT, # 1: chưa thanh toán, 2: đã thanh toán 
    update_at TIMESTAMP NOT NULL
);

CREATE TABLE DeliveryMethod(
	delivery_method_id INT PRIMARY KEY AUTO_INCREMENT,
    delivery_method VARCHAR(20)
-- 	schedule_time TIMESTAMP # null if the delivery method is not "schedule"
);

CREATE TABLE OrderReview(
	order_review_id BIGINT PRIMARY KEY AUTO_INCREMENT,
	order_id BIGINT UNIQUE NOT NULL,	
    create_at TIMESTAMP,
    content NVARCHAR(150),
    image VARCHAR(300),
    stars TINYINT
);
CREATE TABLE ShipperReview(
	shipper_review_id BIGINT PRIMARY KEY AUTO_INCREMENT,
	order_id BIGINT UNIQUE NOT NULL,
    create_at TIMESTAMP,
    content NVARCHAR(150),
    stars TINYINT
);


CREATE TABLE Promotion(
	promotion_id INT PRIMARY KEY AUTO_INCREMENT,
    provider_id BIGINT,
    promotion_name NVARCHAR(50),
	promotion_description NVARCHAR(200),
    promotion_code VARCHAR(30) UNIQUE NOT NULL, # P....
    promotion_value FLOAT,
    promotion_status TINYINT,
    max_discount_value INT,
    min_order_value INT, /**/
    start_at TIMESTAMP,
    expire_at TIMESTAMP,
    payment_method_id TINYINT,
	limited_offer INT,
    weekly_usage_limit_per_user TINYINT,
    delivery_mode TINYINT,
    update_at TIMESTAMP,
    delete_at TIMESTAMP
);

CREATE TABLE Discount(
	discount_id BIGINT PRIMARY KEY AUTO_INCREMENT,
	provider_id BIGINT,
    discount_value FLOAT,
	start_at TIMESTAMP,
    expire_at TIMESTAMP
);

CREATE TABLE Shipper(
	shipper_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    first_name NVARCHAR(20),
    last_name NVARCHAR(20),
    id_card_number VARCHAR(12),
	phone_number VARCHAR(10),
	driving_license VARCHAR(100),
	license_plate VARCHAR(20),
    email VARCHAR(30),
    credit_card VARCHAR(20),
    avatar VARCHAR(300),
    create_at TIMESTAMP, 
    update_at TIMESTAMP,
    delete_at TIMESTAMP  
);

# Add/modify columns
ALTER TABLE Product ADD COLUMN calo FLOAT;
ALTER TABLE Product MODIFY price FLOAT;
ALTER TABLE Product ADD COLUMN discount_id BIGINT;
ALTER TABLE `User` ADD COLUMN avatar VARCHAR(150);
--------------------------
ALTER TABLE Payment MODIFY COLUMN payment_id TINYINT AUTO_INCREMENT;
ALTER TABLE `Order` MODIFY COLUMN payment_id TINYINT;
ALTER TABLE `Order` ADD CONSTRAINT FK_Order_Payment FOREIGN KEY (payment_id) REFERENCES Payment(payment_id);
ALTER TABLE ProviderCategory ADD COLUMN icon_url VARCHAR(120);
ALTER TABLE CuisineCategory ADD COLUMN icon_url VARCHAR(120);
-------------------------------------------
ALTER TABLE Discount ADD COLUMN discount_description NVARCHAR(200);
ALTER TABLE UpcomingProduct ADD COLUMN update_at TIMESTAMP;

ALTER TABLE Survey ADD UNIQUE ProviderHasUpcomingProduct (provider_id, upcoming_product_id);

ALTER TABLE `Order` ADD CONSTRAINT FK_Order_Customer FOREIGN KEY (customer_id) REFERENCES User(user_id);
ALTER TABLE `Order` ADD CONSTRAINT FK_Order_Shipper FOREIGN KEY (shipper_id) REFERENCES Shipper(shipper_id);
ALTER TABLE `Order` ADD CONSTRAINT FK_Order_Ecoupon FOREIGN KEY (ecoupon_id) REFERENCES Ecoupon(ecoupon_id);
ALTER TABLE `Order` ADD CONSTRAINT FK_Order_Delivery_Method FOREIGN KEY (delivery_method_id) REFERENCES DeliveryMethod(delivery_method_id);
ALTER TABLE `Order` ADD CONSTRAINT FK_Order_Promotion FOREIGN KEY (promotion_id) REFERENCES Promotion(promotion_id);

ALTER TABLE OrderDetail ADD CONSTRAINT PK_OrderDetail PRIMARY KEY(order_id, product_id, label, `value`, item_code);
ALTER TABLE OrderDetail ADD CONSTRAINT FK_OrderDetail_Order FOREIGN KEY (order_id) REFERENCES `Order`(order_id);
ALTER TABLE OrderDetail ADD CONSTRAINT FK_OrderDetail_Product FOREIGN KEY(product_id) REFERENCES Product(product_id);
ALTER TABLE OrderDetail ADD CONSTRAINT FK_OrderDetail_ProductOption FOREIGN KEY(product_id, `value`, label) REFERENCES ProductOption(product_id, `value`, label);

ALTER TABLE OrderReview ADD CONSTRAINT FK_OrderReview_Order FOREIGN KEY (order_id) REFERENCES `Order`(order_id);

ALTER TABLE PaymentStatus ADD CONSTRAINT PK_PaymentStatus PRIMARY KEY (order_id, update_at);
ALTER TABLE PaymentStatus ADD CONSTRAINT FK_PaymentStatus_belongTo_Order FOREIGN KEY (order_id) REFERENCES `Order`(order_id);
ALTER TABLE OrderStatus ADD CONSTRAINT PK_OrderStatus PRIMARY KEY (order_id, order_status_name);
ALTER TABLE OrderStatus ADD CONSTRAINT FK_OrderStatus_belongTo_Order FOREIGN KEY (order_id) REFERENCES `Order`(order_id);

ALTER TABLE EcouponProviderDetail ADD CONSTRAINT PK_EcouponProviderDetail PRIMARY KEY(ecoupon_id, provider_id);
ALTER TABLE EcouponProviderDetail ADD CONSTRAINT FK_Providers_belongTo_Ecoupon FOREIGN KEY (provider_id) references Provider(provider_id);
ALTER TABLE EcouponProviderDetail ADD CONSTRAINT FK_Ecoupon_belongTo_Ecoupon FOREIGN KEY (ecoupon_id) references Ecoupon(ecoupon_id);

ALTER TABLE ShipperReview ADD CONSTRAINT FK_ShipperReview_Order FOREIGN KEY (order_id) REFERENCES `Order`(order_id);

ALTER TABLE Cart ADD CONSTRAINT FK_Cart_User FOREIGN KEY (user_id) REFERENCES `User`(user_id);

ALTER TABLE CartDetail ADD CONSTRAINT PK_CartDetail PRIMARY KEY(cart_id, product_id, label, `value`, item_code);
ALTER TABLE CartDetail ADD CONSTRAINT FK_CartDetail_Cart FOREIGN KEY(cart_id) REFERENCES Cart(cart_id);
ALTER TABLE CartDetail ADD CONSTRAINT FK_CartDetail_Product FOREIGN KEY(product_id) REFERENCES Product(product_id);
ALTER TABLE CartDetail ADD CONSTRAINT FK_CartDetail_ProductOption FOREIGN KEY(product_id, `value`, label) REFERENCES ProductOption(product_id, `value`, label);

ALTER TABLE Promotion ADD CONSTRAINT FK_Promotion_Provider FOREIGN KEY (provider_id) REFERENCES Provider(provider_id);

ALTER TABLE Discount ADD CONSTRAINT FK_Discount_Provider FOREIGN KEY (provider_id) REFERENCES Provider(provider_id);
ALTER TABLE Product ADD CONSTRAINT FK_Product_Discount FOREIGN KEY (discount_id) REFERENCES Discount(discount_id);

ALTER TABLE Survey ADD CONSTRAINT FK_Survey_Provider FOREIGN KEY(provider_id) REFERENCES Provider(provider_id);
ALTER TABLE Survey ADD CONSTRAINT FK_Survey_UpcomingProduct FOREIGN KEY(upcoming_product_id) REFERENCES UpcomingProduct(upcoming_product_id);
ALTER TABLE SurveyDetail ADD CONSTRAINT PK_SurveyDetail PRIMARY KEY(survey_id, choice);
ALTER TABLE Survey ADD COLUMN update_at TIMESTAMP;

ALTER TABLE UpcomingProduct ADD CONSTRAINT FK_UpcomingProduct_Provider FOREIGN KEY(provider_id) REFERENCES Provider(provider_id);
ALTER TABLE UpcomingProductReview ADD CONSTRAINT PK_UpcomingProductReview PRIMARY KEY(upcoming_product_id, customer_id);
ALTER TABLE UpcomingProductReview ADD CONSTRAINT FK_UpcomingProductReview_UpcomingProduct FOREIGN KEY(upcoming_product_id) REFERENCES UpcomingProduct(upcoming_product_id);
ALTER TABLE UpcomingProductReview ADD CONSTRAINT FK_UpcomingProductReview_User FOREIGN KEY(customer_id) REFERENCES User(user_id);

ALTER TABLE Ecoupon ADD CONSTRAINT FK_Ecoupon_Payment FOREIGN KEY (payment_method_id) REFERENCES Payment(payment_id);##
ALTER TABLE Promotion ADD CONSTRAINT FK_Promotion_Payment FOREIGN KEY (payment_method_id) REFERENCES Payment(payment_id);
ALTER TABLE Banner ADD CONSTRAINT FK_Banner_Admin FOREIGN KEY (admin_id) references Admin(admin_id);

ALTER TABLE FavoriteRestaurant ADD CONSTRAINT FK_FavoriteRestaurant_User FOREIGN KEY(customer_id) REFERENCES `User`(user_id);
ALTER TABLE FavoriteRestaurant ADD CONSTRAINT FK_FavoriteRestaurant_Provider FOREIGN KEY(provider_id) REFERENCES Provider(provider_id);

#================================
-- INSERT INTO Payment(payment_id, payment_name) VALUES 
-- 			(1, 'Cash'),
--             (2, 'Momo'),
--             (3, 'Card');

-- INSERT INTO DeliveryMethod(delivery_method_id, delivery_method) VALUES
-- 							(1, 'Standard'),
-- 							(2, 'Schedule');


