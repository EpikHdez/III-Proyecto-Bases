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

		--Varibles para restrear la llave foranea del tipo movimiento saldo
		DECLARE @low INT, @high INT;
		DECLARE @nombre VARCHAR(100);

		--Variables tablas para almacenar los datos leidos del documento XML
		DECLARE @tipoAhorroT TABLE (ID INT IDENTITY(1, 1), Nombre VARCHAR(100), TasaInteres FLOAT,
									Multa INT, CostoPorMes INT);
		DECLARE @ahorrosT TABLE (ID INT IDENTITY(1, 1), FK_TipoAhorro INT, MontoOriginal FLOAT, 
								Saldo FLOAT, SaldoMinimo FLOAT, DiaCorte INT, FechaConstitucion DATE);
		DECLARE @movSaldoT TABLE (ID INT IDENTITY(1, 1), FK_Ahorro INT, FK_TipoMovimientoSaldo INT, 
								TipoMovimientoSaldoChar VARCHAR(100), Monto INT, Fecha DATE);

		--Comando necesario para poder cargar el documento xml desde cualquier ubicación
		SET @xmlPath = N'C:\XMLBases3.xml';
		SET @command = N'SET @document = (SELECT * FROM OPENROWSET(BULK ''' +
			@xmlPath + ''', SINGLE_BLOB) AS data)';
		
		--Ejecutar el comando anterior y asignar a la variable @document los datos del xml leido
		EXEC dbo.sp_executesql
			@command = @command,
			@params = N'@document xml output',
			@document = @document output

		--Evitar que cuente las inserciones en las variables tabla
		SET NOCOUNT ON;

		--Lectura e inserción de datos en las respectivas variables tablas desde el XML
		--Obtener todos los tipos de ahorros
		INSERT INTO @tipoAhorroT (Nombre, TasaInteres, Multa, CostoPorMes)
		SELECT TA.value('@Nombre', 'VARCHAR(100)'),
				TA.value('@TazaInteres', 'FLOAT'),
				TA.value('@MontoMultaSM', 'INT'),
				TA.value('@CostoServicioMes', 'INT')
		FROM @document.nodes('ROOT/TipoAhorro') AS TipoAhorro(TA);

		--Obtener los ahorros dentro de cada tipo de ahorro
		INSERT INTO @ahorrosT (FK_TipoAhorro, MontoOriginal, Saldo, SaldoMinimo, DiaCorte, 
							FechaConstitucion)
		SELECT TA.ID,
				AH.value('@Saldo', 'FLOAT'),
				AH.value('@Saldo', 'FLOAT'),
				AH.value('@SaldoMinimo', 'FLOAT'),
				AH.value('@DiaCorte', 'INT'),
				AH.value('@FechaConstitucion', 'DATE')
		FROM @document.nodes('ROOT/TipoAhorro/Ahorro') AS Ahorro(AH)
		INNER JOIN @tipoAhorroT TA
		ON TA.ID = AH.value('../@TAID', 'INT');

		--Obtener todos los movimientos dentro de cada ahorro
		INSERT INTO @movSaldoT (FK_Ahorro, TipoMovimientoSaldoChar, Monto, Fecha)
		SELECT AH.ID,
				MS.value('@TipoMov', 'VARCHAR(100)'),
				MS.value('@Monto', 'FLOAT'),
				MS.value('@Fecha', 'DATE')
		FROM @document.nodes('ROOT/TipoAhorro/Ahorro/MovSaldo') AS MovimientoSaldo(MS)
		INNER JOIN @AhorrosT AH
		ON AH.ID = MS.value('../@AHID', 'INT');

		--Insertar en la tabla de tipo de movimiento al saldo para poder asignar correctamente
		--la llave foranea en los movimientos al saldo
		SET @low = 1;
		SET @high = 33;

		WHILE @low <= @high
		BEGIN
			SELECT @nombre = MS.TipoMovimientoSaldoChar
			FROM @movSaldoT MS
			WHERE MS.ID = @low;

			IF dbo.AHFN_VerificarTipoMovimientoSaldo(@nombre) = 0
				EXEC dbo.AHSP_InsertarTipoMovimientoSaldo @nombre;

			SET @low = (@low + 1);
		END

		--Transaccion que pasa los datos de las variables tablas a las de la BD
		--y reasigna la llave foranea FK_TipoMovimientoSaldo en @movSaldoT para
		--que quede correctamente asignada antes de pasar a la BD
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		BEGIN TRAN Insercion
			UPDATE @movSaldoT
			SET FK_TipoMovimientoSaldo = dbo.AHFN_VerificarTipoMovimientoSaldo(TipoMovimientoSaldoChar);
			
			INSERT INTO dbo.TipoAhorro (Nombre, TasaDeInteres, MontoMultaPorSaldoMinimo, 
										CostoServicioPorMes)
			SELECT TA.Nombre, TA.TasaInteres, TA.Multa, TA.CostoPorMes
			FROM @tipoAhorroT TA;

			INSERT INTO dbo.Ahorros (FK_TipoAhorro, MontoOriginal, Saldo, InteresAcumuladoDelMes,
									DiaCorte, SaldoMinimo, FechaConstitucion)
			SELECT AH.FK_TipoAhorro, AH.MontoOriginal, AH.Saldo, 0.0, AH.DiaCorte, AH.SaldoMinimo,
					AH.FechaConstitucion
			FROM @ahorrosT AH;

			INSERT INTO dbo.MovimientoSaldo (FK_Ahorro, FK_TipoMovimientoSaldo, PostIn, PostBy,
											PostDate, Monto)
			SELECT MS.FK_Ahorro, MS.FK_TipoMovimientoSaldo, 'localhost', 'localhost',
					MS.Fecha, MS.Monto
			FROM @movSaldoT MS;
		
		COMMIT TRAN Insercion;

		--Restar el valor de NOCOUNT y retornar resultado exitoso
		SET NOCOUNT OFF;
		RETURN 1;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		RETURN @@ERROR * -1;
	END CATCH
END
