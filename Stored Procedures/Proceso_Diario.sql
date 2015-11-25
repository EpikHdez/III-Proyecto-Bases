USE AhorrosDB;
GO

CREATE PROCEDURE AHSP_ProcesoDiario
	@pFechaProceso DATE
AS
BEGIN
	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		BEGIN TRAN Proceso
			----Estos calculos se realizan todos los dias---
			--Calcular interes diario y generar un movimiento con el mismo
			INSERT INTO dbo.MovimientoInteres (FK_Ahorro, FK_TipoMovimientoInteres, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 1, 'localhost', 'procesodiario', @pFechaProceso, dbo.AHFN_CalcularInteresDiario
					(AH.Saldo, TA.TasaDeInteres)
			FROM dbo.Ahorros AH INNER JOIN dbo.TipoAhorro TA
			ON AH.FK_TipoAhorro = TA.ID;

			--Actualizar el valor del interes acumulado en el ahorro con su respectivo movimiento
			--del día
			UPDATE AH
			SET AH.InteresAcumuladoDelMes = (AH.InteresAcumuladoDelMes + MI.Monto)
			FROM dbo.Ahorros AH INNER JOIN dbo.MovimientoInteres MI
			ON MI.FK_Ahorro = AH.ID
			WHERE MI.PostDate = @pFechaProceso;

			--Actualizar el saldo minímo si este es mayor al saldo del ahorro
			UPDATE SMPM
			SET SMPM.SaldoMinimo = AH.Saldo 
			FROM dbo.SaldoMinimoPorMes SMPM INNER JOIN dbo.Ahorros AH
			ON SMPM.FK_Ahorro = AH.ID
			WHERE (SMPM.Activo = 1) AND (AH.Saldo < SMPM.SaldoMinimo);
			----Fin de calculos diarios----

			----Estos calculos se realizan solamente si se esta en el dia corte del ahorro----
			--Crear movimiento de credito en MovimientoSaldo con respecto al interes 
			--acumulado del mes del ahorro
			INSERT INTO dbo.MovimientoSaldo (FK_Ahorro, FK_TipoMovimientoSaldo, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 1, 'localhost', 'procesodiario/diacorte', @pFechaProceso, 
					AH.InteresAcumuladoDelMes
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			--Realizar el cobro mensual por el servicio
			INSERT INTO dbo.MovimientoSaldo (FK_Ahorro, FK_TipoMovimientoSaldo, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 2, 'localhost', 'procesodiario/diacorte', @pFechaProceso, 
					TA.CostoServicioPorMes
			FROM dbo.Ahorros AH INNER JOIN dbo.TipoAhorro TA
			ON AH.FK_TipoAhorro = TA.ID
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			--Crear movimiento de debito en MovimientoInteres con respecto al interes
			--acumulado del mes del ahorro
			INSERT INTO dbo.MovimientoInteres (FK_Ahorro, FK_TipoMovimientoInteres, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 2, 'localhost', 'procesodiario/diacorte', @pFechaProceso, AH.InteresAcumuladoDelMes
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			--Resetar el monto del interes acumulado del mes para el nuevo mes
			UPDATE AH
			SET AH.InteresAcumuladoDelMes = 0.0
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			--Crear movimiento de debito en MovimientoSaldo con respecto a la multa del tipo de ahorro
			--si el SaldoMinimo en la tabla de saldo minimo es menos al saldo minimo en la tabla ahorro
			INSERT INTO dbo.MovimientoSaldo (FK_Ahorro, FK_TipoMovimientoSaldo, PostIn,
											PostBy, PostDate, Monto)
			SELECT AH.ID, 2, 'localhost', 'procesodiario/diacorte', @pFechaProceso, 
					TA.MontoMultaPorSaldoMinimo
			FROM dbo.Ahorros AH INNER JOIN dbo.TipoAhorro TA
			ON AH.FK_TipoAhorro = TA.ID INNER JOIN dbo.SaldoMinimoPorMes SMPM
			ON SMPM.FK_Ahorro = AH.ID
			WHERE (SMPM.SaldoMinimo < AH.SaldoMinimo) AND (AH.DiaCorte = DAY(@pFechaProceso));

			--Actualizar el registro de saldo minímo de ese mes, asignando la fecha de fin
			UPDATE SMPM
			SET SMPM.FechaFin = @pFechaProceso,
				SMPM.Activo = 0
			FROM dbo.SaldoMinimoPorMes SMPM INNER JOIN dbo.Ahorros AH
			ON SMPM.FK_Ahorro = AH.ID
			WHERE (AH.DiaCorte = DAY(@pFechaProceso)) AND (SMPM.Activo = 1);

			----Actualizar el estado de cuenta de ese mes con los valores correspondientes
			--UPDATE EC
			--SET EC.FechaFin = @pFechaProceso,
			--	EC.SumaCreditos = dbo.AHFN_ObtenerSumaCreditos(AH.ID, EC.FechaInicio, @pFechaProceso),
			--	EC.CantidadCreditos = dbo.AHFN_ObtenerCantidadCreditos(AH.ID, EC.FechaInicio, @pFechaProceso),
			--	EC.SumaDebitos = dbo.AHFN_ObtenerSumaDebitos(AH.ID, EC.FechaInicio, @pFechaProceso),
			--	EC.CantidadDebitos = dbo.AHFN_ObtenerCantidadDebitos(AH.ID, EC.FechaInicio, @pFechaProceso),
			--	EC.SaldoFinalReal = AH.Saldo
			--	EC.Activo = 0
			--FROM dbo.EstadoCuenta EC INNER JOIN dbo.Ahorros AH
			--ON EC.FK_Ahorro = AH.ID
			--WHERE (AH.DiaCorte = DAY(@pFechaProceso)) AND (EC.Activo = 1);

			--Crear un nuevo registro en saldo minímo para el siguiente mes de 
			INSERT INTO dbo.SaldoMinimoPorMes (FK_Ahorro, FechaInicio, FechaFin, SaldoMinimo)
			SELECT AH.ID, @pFechaProceso, NULL, AH.Saldo
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			----Crear un nuevo registro en estado de cuenta para el siguiente mes de los ahorros
			--INSERT INTO dbo.EstadoCuenta (FK_Ahorro, FechaInicio, FechaFin, SumaCreditos,
			--							CantidadCreditos, SumaDebitos, CantidadDebitos, SaldoFinalReal)
			--SELECT AH.ID, @pFechaProceso, NULL, 0.0, 0, 0.0, 0, 0.0
			--FROM dbo.Ahorros AH
			--WHERE AH.DiaCorte = DAY(@pFechaProceso);
		COMMIT TRAN Proceso;

		RETURN 1;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		RAISERROR(50001, 1, 1, @@ERROR);
	END CATCH
END
GO