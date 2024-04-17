USE [AdventureDW]
GO

/****** Object:  Table [dbo].[vac_Acumul]    Script Date: 06/04/2024 19:48:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[vac_Acumul](
	[NombreDep] [nchar](100) NULL,
	[DiasVacaciones] [int] NULL,
	[DiasIncapacidades] [int] NULL
) ON [PRIMARY]
GO

USE [AdventureDW]
GO

/****** Object:  Table [dbo].[ventas_Comparativas]    Script Date: 06/04/2024 19:49:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ventas_Comparativas](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[VentasReales] [numeric](18, 2) NULL,
	[VentasPlaneadas] [numeric](18, 2) NULL,
	[Territorio] [nchar](100) NULL
) ON [PRIMARY]
GO


USE [AdventureDW]
GO

/****** Object:  Table [dbo].[VentasXproducto]    Script Date: 06/04/2024 19:49:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[VentasXproducto](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[codigoProducto] [int] NULL,
	[Nombre] [nvarchar](100) NULL,
	[TotalVentas] [numeric](18, 2) NULL,
	[Subcategoria] [nvarchar](50) NULL,
	[Categoria] [nvarchar](50) NULL
) ON [PRIMARY]
GO



USE [AdventureDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Informe_ventas]    Script Date: 06/04/2024 19:49:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_Informe_ventas]

AS
BEGIN

    DELETE FROM [AdventureDW].[dbo].[ventas_Comparativas]
    
    INSERT INTO [AdventureDW].[dbo].[ventas_Comparativas] (Territorio,VentasPlaneadas,VentasReales)
    SELECT 
        T.CountryRegionCode AS Territorio,
    SUM(CAST(T.SalesYTD AS NUMERIC(18, 2))) as VentasPlaneadas, 
    SUM(CAST(O.TotalDue AS NUMERIC(18, 2))) as VentasReales    
    FROM
	AdventureWorks2014.Sales.SalesTerritory T 
	INNER JOIN AdventureWorks2014.Sales.SalesOrderHeader O ON T.TerritoryID = O.TerritoryID

	GROUP BY
	 T.CountryRegionCode;

END


USE [AdventureDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_InformeVacacionesIncapacidades]    Script Date: 06/04/2024 19:50:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_InformeVacacionesIncapacidades]

AS
BEGIN

    DELETE FROM [AdventureDW].[dbo].[vac_Acumul];
    
    INSERT INTO [AdventureDW].[dbo].[vac_Acumul] (NombreDep, DiasVacaciones, DiasIncapacidades)
    SELECT 
        d.Name AS NombreDep,
        SUM(e.VacationHours / 8) AS DiasVacaciones,
        SUM(e.SickLeaveHours / 8) AS DiasIncapacidades
    FROM
	AdventureWorks2014.HumanResources.Department d
    JOIN 
	AdventureWorks2014.HumanResources.EmployeeDepartmentHistory edh ON d.DepartmentID = edh.DepartmentID
    JOIN
	AdventureWorks2014.HumanResources.Employee e ON edh.BusinessEntityID = e.BusinessEntityID
    WHERE 
        edh.EndDate IS NULL
    GROUP BY 
        d.Name;

END


USE [AdventureDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_VentasxProducto]    Script Date: 06/04/2024 19:50:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_VentasxProducto]

AS
BEGIN

    DELETE FROM [AdventureDW].[dbo].[VentasXproducto]
    
    INSERT INTO [AdventureDW].[dbo].[VentasXproducto] (codigoProducto,Nombre,TotalVentas,Subcategoria,Categoria)
    SELECT 
	P.ProductID as codigoProducto,
	P.Name as Nombre,
	SUM(O.LineTotal) as TotalVentas,
	S.Name as Subcategoria,
	C.Name as Categoria
    FROM
	AdventureWorks2014.Sales.SalesOrderDetail O 
	INNER JOIN AdventureWorks2014.Production.Product P ON O.ProductID = P.ProductID
	INNER JOIN AdventureWorks2014.Production.ProductSubcategory S ON P.ProductSubcategoryID = S.ProductSubcategoryID
	INNER JOIN AdventureWorks2014.Production.ProductCategory C ON S.ProductCategoryID = C.ProductCategoryID

	GROUP BY
	 P.ProductID,P.Name,S.Name,C.Name

	 HAVING
	 SUM(O.LineTotal) > 1000000;

END