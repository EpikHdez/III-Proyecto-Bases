USE AhorrosDB;
GO

CREATE FUNCTION AHFN_AgregadoAlSaldo(@IDAhorro INT, @pFecha DATE)
RETURNS FLOAT
AS
BEGIN
	DECLARE @sumCreditos FLOAT = 0.0, @sumDebitos FLOAT = 0.0, @result FLOAT = 0.0;

	SELECT @sumCreditos = SUM(MS.Monto)
	FROM dbo.MovimientoSaldo MS
	WHERE (MS.FK_Ahorro = @IDAhorro) AND 
			(MS.FK_TipoMovimientoSaldo = 1) AND
			(MS.PostDate = @pFecha);

	SELECT @sumDebitos =  SUM(MS.Monto)
	FROM dbo.MovimientoSaldo MS
	WHERE (MS.FK_Ahorro = @IDAhorro) AND 
			(MS.FK_TipoMovimientoSaldo > 1) AND
			(MS.PostDate = @pFecha);

	IF @sumCreditos = NULL
		SET @sumCreditos = 0.0;

	IF @sumDebitos = NULL
		SET @sumDebitos = 0.0;

	SET @result = (@sumCreditos - @sumDebitos);

	RETURN @result;
END