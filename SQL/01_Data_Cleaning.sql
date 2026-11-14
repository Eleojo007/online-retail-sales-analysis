-- Data Cleaning SQL Script
/*
Project: Online Retail Sales Analysis
Dataset: UCI Online Retail Dataset
Author: Philip Hosea Eleojo

Description:
This script contains all data cleaning, validation,
standardization and feature engineering steps performed
before exploratory data analysis.
*/
-- INSPECT DATA

SELECT *
FROM online_retail_original;

SELECT COUNT(*) AS total_rows
FROM online_retail_original;

-- total rows is 541909 before cleaning
-- creating table for cleaning

DROP TABLE IF EXISTS online_retail_staging;
CREATE TABLE online_retail_staging AS 
SELECT *
FROM online_retail_original;

-- check staging table

SELECT *
FROM online_retail_staging;

SELECT COUNT(*) AS tt
FROM online_retail_staging;

-- FIX FORMAT(REMOVING WHITE SPACES)
-- excel has been used to fix some column mixed cases(upper/lower)
-- trimming every column for white spaces 

UPDATE online_retail_staging
SET StockCode = UPPER(StockCode);

UPDATE online_retail_staging
SET `Description` = UPPER(`Description`);

SELECT *, 
TRIM(InvoiceNo) AS clean_invoiceno,
TRIM(StockCode) AS clean_stockcode,
TRIM(`Description`) AS clean_description,
TRIM(Quantity) AS clean_quantity,
TRIM(InvoiceDate) AS cleanInvoiceDate,
TRIM(UnitPrice) AS cleanUnitPrice,
TRIM(CustomerId) AS cleanCustomerId,
TRIM(Country) AS cleanCountry
FROM online_retail_staging;

-- all columns are in varchar so all columns must be cleaned of whitespace

UPDATE online_retail_staging
SET InvoiceNo = TRIM(InvoiceNo),
	StockCode = TRIM(StockCode),
    `Description` = TRIM(`Description`),
    Quantity = TRIM(Quantity),
    InvoiceDate = TRIM(InvoiceDate),
    UnitPrice = TRIM(UnitPrice),
    CustomerId = TRIM(CustomerId),
    Country = TRIM(Country);
    
-- 113452 rows were cleaned ofextra white space
    
SELECT *
FROM online_retail_staging;

-- CHECKING FOR DUPLICATES

WITH duplicateCTE AS (
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY  InvoiceNo, `Description`, Quantity, UnitPrice, InvoiceDate, CustomerId, Country, StockCode) AS row_num
FROM online_retail_staging
)
SELECT *
FROM duplicateCTE
WHERE row_num > 1;

-- 5268 rows returned as exact duplicate rows
-- remove those duplicate rows from the original 541909 using a new table

DROP TABLE IF EXISTS online_retail_staging1;
CREATE TABLE online_retail_staging1 AS

 WITH duplicateCTE AS (
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY InvoiceNo, StockCode, `Description`, Quantity, InvoiceDate, UnitPrice, CustomerId, Country) AS row_num
FROM online_retail_staging
)
SELECT  InvoiceNo, StockCode, `Description`, Quantity, InvoiceDate, UnitPrice, CustomerId, Country 
FROM duplicateCTE
WHERE row_num = 1;

-- inspect new table

SELECT *
FROM online_retail_staging1;

-- after removing exact duplicates, 536641 rows remain

-- FIXING BLANK CELLS in each column by changing to NULL before trying to populate or flag it

SELECT *
FROM online_retail_staging1
WHERE `Description` = '';

-- `Description` had 1454 blank rows

SELECT `Description`, CASE 
WHEN `Description` = '' THEN NULL 
ELSE `Description`
END AS corrected
FROM online_retail_staging1
WHERE `Description` = '';

UPDATE online_retail_staging1
SET `Description` = CASE 
WHEN `Description` = '' THEN NULL 
ELSE `Description`
END;

-- 1454 blank rows changed to NULL

SELECT CustomerId, COUNT(*) AS tt
FROM online_retail_staging1
WHERE CustomerId = ''
GROUP BY CustomerId;

-- 135037 rows had missing customerid
-- replace with NULL then investigate later

SELECT CustomerId, CASE 
WHEN CustomerId = '' THEN NULL 
ELSE CustomerId
END AS corrected
FROM online_retail_staging1
WHERE CustomerId = '';

UPDATE online_retail_staging1
SET CustomerId = CASE 
WHEN CustomerId = '' THEN NULL 
ELSE CustomerId
END;

-- 135037 blank rows were replaced with NULL till further investigation
-- only the description and customerid columns had blank values which were replaced by NULL
-- the other columns had no blank values

-- CHANGE DATATYPES FOR COLUMNS

-- change datatypes and remove unwanted column
-- all columns were imported as varchar

DESCRIBE online_retail_staging1;

ALTER TABLE online_retail_staging1
MODIFY COLUMN Quantity INT,
MODIFY COLUMN InvoiceDate DATETIME,
MODIFY COLUMN UnitPrice DECIMAL(10,3);

-- STANDARDIZE DATA
-- checking description columns for typos and wrong spellings

SELECT DISTINCT `Description`
FROM online_retail_staging1;

-- create a mapping table for typos noticed in description

DROP TABLE IF EXISTS description_mapping;
CREATE TABLE description_mapping (
	StockCode VARCHAR(50),
    IncorrectDescription VARCHAR(255),
    CorrectDescription VARCHAR(255)
);


INSERT INTO description_mapping 
(StockCode, IncorrectDescription, CorrectDescription)

VALUES
('23068', 'ALUMINIUM HEART', 'ALUMINIUM STAMPED HEART'),
('23253', '16 PC CUTLERY SET PANTRY DESIGN', '16 PIECE CUTLERY SET PANTRY DESIGN'),
('22937', 'BAKING MOULD CHOCOLATE CUP CAKES', 'BAKING MOULD CHOCOLATE CUPCAKES'),
('22972', 'CHILDRENS SPACEBOY MUG', "CHILDREN'S SPACEBOY MUG"),
('23271', 'CHRISTMAS TABLE CANDLE SILVER SPIKE', 'CHRISTMAS TABLE SILVER CANDLE SPIKE'),
('23497', 'CLASSIC CROME BICYCLE BELL', 'CLASSIC CHROME BICYCLE BELL'),
('22287', 'DECORATION , WOBBLY CHICKEN, METAL', 'DECORATION WOBBLY CHICKEN'),
('22286', 'DECORATION , WOBBLY RABBIT , METAL', 'DECORATION WOBBLY RABBIT METAL'),
('22466', 'FAIRY TALE COTTAGE NIGHTLIGHT', 'FAIRY TALE COTTAGE NIGHT LIGHT'),
('81950V', 'FLOWER PURPLE CLOCK W/SUCKER', 'FLOWER PURPLE CLOCK WITH SUCKER'),
('23299', 'FOOD COVER WITH BEADS , SET 2 SIZES', 'FOOD COVER WITH BEADS SET 2'),
('20725', 'LUNCH BAG RED SPOTTY', 'LUNCH BAG RED RETROSPOT'),
('21175', 'GIN AND TONIC DIET METAL SIGN', 'GIN + TONIC DIET METAL SIGN'),
('23086', 'ZINC  STAR T-LIGHT HOLDER', 'ZINC STAR T-LIGHT HOLDER'),
('23145', 'ZINC T-LIGHT HOLDER STARS LARGE', 'ZINC T-LIGHT HOLDER STAR LARGE'),
('23484', 'HEART TRELLISTRIPLE T-LIGHT HOLDER', 'HEART TRELLIS TRIPLE T-LIGHT HOLDER'),
('71459', 'HANGING JAM JAR T-LIGHT HOLDERS', 'HANGING JAM JAR T-LIGHT HOLDER'),
('71477', 'COLOURED GLASS STAR T-LIGHT HOLDER', 'COLOUR GLASS. STAR T-LIGHT HOLDER'),
('85123A', 'CREAM HANGING HEART T-LIGHT HOLDER', 'WHITE HANGING HEART T-LIGHT HOLDER'),
('84228', 'HEN HOUSE WITH CHICK STANDING', 'HEN HOUSE W CHICK STANDING'),
('23402', 'HOME SWEEET HOME 3 PEG HANGER', 'HOME SWEET HOME 3 PEG HANGER'),
('21109', 'LARGE CAKE TOWEL, CHOCOLATE SPOTS', 'LARGE CAKE TOWEL CHOCOLATE SPOTS'),
('23457', 'LARGE PARLOUR FRAME', 'LARGE PARLOUR PICTURE FRAME'),
('22383', 'LUNCH BAG SUKI  DESIGN', 'LUNCH BAG SUKI DESIGN'),
('23209', 'LUNCH BAG VINTAGE DOILEY', 'LUNCH BAG VINTAGE DOILY'),
('23071', 'MARIE ANTOIENETT TRINKET BOX GOLD', 'MARIE ANTOINETTE TRINKET BOX GOLD'),
('23456', 'MEDIUM PARLOUR FRAME', 'MEDIUM PARLOUR PICTURE FRAME'),
('23148', 'MINITURE ANTIQUE ROSE HOOK IVORY', 'MINIATURE ANTIQUE ROSE HOOK IVORY'),
('23342', 'MINT DINER CLOCK', 'MINT DINER WALL CLOCK'),
('22407', 'MONEY BOX FIRST ADE DESIGN', 'MONEY BOX FIRST AID DESIGN'),
('72802B', 'OCEAN SCENT CANDLE JEWELLED DRAWER', 'OCEAN SCENT CANDLE IN JEWELLED BOX'),
('22812', 'PACK 3 BOXES CHRISTMAS PANNETONE', 'PACK 3 BOXES CHRISTMAS PANETTONE'),
('23380', 'PACK OF 12 DOILEY TISSUES', 'PACK OF 12 VINTAGE DOILY TISSUES'),
('22584', 'PACK OF 6 PANNETONE GIFT BOXES', 'PACK OF 6 PANETTONE GIFT BOXES'),
('22952', '72 CAKE CASES VINTAGE CHRISTMAS', '60 CAKE CASES VINTAGE CHRISTMAS'),
('23047', 'PAPER LANTERN 5 POINT STUDDED STAR', 'PAPER LANTERN 5 POINT SEQUIN STAR'),
('22129', 'PARTY CONES CANDY TREE DECORATION', 'PARTY CONES CANDY DECORATION'),
('22896', 'PEG BAG APPLE DESIGN', 'PEG BAG APPLES DESIGN'),
('85185B', 'PINK HORSE SOCK PUPPET', 'PINK HORSE SOCK PUPPET KIT'),
('23502', 'PLAYING CARDS VINTAGE DOILEY', 'PLAYING CARDS VINTAGE DOILY'),
('23462', 'ROCOCO WALL MIROR', 'ROCOCO WALL MIRROR WHITE'),
('23324', 'RUSTIC STRAWBERRY JAMPOT LARGE', 'RUSTIC STRAWBERRY JAM POT LARGE'),
('23325', 'RUSTIC STRAWBERRY JAMPOT SMALL', 'RUSTIC STRAWBERRY JAM POT SMALL'),
('23366', 'SET 12 COLOURING PENCILS DOILEY', 'SET 12 COLOURING PENCILS DOILY'),
('23366', 'SET 12 COLOUR PENCILS DOILEY', 'SET 12 COLOURING PENCILS DOILY'),
('23370', 'SET 36 COLOUR PENCILS DOILEY', 'SET 36 COLOURING PENCILS DOILY'),
('23360', 'SET 8 CANDLES VINTAGE DOILEY', 'SET 8 CANDLES VINTAGE DOILY'),
('23359', 'SET OF 12 T-LIGHTS VINTAGE DOILEY', 'SET OF 12 T-LIGHTS VINTAGE DOILY'),
('23237', 'SET OF 4 KNICK KNACK TINS LEAVES', 'SET OF 4 KNICK KNACK TINS LEAF'),
('23240', 'SET OF 4 KNICK KNACK TINS  DOILEY', 'SET OF 4 KNICK KNACK TINS DOILY'),
('23240', 'SET OF 4 KNICK KNACK TINS DOILEY', 'SET OF 4 KNICK KNACK TINS DOILY'),
('23236', 'STORAGE TIN VINTAGE DOILEY', 'STORAGE TIN VINTAGE DOILY'),
('79030D', 'TUMBLER, BAROQUE', 'TUMBLER BAROQUE'), 
('79030G', 'TUMBLER, NEW ENGLAND', 'TUMBLER NEW ENGLAND'),
('23466', 'TUSCAN VILLA DOVECOTE', 'TUSCAN VILLA DOVECOTE BIRD FEEDER'),
('23465', 'TUSCAN VILLA FEEDING STATION', 'TUSCAN VILLA BIRD FEEDER'),
('23188', 'VINTAGE  2 METRE FOLDING RULER', 'VINTAGE  2 METER FOLDING RULER'),
('20622', 'VIPPASSPORT COVER', 'VIP PASSPORT COVER');

-- check new mapping table

SELECT *
FROM description_mapping;

-- matching the incorrect descriptions to the corrected ones
-- checking the new corrections made against the staging table

SELECT DISTINCT 
    t1.StockCode, 
    t1.`Description` AS olddescription, 
    t2.CorrectDescription AS proposedcorrection
FROM online_retail_staging1 t1
JOIN description_mapping t2
  ON t1.StockCode = t2.StockCode
WHERE t1.`Description` = t2.InCorrectDescription
  AND t1.`Description` IS NOT NULL;
  
-- updating the table with corrections made after reviewing the descriptions 
-- the descritions were checked against the stockcode and investigated
-- the corrections made in the description mapping table include confirmed typos, wrong spellings, old identitfications and punctuation marks
-- all corrections made were verified and checked against all columns to make sure there are valid with evidence

UPDATE online_retail_staging1 t1
JOIN description_mapping t2
    ON t1.StockCode = t2.StockCode
    AND t1.`Description` = t2.IncorrectDescription
SET t1.`Description` = t2.CorrectDescription;

-- 1673 rows were corrected

SELECT *
FROM online_retail_staging1;

-- HANDLING OUTLIERS AND INVALID VALUES

SELECT MAX(UnitPrice) AS max_unitprice, MIN(UnitPrice) AS min_unitprice
FROM online_retail_staging1;

-- max unitprice came back as 38970.00 and min came back as -11062.06
-- investigate further to get the context of this values

SELECT *
FROM online_retail_staging1
WHERE UnitPrice IN (38970.00, -11062.06);

-- 3 rows were returned 
-- 2 rows with -11062.06. Both Invoiceno are A563186, A563187. StockCode is B and Description is Adjust bad debt
-- with this info, it seems the both of these are Adjustment transactions because of the A prefix in front of the invoice and the description
-- 1 row with 38970. Invoiceno has a C-prefix with means it's a cancellation or credit transaction
-- the description is Manual and it has a negative quantity (which is because of the transaction type)
-- these transactions will be flagged 

-- create column for LineRevenue (unitprice * quantity)

ALTER TABLE online_retail_staging1
ADD COLUMN LineRevenue DECIMAL(12,3);

UPDATE online_retail_staging1
SET LineRevenue = Quantity * UnitPrice;

-- check new column

SELECT Quantity, UnitPrice, LineRevenue
FROM online_retail_staging1;

-- flagging negative and 0 unitprices

SELECT * 
FROM online_retail_staging1
WHERE UnitPrice < 0;

-- 2 rows with negative values (the adjustment transactions)

SELECT * 
FROM online_retail_staging1
WHERE UnitPrice = 0;

-- 2510 rows returned with unitprice as 0
-- these rows includes NULL, regular and so many other special 
-- create a data quality flag for the unitprice

SELECT *,
CASE
    WHEN UnitPrice < 0 THEN 'Adjustment_Transaction'
    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%damage%' 
        OR LOWER(Description) LIKE '%broken%'
        OR LOWER(Description) LIKE '%lost%'
        OR LOWER(Description) LIKE '%missing%'
        OR LOWER(Description) LIKE '%breakages%'
        OR LOWER(Description) LIKE '%lost%'
        OR LOWER(Description) LIKE '%mouldy%'
        OR LOWER(Description) LIKE '%thrown%'
    ) THEN 'Zero_Price_Damage_Keyword'
    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%adjust%'
        OR LOWER(Description) LIKE '%found%'
        OR LOWER(Description) LIKE '%check%'
        OR LOWER(Description) LIKE '%count%'
        OR LOWER(Description) LIKE '%incorrectly%'
    ) THEN 'Zero_Price_Adjustment_Keyword'
	    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%dotcom%'
        OR LOWER(Description) LIKE '%amazon%'
        OR LOWER(Description) LIKE '%paypal%'
    ) THEN 'Zero_Price_3rd_Party_Keyword'
    WHEN UnitPrice = 0 THEN 'Zero_Price_Unclassified'
    WHEN UnitPrice > 0 AND (
		(Description) LIKE 'postage'
        OR (Description) LIKE 'manual'
        OR (Description) LIKE 'dotcom postage'
        OR (Description) LIKE 'bank charges'
        OR (Description) LIKE 'carriage'
        OR (Description) LIKE 'amazon fee'
	) THEN 'Operational/Non-Product_Transactions'
    ELSE 'Standard_Transaction'
END AS TransactionCategory
FROM online_retail_staging1;

-- first test on dummy table

DROP TABLE IF EXISTS online_retail_test;
CREATE TABLE online_retail_test AS
SELECT *
FROM online_retail_staging1;


ALTER TABLE online_retail_test
ADD COLUMN TransactionCategory VARCHAR(255);

UPDATE online_retail_test
SET TransactionCategory = CASE
    WHEN UnitPrice < 0 THEN 'Adjustment_Transaction'
    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%damage%' 
        OR LOWER(Description) LIKE '%broken%'
        OR LOWER(Description) LIKE '%lost%'
        OR LOWER(Description) LIKE '%missing%'
        OR LOWER(Description) LIKE '%breakages%'
        OR LOWER(Description) LIKE '%lost%'
        OR LOWER(Description) LIKE '%mouldy%'
        OR LOWER(Description) LIKE '%thrown%'
    ) THEN 'Zero_Price_Damage_Keyword'
    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%adjust%'
        OR LOWER(Description) LIKE '%found%'
        OR LOWER(Description) LIKE '%check%'
        OR LOWER(Description) LIKE '%count%'
        OR LOWER(Description) LIKE '%incorrectly%'
    ) THEN 'Zero_Price_Adjustment_Keyword'
	    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%dotcom%'
        OR LOWER(Description) LIKE '%amazon%'
        OR LOWER(Description) LIKE '%paypal%'
    ) THEN 'Zero_Price_3rd_Party_Keyword'
    WHEN UnitPrice = 0 THEN 'Zero_Price_Unclassified'
    WHEN UnitPrice > 0 AND (
		(Description) LIKE 'postage'
        OR (Description) LIKE 'manual'
        OR (Description) LIKE 'dotcom postage'
        OR (Description) LIKE 'bank charges'
        OR (Description) LIKE 'carriage'
        OR (Description) LIKE 'amazon fee'
	) THEN 'Operational/Non-Product_Transactions'
    ELSE 'Standard_Transaction'
END;


SELECT *
FROM online_retail_test
WHERE TransactionCategory NOT LIKE 'Standard_Transaction';

-- now to implement in our staging table

ALTER TABLE online_retail_staging1
ADD COLUMN TransactionCategory VARCHAR(255);

UPDATE online_retail_staging1
SET TransactionCategory = CASE
    WHEN UnitPrice < 0 THEN 'Adjustment_Transaction'
    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%damage%' 
        OR LOWER(Description) LIKE '%broken%'
        OR LOWER(Description) LIKE '%lost%'
        OR LOWER(Description) LIKE '%missing%'
        OR LOWER(Description) LIKE '%breakages%'
        OR LOWER(Description) LIKE '%lost%'
        OR LOWER(Description) LIKE '%mouldy%'
        OR LOWER(Description) LIKE '%thrown%'
    ) THEN 'Zero_Price_Damage_Keyword'
    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%adjust%'
        OR LOWER(Description) LIKE '%found%'
        OR LOWER(Description) LIKE '%check%'
        OR LOWER(Description) LIKE '%count%'
        OR LOWER(Description) LIKE '%incorrectly%'
    ) THEN 'Zero_Price_Adjustment_Keyword'
	    WHEN UnitPrice = 0 AND (
        LOWER(Description) LIKE '%dotcom%'
        OR LOWER(Description) LIKE '%amazon%'
        OR LOWER(Description) LIKE '%paypal%'
    ) THEN 'Zero_Price_3rd_Party_Keyword'
    WHEN UnitPrice = 0 THEN 'Zero_Price_Unclassified'
    WHEN UnitPrice > 0 AND (
		(Description) LIKE 'postage'
        OR (Description) LIKE 'manual'
        OR (Description) LIKE 'dotcom postage'
        OR (Description) LIKE 'bank charges'
        OR (Description) LIKE 'carriage'
        OR (Description) LIKE 'amazon fee'
	) THEN 'Operational/Non-Product_Transactions'
    ELSE 'Standard_Transaction'
END;

-- every transaction was flagged based on unitprice (negative price, zero price and positive price)
-- confirm changes to table

SELECT *
FROM online_retail_staging1
ORDER BY StockCode DESC;

-- now to negative or invalid quantities

SELECT *
FROM online_retail_staging1
WHERE Quantity < 0;

SELECT *
FROM online_retail_staging1
WHERE Quantity = 0;

-- 10587 rows returned with less than zero or negative values
-- 0 rows returned with 0 values
 
SELECT *
FROM online_retail_staging1
WHERE Quantity < 0 AND InvoiceNo LIKE 'C%';

-- 9251 rows returned with invoiceno with C-prefix, i assume this represents cancellation or credit

SELECT *
FROM online_retail_staging1
WHERE Quantity < 0 AND InvoiceNo NOT LIKE 'C%';

-- 1336 rows were returned with invoiceno without 'C' so these are some type of transactions
-- i'll check through the description of the ones without C to find some clue

SELECT *
FROM online_retail_staging1
WHERE Quantity < 0 AND InvoiceNo NOT LIKE 'C%';

-- most of the deescription for the descriptions were special cases which I created a quality flag for earlier
-- all the unitprice for all 1336 rows are zero, thereby making linerevenue zero
-- instead of deleting, i'll create a quality flag for quantity check

SELECT *, CASE
    WHEN Quantity > 0 THEN 'Standard_Sale'
    WHEN Quantity < 0 AND InvoiceNo LIKE 'C%' THEN 'Customer_Return_or_Credit'
    WHEN Quantity < 0 AND InvoiceNo NOT LIKE 'C%' THEN 'Other_Negative_Quantity'
    WHEN Quantity = 0 THEN 'Zero_Quantity_Check'
    ELSE 'Other'
END AS QuantityBehaviourFlag
FROM online_retail_staging1;

ALTER TABLE online_retail_staging1
ADD COLUMN QuantityBehaviourFlag VARCHAR(100);

UPDATE online_retail_staging1
SET QuantityBehaviourFlag = CASE
    WHEN Quantity > 0 THEN 'Standard_Sale'
    WHEN Quantity < 0 AND InvoiceNo LIKE 'C%' THEN 'Customer_Return_or_Credit'
    WHEN Quantity < 0 AND InvoiceNo NOT LIKE 'C%' THEN 'Other_Negative_Quantity'
    WHEN Quantity = 0 THEN 'Zero_Quantity_Check'
    ELSE 'Other'
END;

SELECT *
FROM online_retail_staging1;

-- handling NULL customerids

SELECT CustomerId, Count(*)
FROM online_retail_staging1
WHERE CustomerId IS NULL
GROUP BY CustomerId;

-- 135037 rows returned with missing or NULL customerid
-- investigating and trying to fill up missing ids
-- check for same invoices that have have customerid and some that are missing customerid

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN CustomerId IS NULL THEN 1 ELSE 0 END) AS missing_customer_rows,
    COUNT(DISTINCT CASE WHEN CustomerId IS NULL THEN InvoiceNo END) AS missing_invoices
FROM online_retail_staging1;

-- 3710 unique invoiceno are associated with the missing customerids
-- using these unique invoiceno to find out if some missing customerid invoiceno with customerid had another without

SELECT t1.InvoiceNo
FROM online_retail_staging1 t1
JOIN online_retail_staging1 t2 
	ON t1.InvoiceNo = t2.InvoiceNo
WHERE t1.CustomerId IS NULL AND t2.CustomerId IS NOT NULL
GROUP BY t1.InvoiceNo;

-- no row was returned 
-- this means none of the invoiceno share a customerid
-- from this, it is safe to assume the customers with ids may be guest customers
-- i'll create a column to flag the customers

SELECT *, CASE
WHEN CustomerId IS NULL THEN 'Unknown_Customer'
ELSE 'Registered_Customer'
END AS CustomerType 
FROM  online_retail_staging1;

-- create a new column for customertype

ALTER TABLE online_retail_staging1
ADD COLUMN CustomerType VARCHAR(255);

-- update table with new flagged column

UPDATE online_retail_staging1
SET CustomerType = CASE
WHEN CustomerId IS NULL THEN 'Unknown_Customer'
ELSE 'Registered_Customer'
END;

SELECT *
FROM online_retail_staging1;

-- Missing descriptions were not imputed because multiple StockCodes contained operational descriptions
-- (e.g., damaged, check, adjustment records) and product-description inconsistencies. 
-- To avoid introducing incorrect values, descriptions will be left like that

-- inspecting data

SELECT *
FROM online_retail_staging1;

-- checking for duplicates one final time afer making corrections to descriptions

WITH duplicateCTE AS (
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY  InvoiceNo, `Description`, Quantity, UnitPrice, InvoiceDate, CustomerId, Country, StockCode) AS row_num
FROM online_retail_staging1
)
SELECT *
FROM duplicateCTE
WHERE row_num > 1;

-- no extra duplicate found after cleaning

SELECT *
FROM online_retail_staging1
WHERE InvoiceNo = '575335' 
AND StockCode = '23203';

-- create the final cleaned table 

DROP TABLE IF EXISTS online_retail_cleaned;
CREATE TABLE online_retail_cleaned AS
WITH duplicateCTE AS (
SELECT *,
ROW_NUMBER() 
OVER(PARTITION BY  InvoiceNo, `Description`, Quantity, UnitPrice, InvoiceDate, CustomerId, Country, StockCode) AS row_num
FROM online_retail_staging1
)
SELECT InvoiceNo, StockCode, `Description`, Quantity, InvoiceDate, UnitPrice, 
CustomerId, Country, LineRevenue, TransactionCategory, QuantityBehaviourFlag, CustomerType
FROM duplicateCTE
WHERE row_num = 1;

-- inspect final table 

SELECT *
FROM online_retail_cleaned;

-- confirm datatypes

DESCRIBE online_retail_cleaned;

-- datatypes are correct

-- confirm row total

SELECT COUNT(*) AS total_rows
FROM online_retail_cleaned;

-- 536641 rows

-- FINAL REPORT
-- Row before cleaning was 541909 and after cleaning is 536640
-- Duplicate rows before was cleaning was 5268 and after cleaning is 0
-- Data quality flag check was created for 135037 rows with missing customerids 
-- Data quality flag check was created for 2512 rows with zero and less than unitprices 
-- Data quality flag check was created for 10587 rows with negative quantities
