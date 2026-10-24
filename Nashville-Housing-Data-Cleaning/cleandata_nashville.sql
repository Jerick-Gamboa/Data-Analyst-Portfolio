/* 	1. Back up raw data
	2. Review and understand the data
    3. Standardized the data
    4. Handle null values
    5. Check and remove duplicates
    6. Drop column (if needed)
    7. Save data
*/

SELECT * FROM nashville_housing;

DESCRIBE nashville_housing;

-- BACKUP THE DATA ----------------------------------------------------------------------------------------

-- Creating table exactly the same with the existing one for data cleaning

DROP TABLE IF EXISTS cleandata_nashville;
CREATE TABLE cleandata_nashville
LIKE nashville_housing;

-- This query is for inserting data inside the table intended for data cleaning
INSERT INTO  cleandata_nashville
SELECT * FROM nashville_housing;

-- Query for checking the created table
SELECT * FROM cleandata_nashville;

-- STANDARDIZING THE DATA ----------------------------------------------------------------------------------------

SELECT LandUse, COUNT(*) AS total
FROM cleandata_nashville
GROUP BY LandUse
ORDER BY 1;

-- This query is to check if there's a inconsistencies in data
-- Found out that VACANT RES LAND' & 'VACANT RESIDENTIAL LAND pertaining to one LandUse
SELECT DISTINCT(TRIM(LandUse)) AS LandUse
FROM cleandata_nashville;

-- This query removes spaces at the start and end of each value
UPDATE cleandata_nashville
SET LandUse = TRIM(LandUse);

-- To update 'VACANT RES LAND' to 'VACANT RESIDENTIAL LAND'
UPDATE cleandata_nashville
SET LandUse = 'VACANT RESIDENTIAL LAND'
WHERE LandUse = 'VACANT RES LAND';

-- To verify if the query works
SELECT DISTINCT(LandUse) FROM cleandata_nashville;

-- Checking Property Adress
SELECT DISTINCT(PropertyAddress) FROM cleandata_nashville;

-- Standardizing Property Adress
SELECT DISTINCT(REPLACE(REPLACE(TRIM(PropertyAddress), '  ', ' '), '  ', ' ')) AS PropertyAddress
FROM cleandata_nashville;

-- Standardizing Property Addresses with 2 spaces or more
UPDATE cleandata_nashville
SET PropertyAddress = REPLACE(REPLACE(TRIM(PropertyAddress), '  ', ' '), '  ', ' ')
WHERE PropertyAddress LIKE '%  %';

-- Standardizing Saledate
select SaleDate,
str_to_date(SaleDate,'%M %e, %Y') AS CleanSaleDate
from cleandata_nashville;

UPDATE cleandata_nashville
SET SaleDate = str_to_date(SaleDate,'%M %e, %Y');

ALTER TABLE cleandata_nashville
MODIFY COLUMN SaleDate DATE;

-- To check the value inside the SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), COUNT(*)
FROM cleandata_nashville
GROUP BY 1;

-- To update 'N' to 'No'
UPDATE cleandata_nashville
SET SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N';

SELECT DISTINCT(REPLACE(REPLACE(TRIM(OwnerAddress),'  ', ' '),'  ',' ')) AS OwnerAddress
FROM cleandata_nashville;

UPDATE cleandata_nashville
SET OwnerAddress = REPLACE(REPLACE(TRIM(OwnerAddress),'  ', ' '),'  ',' ')
WHERE  OwnerAddress LIKE '%  %';

-- HANDLING NULL OR MISSING VALUES ------------------------------------------------------------------------

-- Populate missing PropertyAddress using rows with the same ParcelID
SELECT t1.ParcelID, t1.PropertyAddress, t2.ParcelID,t2.PropertyAddress
FROM cleandata_nashville t1
JOIN cleandata_nashville t2
  ON t1.ParcelID = t2.ParcelID
  AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress = '' AND t2.PropertyAddress != '';

-- Update missing PropertyAddress using rows with the same ParcelID
UPDATE cleandata_nashville t1
JOIN cleandata_nashville t2
	ON t1.ParcelID = t2.ParcelID
SET t1.PropertyAddress = t2.PropertyAddress
WHERE t1.PropertyAddress = '' AND t2.PropertyAddress != '';

-- SPLITING PropertyAddress -----------------------------------------------------
SELECT PropertyAddress,
TRIM(SUBSTRING_INDEX(PropertyAddress,',', 1)) AS PropertyStreet,
TRIM(SUBSTRING_INDEX(PropertyAddress,',', -1)) AS PropertyCity
FROM cleandata_nashville;

-- This query is for adding PropertyStreet column
ALTER TABLE cleandata_nashville
ADD COLUMN PropertyStreet VARCHAR(250)
AFTER PropertyAddress;

-- Inserting value inside propertyStreet column
UPDATE cleandata_nashville
SET PropertyStreet = TRIM(SUBSTRING_INDEX(PropertyAddress,',', 1));

-- This query is for updating PropertyCity column
ALTER TABLE cleandata_nashville
ADD COLUMN PropertyCity VARCHAR(250)
AFTER PropertyStreet;

UPDATE cleandata_nashville
SET PropertyCity = TRIM(SUBSTRING_INDEX(PropertyAddress,',', -1));

SELECT OwnerAddress,
TRIM(SUBSTRING_INDEX(OwnerAddress, ',',1)) AS OwnerSplitAddress,
TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',2),',',-1)) AS OwnerSplitCity,
TRIM(SUBSTRING_INDEX(OwnerAddress, ',',-1)) AS OwnerSplitState
FROM cleandata_nashville;

ALTER TABLE cleandata_nashville
ADD COLUMN OwnerSplitAddress VARCHAR(250)
AFTER OwnerAddress;

UPDATE cleandata_nashville
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',',1));

ALTER TABLE cleandata_nashville
ADD COLUMN OwnerSplitCity VARCHAR(250)
AFTER OwnerSplitAddress;

UPDATE cleandata_nashville
SET OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',2),',',-1));

ALTER TABLE cleandata_nashville
ADD COLUMN OwnerSplitState VARCHAR(250)
AFTER OwnerSplitCity;

UPDATE cleandata_nashville
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',',-1));

-- This query is for checking if there's a duplicate value
WITH checking_duplicates AS (
SELECT *,
ROW_NUMBER () OVER(
					PARTITION BY ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerName, OwnerAddress, Acreage, TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath ORDER BY UniqueID) AS row_num
FROM cleandata_nashville 
)
SELECT * FROM checking_duplicates
WHERE row_num > 1;

-- DROP UNUSED COLUMN
ALTER TABLE cleandata_nashville
DROP COLUMN PropertyAddress, 
DROP COLUMN OwnerAddress;

SELECT COUNT(*) AS total_rows, COUNT(DISTINCT UniqueID) AS unique_ids
FROM cleandata_nashville;

SELECT DISTINCT(SoldAsVacant)
from cleandata_nashville;





SELECT * FROM cleandata_nashville;

