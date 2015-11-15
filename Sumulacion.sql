USE AhorrosDB;
GO

CREATE PROCEDURE AHSP_Simulacion
	@pCantidadDias INT
AS
BEGIN
	BEGIN TRY
		DECLARE @fechaActual DATE, @fechaFinal DATE;

		SELECT @fechaActual = MIN(MS.PostDate) FROM dbo.MovimientoSaldo MS;
		SET @fechaFinal = DATEADD(DAY, @pCantidadDias, @fechaActual);

		WHILE @fechaActual < @fechaFinal
		BEGIN
			EXEC AHSP_ProcesoDiario @fechaActual;
			SET @fechaActual = DATEADD(DAY, 1, @fechaActual);
		END

		RETURN 1;
	END TRY
	BEGIN CATCH
		RETURN @@ERROR * -1;
	END CATCH
END
GO