USE AhorrosDB;
GO

CREATE PROCEDURE AHSP_ProcesoDiario
	@pFechaProceso DATE
AS
BEGIN
	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		BEGIN TRANSACTION
			INSERT INTO dbo.MovimientoInteres (FK_Ahorro, FK_TipoMovimientoInteres, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 1, 'localhost', 'localhost', @pFechaProceso, dbo.AHFN_CalcularInteresDiario
					(AH.Saldo, TA.TasaInteresDiario)
			FROM dbo.Ahorros AH INNER JOIN dbo.TipoAhorro TA
			ON AH.FK_TipoAhorro = TA.ID;

			UPDATE AH
			SET AH.InteresAcumuladoDelMes = (AH.InteresAcumuladoDelMes + MI.Monto)
			FROM dbo.Ahorros AH INNER JOIN dbo.MovimientoInteres MI
			ON MI.FK_Ahorro = AH.ID
			WHERE MI.PostDate = @pFechaProceso;

			--Aun no se si es así como tiene que ser
			--UPDATE AH
			--SET AH.SaldoMinimo = SMPM.SaldoMinimo 
			--FROM dbo.Ahorros AH INNER JOIN dbo.SaldoMinimoPorMes SMPM
			--ON SMPM.FK_Ahorro = AH.ID
			--WHERE AH.Saldo < SMPM.SaldoMinimo;

			INSERT INTO dbo.MovimientoSaldo (FK_Ahorro, FK_TipoMovimientoSaldo, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 1, 'localhost', 'localhost', @pFechaProceso, AH.InteresAcumuladoDelMes
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			INSERT INTO dbo.MovimientoInteres (FK_Ahorro, FK_TipoMovimientoInteres, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 2, 'localhost', 'localhost', @pFechaProceso, AH.InteresAcumuladoDelMes
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			UPDATE AH
			SET AH.InteresAcumuladoDelMes = 0.0
			FROM dbo.Ahorros AH
			WHERE AH.DiaCorte = DAY(@pFechaProceso);

			INSERT INTO dbo.MovimientoSaldo (FK_Ahorro, FK_TipoMovimientoSaldo, PostIn,
						PostBy, PostDate, Monto)
			SELECT AH.ID, 2, 'localhost', 'localhost', @pFechaProceso, TA.MontoMultaPorSaldoMinimo
			FROM dbo.Ahorros AH INNER JOIN dbo.TipoAhorro TA
			ON AH.FK_TipoAhorro = TA.ID INNER JOIN dbo.SaldoMinimoPorMes SMPM
			ON SMPM.FK_Ahorro = AH.ID
			WHERE SMPM.SaldoMinimo < AH.SaldoMinimo AND AH.DiaCorte = DAY(@pFechaProceso);

			UPDATE SMPM
			SET SMPM.SaldoMinimo = AH.Saldo
			FROM dbo.SaldoMinimoPorMes SMPM INNER JOIN dbo.Ahorros AH
			ON SMPM.FK_Ahorro = AH.ID
			WHERE AH.DiaCorte = DAY(@pFechaProceso);
		COMMIT TRANSACTION;

		RETURN 1;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;

		RETURN @@ERROR * -1;
	END CATCH
END
GO