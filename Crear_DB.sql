CREATE DATABASE AhorrosDB;
GO

USE AhorrosDB;
GO

CREATE TABLE TipoAhorro (
ID INT IDENTITY(1, 1),
Nombre VARCHAR(100),
TasaDeInteres FLOAT,
MontoMultaPorSaldoMinimo INT,
CostoServicioPorMes INT,
PRIMARY KEY (ID)
);
GO

CREATE TABLE TipoMovimientoSaldo (
ID INT IDENTITY(1, 1),
Nombre VARCHAR(100),
PRIMARY KEY (ID)
);
GO

CREATE TABLE TipoMovimientoInteres (
ID INT IDENTITY(1, 1),
Nombre VARCHAR(100),
PRIMARY KEY (ID)
);
GO

CREATE TABLE Ahorros (
ID INT IDENTITY(1, 1),
FK_TipoAhorro INT,
MontoOriginal FLOAT,
Saldo FLOAT,
InteresAcumuladoDelMes FLOAT,
DiaCorte INT,
SaldoMinimo FLOAT,
FechaConstitucion DATE,
PRIMARY KEY (ID),
FOREIGN KEY (FK_TipoAhorro) REFERENCES TipoAhorro (ID)
);
GO

CREATE TABLE SaldoMinimoPorMes (
ID INT IDENTITY(1, 1),
FK_Ahorro INT,
MesDelAño INT,
SaldoMinimo FLOAT,
PRIMARY KEY (ID),
FOREIGN KEY (FK_Ahorro) REFERENCES Ahorros (ID)
);
GO

CREATE TABLE MovimientoSaldo (
ID INT IDENTITY(1, 1),
FK_Ahorro INT,
FK_TipoMovimientoSaldo INT,
PostIn VARCHAR(100),
PostBy VARCHAR(100),
PostDate DATE,
Monto FLOAT,
PRIMARY KEY (ID),
FOREIGN KEY (FK_Ahorro) REFERENCES Ahorros (ID),
FOREIGN KEY (FK_TipoMovimientoSaldo) REFERENCES TipoMovimientoSaldo (ID)
);
GO

CREATE TABLE MovimientoInteres (
ID INT IDENTITY(1, 1),
FK_Ahorro INT,
FK_TipoMovimientoInteres INT,
PostIn VARCHAR(100),
PostBy VARCHAR(100),
PostDate DATE,
Monto FLOAT,
PRIMARY KEY (ID),
FOREIGN KEY (FK_Ahorro) REFERENCES Ahorros (ID),
FOREIGN KEY (Fk_TipoMovimientoInteres) REFERENCES TipoMovimientoInteres (ID)
);
GO