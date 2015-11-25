USE AhorrosDB;
GO

CREATE FUNCTION AHFN_ObtenerSumaDebitos(@IDAhorro INT, @FechaInicio DATE, @FechaFin DATE)
RETURNS FLOAT
AS
BEGIN
	DECLARE @result FLOAT = 0.0;

	SELECT @result = SUM(MS.Monto)
	FROM dbo.MovimientoSaldo MS 
	WHERE (MS.FK_Ahorro = @IDAhorro) AND (MS.PostDate BETWEEN @FechaInicio AND @FechaFin) AND
			(MS.FK_TipoMovimientoSaldo > 1);

	RETURN @Result;
END