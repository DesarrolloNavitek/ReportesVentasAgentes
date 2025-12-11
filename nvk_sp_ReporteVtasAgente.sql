--EXEC dbo.nvk_sp_ReporteVtasAgente 2025,9,'8146',NULL

SET DATEFIRST 7  
SET ANSI_NULLS OFF  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET LOCK_TIMEOUT-1  
SET QUOTED_IDENTIFIER OFF  
GO 
IF EXISTS (SELECT * FROM SYSOBJECTS WHERE ID=OBJECT_ID('dbo.nvk_sp_ReporteVtasAgente') AND type = 'P')
DROP PROCEDURE dbo.nvk_sp_ReporteVtasAgente
GO
CREATE PROC dbo.nvk_sp_ReporteVtasAgente
@Ejercicio		INT,
@Periodo		INT,
@Agente			varchar(10),
@Usuario		VARCHAR(10)
	
AS
BEGIN
DECLARE
		@Equipo				VARCHAR(10),
		@DefAgente			VARCHAR(10),
		@TipoAgente			VARCHAR(15),
		@NombreAgente		VARCHAR(100),
		@EstatusAgente		VARCHAR(15),
		@GrupoAgente		VARCHAR(50),
		@Hoy				DATETIME = dbo.fnFechaSinHora(GETDATE()),
		@Fecha				DATETIME,
		@FechaD				DATETIME,
		@FechaA				DATETIME,
		@Mes				INT,
		@Anio				INT


			CREATE TABLE #nvk_tb_Agente	(
			Agente		VARCHAR(10),
			Nombre		VARCHAR(100)	NULL,
			Tipo		VARCHAR(15)		NULL,
			Estatus		VARCHAR(15)		NULL
		)


DECLARE @nvk_tbl_VentasAgentes TABLE (
	Gerente				VARCHAR(10)		NULL,
	Trimestre			INT,
	Periodo					INT,
	Ejercicio					INT,
	Agente						VARCHAR(10),
	NombreAgente				VARCHAR(100),
	EstatusAgente				VARCHAR(15),
	GrupoAgente					VARCHAR(50),
	Facturado					MONEY NULL,
	Cuota						MONEY NULL
)

	IF @Periodo <= MONTH(@Hoy)
	BEGIN
		SET	@Mes = @Periodo-MONTH(@Hoy)
	END ELSE 
	BEGIN
		IF @Ejercicio >= YEAR(@Hoy)
		BEGIN
			SET	@Mes = 0
			SET @Periodo = @Periodo-(@Periodo-MONTH(@Hoy))
		END ELSE
		BEGIN
			SET @Mes = @Periodo-MONTH(@Hoy)
			SET @Periodo = @Periodo
		END
	END

	IF @Ejercicio <= YEAR(@Hoy)
	BEGIN
		SET	@Anio = @Ejercicio-YEAR(@Hoy)
	END

	SET @Fecha = DATEADD(YEAR, (@Anio), DATEADD(MONTH, (@Mes), @Hoy))
	SET	@FechaD = (dbo.fnFechaSinHora(DATEADD(DAY, -DAY(@Fecha)+1, @Fecha)))
	SET	@FechaA = CASE	WHEN @Periodo IN (1,3,5,7,8,10,12) THEN dbo.fnFechaSinHora(DATEADD(DAY, 31-DAY(@FechaD), @FechaD))
						WHEN @Periodo IN (4,6,9,11) THEN dbo.fnFechaSinHora(DATEADD(DAY, 30-DAY(@FechaD), @FechaD))
					ELSE CASE WHEN YEAR(@FechaD)/4.0 - FLOOR(YEAR(@FechaD)/4.0) > 0 THEN  dbo.fnFechaSinHora(DATEADD(DAY, 28-DAY(@FechaD), @FechaD))
								ELSE dbo.fnFechaSinHora(DATEADD(DAY, 27-DAY(@FechaD), @FechaD))--27
						END
					END

	IF @Agente IN ('', '0', 'NULL')
		SET @Agente = NULL

	IF @Agente IS NULL
	BEGIN
		SELECT	@TipoAgente = a.Tipo, 
				@Equipo = Equipo,
				@NombreAgente = a.Nombre,
				@EstatusAgente = a.Estatus,
				@GrupoAgente = a.Grupo,
				@DefAgente = u.DefAgente
		FROM	Usuario				u
		LEFT	OUTER JOIN	Agente	a	ON	u.DefAgente = a.Agente
		WHERE	u.Usuario = @Usuario
	END ELSE
	BEGIN
		SELECT	@TipoAgente = a.Tipo, 
				@Equipo = Equipo,
				@NombreAgente = a.Nombre,
				@EstatusAgente = a.Estatus,
				@GrupoAgente = a.Grupo,
				@DefAgente = u.DefAgente
		FROM	Usuario				u
		RIGHT	OUTER JOIN	Agente	a	ON	u.DefAgente = a.Agente
		WHERE	a.Agente = @Agente
	END

	IF	@TipoAgente = 'Vendedor'
	BEGIN
		INSERT	#nvk_tb_Agente
		VALUES (@DefAgente, @NombreAgente, @TipoAgente, @EstatusAgente)
	END ELSE
	IF	@TipoAgente = 'Gerente Vtas'
	BEGIN
		INSERT	#nvk_tb_Agente
		VALUES (@DefAgente, @NombreAgente, @TipoAgente, @EstatusAgente)
		
		INSERT	#nvk_tb_Agente
		SELECT	e.Agente, a.Nombre, a.Tipo, a.Estatus
		FROM	EquipoAgente		e
		LEFT	OUTER JOIN Agente	a	ON	e.Agente = a.Agente
		WHERE	e.Equipo = @DefAgente
		AND		LEFT(e.Equipo, 2) <> 'AV'
	END ELSE
	IF	@TipoAgente = 'Admon Vtas'
	BEGIN
		INSERT	#nvk_tb_Agente
		VALUES (@DefAgente, @NombreAgente, @TipoAgente, @EstatusAgente)

		INSERT	#nvk_tb_Agente
		SELECT	Agente, Nombre, Tipo, Estatus
		FROM	Agente
		WHERE	Tipo IN ('Vendedor', 'Gerente Vtas', 'Admon Vtas')  
		AND		LEFT(Agente, 2) <> 'AV'
	END

	SELECT	e.Equipo, e.Agente
	INTO	#EquipoAgente
	FROM	EquipoAgente	e 
	WHERE	LEFT(Equipo, 2) <> 'AV'
	AND		NULLIF(Agente, '') IS NOT NULL

	INSERT	#EquipoAgente
	SELECT	DISTINCT Equipo, Equipo
	FROM	EquipoAgente
	WHERE	LEFT(Equipo, 2) <> 'AV'
	AND		NULLIF(Agente, '') IS NOT NULL

--SELECT * FROM #nvk_tb_Agente

INSERT INTO @nvk_tbl_VentasAgentes
SELECT
  ISNULL((SELECT TOP 1 e.Equipo --e.Gerente
				FROM	#EquipoAgente	e --GerenteAgenteAdmon	e
				WHERE	e.Agente = a.Agente AND e.Agente = v.AgenteMovimiento --AND e.Equipo = @DefAgente
				AND		LEFT(Equipo, 2) <> 'AV'
				),'DMOLINA')  AS Gerente,

	CASE WHEN MONTH(FechaEmision) IN (1,2,3) THEN 1
		 WHEN MONTH(FechaEmision) IN (4,5,6) THEN 2
		 WHEN MONTH(FechaEmision) IN (7,8,9) THEN 3
		 WHEN MONTH(FechaEmision) IN (10,11,12) THEN 4
			ELSE 0 END AS Trimestre,

	MONTH(FechaEmision)		AS Periodo, 
	YEAR(FechaEmision)		AS Ejercicio , 
	v.AgenteMovimiento		AS Agente,
	a.Nombre,
	a.Estatus,
	@GrupoAgente			AS 'GrupoAgente',
(SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado) + SUM(ImporteCancelNCargo)-SUM(ImporteNotaCred)) AS  Facturado,
    --(SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)) AS  Facturado,
	
	CASE WHEN MONTH(FechaEmision) = 1 THEN (MAX(ISNULL(Enero,0)))
		 WHEN MONTH(FechaEmision) = 2 THEN (MAX(ISNULL(Febrero,0)))
		 WHEN MONTH(FechaEmision) = 3 THEN (MAX(ISNULL(Marzo,0)))	
		 WHEN MONTH(FechaEmision) = 4 THEN (MAX(ISNULL(Abril,0)))
		 WHEN MONTH(FechaEmision) = 5 THEN (MAX(ISNULL(Mayo,0)))
		 WHEN MONTH(FechaEmision) = 6 THEN (MAX(ISNULL(Junio,0)))
		 WHEN MONTH(FechaEmision) = 7 THEN (MAX(ISNULL(Julio,0)))
		 WHEN MONTH(FechaEmision) = 8 THEN (MAX(ISNULL(Agosto,0)))
		 WHEN MONTH(FechaEmision) = 9 THEN (MAX(ISNULL(Septiembre,0)))
		 WHEN MONTH(FechaEmision) = 10 THEN (MAX(ISNULL(Octubre,0)))
		 WHEN MONTH(FechaEmision) = 11 THEN (MAX(ISNULL(Noviembre,0)))
		 WHEN MONTH(FechaEmision) = 12 THEN (MAX(ISNULL(Diciembre,0)))
			ELSE 0 END AS Cuota

		FROM	#nvk_tb_Agente									a
	    LEFT JOIN	CuotasAgentes								b	ON	b.Agente = a.Agente AND b.Ejercicio = @Ejercicio
		LEFT OUTER JOIN	nvk_vw_VentasNetas_Detalle_Cliente	v	ON	a.Agente = v.AgenteMovimiento
	   WHERE v.FechaEmision BETWEEN DATEADD(MONTH, -(@Periodo-1), @FechaD) AND @FechaA
		 AND a.Agente = ISNULL(@Agente, a.Agente)
		 AND v.Mov NOT IN ('Factura Activo Fijo')
	GROUP BY a.Agente,v.AgenteMovimiento,MONTH(FechaEmision),YEAR(FechaEmision),a.Nombre,a.Estatus
	ORDER BY MONTH(FechaEmision),YEAR(FechaEmision),v.AgenteMovimiento

SELECT * FROM @nvk_tbl_VentasAgentes

--SELECT Ejercicio,Periodo,Agente,NombreAgente, Valor,Importe 
--FROM @nvk_tbl_VentasAgentes
--UNPIVOT (
--Importe FOR Valor IN(Facturado,Cuota)
--) AS Resultado

END

