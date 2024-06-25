Select * 
From PortfolioDs..NashvilleHousing
--

--Standarize date format
Select SaleDateConverted, convert(date, saledate)
from PortfolioDs..NashvilleHousing

Update NashvilleHousing
SET saledate = CONVERT(date, saledate)

--In the end the saledate column is remaining untouched so the difference can be seen.

Alter Table NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioDs..NashvilleHousing
SET SaleDateConverted = CONVERT(date, saledate)
--

Select *
from PortfolioDs..NashvilleHousing
--Where PropertyAddress is null
order by ParcelID

--Since address is the same within the same ParcellID, the nulls in address 
--column can be populated by copying the address from the same ParcelID'''
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioDs..NashvilleHousing as a
Join PortfolioDs..NashvilleHousing as b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
WHere a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioDs..NashvilleHousing as a
Join PortfolioDs..NashvilleHousing as b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
WHere a.PropertyAddress is null
--


--Break the address into various individual columns
Select
SUBSTRING(PropertyAddress, 1,  CHARINDEX(',', PropertyAddress)-1) as Address,
--CHARINDEX is the value of the place where the ',' appears
--SUBSTRING(string, begining, longitude)
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
from PortfolioDs..NashvilleHousing

ALTER TABLE PortfolioDs..NashvilleHousing
add PropertySplitAddress Nvarchar(255);

UPDATE PortfolioDs..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1,  CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE PortfolioDs..NashvilleHousing
add PropertySplitCity Nvarchar(255);

UPDATE PortfolioDs..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

Select PropertySplitAddress, PropertySplitCity
From PortfolioDs..NashvilleHousing
--Now is easier to read.
--

--There are other method to split a column
--PARSENAME works with '.'
Select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as OwnerState
From PortfolioDs..NashvilleHousing
where OwnerAddress is not null

ALTER TABLE PortfolioDs..NashvilleHousing
add OwnerSplitAddress Nvarchar(255);

UPDATE PortfolioDs..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE PortfolioDs..NashvilleHousing
add OwnerSplitCity Nvarchar(255);

UPDATE PortfolioDs..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioDs..NashvilleHousing
add OwnerSplitState Nvarchar(255);

UPDATE PortfolioDs..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Easier to read and work with
Select OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
From PortfolioDs..NashvilleHousing
Where OwnerSplitState is not null
--

--Change Y and N from Sold as vacant to Yes and No
Select Distinct SoldAsVacant, COUNT(SoldAsVacant)
From PortfolioDs..NashvilleHousing
Group by SoldAsVacant
order by 2
--Most of the rows are correct with Yes and No

Select SoldAsVacant, CASE When SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
END
From PortfolioDs..NashvilleHousing
Order by 1

UPDATE PortfolioDs..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
END
--Now all rows are YES and NO
--


--Locating duplicates
With RowNumCTE AS (
Select *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) as row_num
From PortfolioDs..NashvilleHousing
)

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

--Deleting duplicates
With RowNumCTE AS (
Select *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) as row_num
From PortfolioDs..NashvilleHousing
)

DELETE
From RowNumCTE
Where row_num > 1
--

--Delete unused columns
Alter Table PortfolioDs..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

--Now data is ready to work with.
