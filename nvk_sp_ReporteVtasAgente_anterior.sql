--EXEC dbo.nvk_sp_ReporteVtasAgente_completo NULL,NULL,12,2025
IF EXISTS (SELECT * FROM SYSOBJECTS WHERE ID=OBJECT_ID('dbo.nvk_sp_ReporteVtasAgente_completo') AND type = 'P')
DROP PROCEDURE dbo.nvk_sp_ReporteVtasAgente_completo
GO
CREATE PROC dbo.nvk_sp_ReporteVtasAgente_completo
@Agente			varchar(10),
@Usuario		VARCHAR(10),
@Periodo		INT,
@Ejercicio		INT		
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
		@FechaDAcum			DATETIME,
		@FechaAAcum			DATETIME,
		@UnAnioAtrasD		DATETIME,
		@UnAnioAtrasA		DATETIME,
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
	Perdiodo					INT,
	Ejercicio					INT,
	Agente						VARCHAR(10),
	NombreAgente				VARCHAR(100),
	EstatusAgente				VARCHAR(15),
	GrupoAgente					VARCHAR(50),
	Facturado					MONEY NULL,
	FacturadoEnero				FLOAT,
	FacturadoFebrero			FLOAT,
	FacturadoMarzo				FLOAT,
	FacturadoAbril				FLOAT,
	FacturadoMayo				FLOAT,
	FacturadoJunio				FLOAT,
	FacturadoJulio				FLOAT,
	FacturadoAgosto				FLOAT,
	FacturadoSeptiembre			FLOAT,
	FacturadoOctubre			FLOAT,
	FacturadoNoviembre			FLOAT,
	FacturadoDiciembre			FLOAT,
	CuotaEnero					FLOAT,
	CuotaFebrero				FLOAT,
	CuotaMarzo					FLOAT,
	CuotaAbril					FLOAT,
	CuotaMayo					FLOAT,
	CuotaJunio					FLOAT,
	CuotaJulio					FLOAT,
	CuotaAgosto					FLOAT,
	CuotaSeptiembre				FLOAT,
	CuotaOctubre				FLOAT,
	CuotaNoviembre				FLOAT,
	CuotaDiciembre				FLOAT
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


	SET	@FechaDAcum	= DATEADD(MONTH, -12, @FechaD)
	SET	@FechaAAcum	= DATEADD(MONTH, -12, @FechaA)
	SET	@UnAnioAtrasD	= DATEADD(MONTH, -12, @FechaDAcum)
	SET	@UnAnioAtrasA	= DATEADD(MONTH, -12, @FechaAAcum)

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
		WHERE	u.Usuario = 'JRIVERA4'--@Usuario
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
	MONTH(FechaEmision)		AS Perdiodo, 
	YEAR(FechaEmision)		AS Ejercicio , 
	v.AgenteMovimiento		AS Agente,
	a.Nombre,
	a.Estatus,
	@GrupoAgente			AS 'GrupoAgente',

	(SUM(v.ImporteFactura-ImporteDevuelto-v.ImporteCancelado-v.ImporteDiversos)+SUM(v.ImporteCancelNCargo-v.ImporteNotaCred)) AS FacturadoAcumulado,
				
			CASE WHEN MONTH(v.FechaEmision) = 1
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoEnero,
			CASE WHEN MONTH(v.FechaEmision) = 2
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoFebrero,
			CASE WHEN MONTH(v.FechaEmision) = 3
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)

				))
				ELSE 0
			END						AS FacturadoMarzo,
			CASE WHEN MONTH(v.FechaEmision) = 4
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoAbril,
			CASE WHEN MONTH(v.FechaEmision) = 5
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoMayo,
			CASE WHEN MONTH(v.FechaEmision) = 6
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoJunio,
			CASE WHEN MONTH(v.FechaEmision) = 7
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoJulio,
			CASE WHEN MONTH(v.FechaEmision) = 8
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoAgosto,
			CASE WHEN MONTH(v.FechaEmision) = 9
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoSeptiembre,
			CASE WHEN MONTH(v.FechaEmision) = 10
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoOctubre,
			CASE WHEN MONTH(v.FechaEmision) = 11
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoNoviembre,
			CASE WHEN MONTH(v.FechaEmision) = 12
				THEN ((SUM(ImporteFactura)-SUM(ImporteDevuelto)-SUM(ImporteCancelado)+SUM(ImporteAnticipo)-SUM(ImporteAplicacion)-SUM(ImporteNotaCred)
				))
				ELSE 0
			END						AS FacturadoDiciembre,
			CASE WHEN MONTH(v.FechaEmision) = 1
				THEN ISNULL(MAX(b.Enero),0)
				ELSE 0
			END						AS CuotaEnero,
			CASE WHEN MONTH(v.FechaEmision) = 2
				THEN ISNULL(MAX(b.Febrero),0)
				ELSE 0
			END						AS CuotaFebrero,
			CASE WHEN MONTH(v.FechaEmision) = 3
				THEN ISNULL(MAX(b.Marzo),0)
				ELSE 0
			END						AS CuotaMarzo,
			CASE WHEN MONTH(v.FechaEmision) = 4
				THEN ISNULL(MAX(b.Abril),0)
				ELSE 0
			END						AS CuotaAbril,
			CASE WHEN MONTH(v.FechaEmision) = 5
				THEN MAX(ISNULL(b.Mayo,0))
				ELSE 0
			END						AS CuotaMayo,
			CASE WHEN MONTH(v.FechaEmision) = 6
				THEN ISNULL(MAX(b.Junio),0)
				ELSE 0
			END						AS CuotaJunio,	
			CASE WHEN MONTH(v.FechaEmision) = 7
				THEN ISNULL(MAX(b.Julio),0)
				ELSE 0
			END						AS CuotaJulio,
			CASE WHEN MONTH(v.FechaEmision) = 8
				THEN ISNULL(MAX(b.Agosto),0)
				ELSE 0
			END						AS CuotaAgosto,
			CASE WHEN MONTH(v.FechaEmision) = 9
				THEN ISNULL(MAX(b.Septiembre),0)
				ELSE 0
			END						AS CuotaSeptiembre,
			CASE WHEN MONTH(v.FechaEmision) = 10
				THEN ISNULL(MAX(b.Octubre),0)
				ELSE 0
			END						AS CuotaOctubre,
			CASE WHEN MONTH(v.FechaEmision) = 11
				THEN ISNULL(MAX(b.Noviembre),0)
				ELSE 0
			END						AS CuotaNoviembre,
			CASE WHEN MONTH(v.FechaEmision) = 12
				THEN ISNULL(MAX(b.Diciembre),0)
				ELSE 0
			END						AS CuotaDiciembre

		FROM	#nvk_tb_Agente									a
	    LEFT JOIN	CuotasAgentes								b	ON	b.Agente = a.Agente AND b.Ejercicio = @Ejercicio
		LEFT OUTER JOIN	nvk_vw_VentasNetas_Detalle_Cliente	v	ON	a.Agente = v.AgenteMovimiento-- v.AgenteCliente--c.Cliente = v.Cliente
	   WHERE v.FechaEmision BETWEEN DATEADD(MONTH, -(@Periodo-1), @FechaD) AND @FechaA--YEAR(FechaEmision) = @Ejercicio
	    --AND		MONTH(FechaEmision) = @Periodo
		 AND a.Agente = ISNULL(@Agente, a.Agente)
		 AND v.Mov NOT IN ('Factura Activo Fijo')
	GROUP BY a.Agente,v.AgenteMovimiento,MONTH(FechaEmision),YEAR(FechaEmision),a.Nombre,a.Estatus
	ORDER BY MONTH(FechaEmision),YEAR(FechaEmision),v.AgenteMovimiento
	   --GROUP BY MONTH(FechaEmision),year(FechaEmision),V.AgenteMovimiento,a.Nombre ,a.Estatus, b.Enero,b.Febrero,b.Marzo,b.Abril,b.Mayo,b.Junio,b.Julio,b.Agosto,b.Septiembre,b.Octubre,b.Noviembre,b.Diciembre
	   --ORDER BY MONTH(FechaEmision),v.AgenteMovimiento,YEAR(FechaEmision),8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31

SELECT * FROM @nvk_tbl_VentasAgentes

END