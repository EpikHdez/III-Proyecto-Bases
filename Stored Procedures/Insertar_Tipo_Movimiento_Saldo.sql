USE AhorrosDB;
GO

CREATE PROCEDURE AHSP_InsertarTipoMovimientoSaldo
	@nombre VARCHAR(100)
AS
BEGIN
	INSERT INTO dbo.TipoMovimientoSaldo (Nombre)
		VALUES (@nombre);

	RETURN SCOPE_IDENTITY();
END