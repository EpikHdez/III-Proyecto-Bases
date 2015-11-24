USE AhorrosDB;
GO

CREATE FUNCTION AHFN_VerificarTipoMovimientoSaldo (@nombre VARCHAR(100))
RETURNS INT
AS
BEGIN
	DECLARE @ID INT = 0;

	SELECT @ID = TMS.ID FROM dbo.TipoMovimientoSaldo TMS WHERE TMS.Nombre = @nombre;

	RETURN @ID;
END
GO