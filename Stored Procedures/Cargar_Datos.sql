USE AhorrosDB;
GO

CREATE PROCEDURE AHSP_CargarDatos
AS
BEGIN
	BEGIN TRY
		--Variables para el manejo del documento XML
		DECLARE @command NVARCHAR(500);
		DECLARE @document XML;
		DECLARE @xmlPath NVARCHAR(300);

		--Variables para el uso durante la iteración de lectura del XML
		DECLARE @lowA INT, @lowB INT;
		DECLARE @highA INT, @highB INT;
		DECLARE @IDTipoMovimientoSaldo INT;
		DECLARE @nombreTA VARCHAR(100);
		DECLARE @fechaConstitucion DATE;

		--Variables tablas para almacenar los datos leidos del documento XML
		DECLARE @tipoAhorroT TABLE (ID INT IDENTITY(1, 1), Nombre VARCHAR(100), TasaInteres FLOAT,
									Multa INT, CostoPorMes INT);
		DECLARE @ahorroT TABLE (ID INT IDENTITY(1, 1), FK_TipoAhorro INT, MontoOriginal FLOAT, 
								Saldo FLOAT, DiaCorte INT, FechaConstitucion DATE);
		DECLARE @movSaldoT TABLE (ID INT IDENTITY(1, 1), FK_Ahorro INT, FK_TipoMovimientoSaldo INT,
									Monto INT, Fecha DATE);

		--Comando necesario para poder cargar el documento xml desde cualquier ubicación
		SET @xmlPath = N'C:\XMLBases3.xml';
		SET @command = N'SET @document = (SELECT * FROM OPENROWSET(BULK ''' +
			@xmlPath + ''', SINGLE_BLOB) AS data)';
		
		--Ejecutar el comando anterior y asignar a la variable @document los datos del xml leido
		EXEC dbo.sp_executesql
			@command = @command,
			@params = N'@document xml output',
			@document = @document output

		--Lectura e inserción de datos en las respectivas variables tablas
		INSERT INTO @tipoAhorroT (Nombre, TasaInteres, Multa, CostoPorMes)
		SELECT TA.value('@Nombre', 'VARCHAR(100)'),
				TA.value('@TazaInteres', 'FLOAT'),
				TA.value('@MontoMultaSM', 'INT'),
				TA.value('@CostoServicioMes', 'INT')
		FROM @document.nodes('ROOT/TipoAhorro') AS TipoAhorro(TA);

		SELECT * FROM @tipoAhorroT;
		SET @lowA = 1;
		SELECT @highA = MAX(TA.ID) FROM @tipoAhorroT TA;

		--Iterar para obtener los ahorros dentro de cada tipo de ahorro
		WHILE @lowA <= @highA
		BEGIN
			SELECT @nombreTA = TA.Nombre FROM @tipoAhorroT TA WHERE TA.ID = @lowA;

			INSERT INTO @ahorroT (FK_TipoAhorro, MontoOriginal, Saldo, DiaCorte, FechaConstitucion)
			SELECT @lowA,
					AH.value('@Saldo', 'FLOAT'),
					AH.value('@Saldo', 'FLOAT'),
					AH.value('@DiaCorte', 'INT'),
					AH.value('@FechaConstitucion', 'DATE')
			FROM @document.nodes('ROOT/TipoAhorro/Ahorro') AS Ahorro(AH)
			WHERE AH.value('../@Nombre', 'VARCHAR(100)') = @nombreTA;
			
			SET @lowA = (@lowA + 1);
		END

		SELECT * FROM @ahorroT;
		SET @lowB = 1;
		SET @highB = 2--MAX(AH.ID) FROM @ahorroT AH;

		SELECT @lowB AS LOWB, @highB AS HIGHB;

		----Iterar para obtener los movimientos dentro de cada ahorro
		--WHILE @lowB <= @highB
		--BEGIN
		--	SELECT @fechaConstitucion = AH.FechaConstitucion FROM @ahorroT AH WHERE AH.ID = @lowB;

		--	INSERT INTO @movSaldoT (FK_Ahorro, FK_TipoMovimientoSaldo, Monto, Fecha)
		--	SELECT @lowB,
		--			1,
		--			MS.value('@Monto', 'INT'),
		--			MS.value('@Fecha', 'DATE')
		--	FROM @document.nodes('ROOT/TipoAhorro/Ahorro/MovSaldo') AS MovimentoSaldo(MS)
		--	WHERE MS.value('../@FechaConstitucion', 'DATE') = @fechaConstitucion;

		--	SET @lowB = (@lowB + 1);
		--END

		--SELECT * FROM @movSaldoT;

		RETURN 1;
	END TRY
	BEGIN CATCH
		RETURN @@ERROR * -1;
	END CATCH
END
