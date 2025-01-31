
-- Creating staging tables to not mess up raw data 
CREATE TABLE housing_stage1
LIKE nashville_housing;

INSERT housing_stage1
SELECT * 
FROM nashville_housing;

SELECT COUNT(*) FROM housing_stage1;


-- Remove duplicates
WITH dupe AS(
SELECT *,
ROW_NUMBER()OVER(PARTITION BY ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerName, OwnerAddress) AS row1
FROM housing_stage1
)

DELETE FROM housing_stage1
WHERE UniqueID IN (SELECT UniqueID FROM dupe WHERE row1 > 1);


-- Standerdize/fix data 
SELECT * FROM housing_stage1;

SELECT DISTINCT SoldAsVacant
FROM housing_stage1;

UPDATE housing_stage1
SET  SoldAsVacant =
CASE 
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant =  'Y' THEN 'Yes'
	ELSE SoldAsVacant
END;

-- capital M reads the month as its text version
UPDATE housing_stage1
SET saleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress)-1) ALSO WORKS
SELECT PropertyAddress, SUBSTRING_INDEX(PropertyAddress,',',1) AS PropAddress ,SUBSTRING_INDEX(PropertyAddress,',',-1) PropCity
FROM housing_stage1;

ALTER TABLE housing_stage1
ADD COLUMN 
PropAddress TEXT;

UPDATE housing_stage1
SET PropAddress = SUBSTRING_INDEX(PropertyAddress,',',1);

ALTER TABLE housing_stage1
ADD COLUMN 
PropCity TEXT;

UPDATE housing_stage1
SET PropCity = SUBSTRING_INDEX(PropertyAddress,',',-1);


ALTER TABLE housing_stage1
ADD COLUMN 
OwnerAdress1 TEXT;

ALTER TABLE housing_stage1
ADD COLUMN 
OwnerCity TEXT;

ALTER TABLE housing_stage1
ADD COLUMN 
OwnerState TEXT;

UPDATE housing_stage1
SET OwnerState = SUBSTRING_INDEX(OwnerAddress,',',-1),
	OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',-2),',',1),
    OwnerAddress1 = SUBSTRING_INDEX(OwnerAddress,',',1) 
;


-- NULL value handling 

-- Checking for null values that can be filled with related data 
SELECT *
FROM housing_stage1 AS t1
JOIN housing_stage1 AS t2
	ON t1.ParcelID = t2.ParcelID
    AND t1.UniqueID <> t2.UniqueID
WHERE (t1.YearBuilt IS NULL)
AND (t2.YearBuilt IS NOT NULL);

-- Only Property Address can be filled 
UPDATE  housing_stage1 AS t1
JOIN housing_stage1 AS t2
	ON t1.ParcelID = t2.ParcelID
    AND t1.UniqueID <> t2.UniqueID
SET t1.PropAddress = t2.PropAddress, t1.PropCity = t2.PropCity
WHERE (t1.PropAddress IS NULL AND t1.PropCity IS NULL)
AND (t2.PropAddress IS NOT NULL AND t2.PropCity IS NOT NULL);


-- Droping Cols 
ALTER TABLE housing_stage1
DROP COLUMN PropertyAddress;

ALTER TABLE housing_stage1
CHANGE COLUMN `OwnerAddress1` `OwnerAddress` TEXT NULL DEFAULT NULL ;

ALTER TABLE housing_stage1
DROP COLUMN OwnerAddress;


