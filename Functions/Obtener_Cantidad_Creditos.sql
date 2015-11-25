USE AhorrosDB;
GO

CREATE FUNCTION AHFN_ObtenerCantidadCreditos(@IDAhorro INT, @FechaInicio DATE, @FechaFin DATE)
RETURNS INT
AS
BEGIN
	DECLARE @result FLOAT = 0.0;
	DECLARE @movs TABLE(ID INT IDENTITY(1, 1), IDMov INT);

	INSERT INTO @movs(IDMov)
	SELECT MS.ID
	FROM dbo.MovimientoSaldo MS
	WHERE (MS.FK_Ahorro = @IDAhorro) AND (MS.PostDate BETWEEN @FechaInicio AND @FechaFin)
			AND (MS.FK_TipoMovimientoSaldo = 1);

	SELECT @result = MAX(MV.ID) FROM @movs MV;

	RETURN @result;
END