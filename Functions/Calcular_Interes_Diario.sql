USE AhorrosDB;
GO

CREATE FUNCTION AHFN_CalcularInteresDiario (@pSaldo FLOAT, @pTasaInteres FLOAT)
RETURNS FLOAT
AS
BEGIN
	DECLARE @Result FLOAT = 0.0;
	SET @Result = (@pSaldo * (@pTasaInteres / 360.0));

	RETURN @Result;
END
GO