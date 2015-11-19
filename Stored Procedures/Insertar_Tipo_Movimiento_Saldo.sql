USE AhorrosDB;
GO

CREATE PROCEDURE AHSP_InsertarTipoMovimientoSaldo
	@nombre VARCHAR(100)
AS
BEGIN
	DECLARE @ID INT = 0;

	SELECT @ID = ID FROM dbo.TipoMovimientoSaldo WHERE Nombre = @nombre;

	IF @ID = 0
	BEGIN
		INSERT INTO dbo.TipoMovimientoSaldo (Nombre)
		VALUES (@nombre);

		SET @ID = SCOPE_IDENTITY();
	END

	RETURN @ID;
END