CREATE DATABASE QL_bida
GO

USE QL_bida
GO

-- TABLEs

CREATE TABLE NhanVien
(
	MaNV varchar(50) PRIMARY KEY,
	SDT nvarchar(20) UNIQUE,
	NamSinh int CHECK(NamSinh < 2005 AND NamSinh > 1975),
	TenNV nvarchar(50) DEFAULT N'NO NAME',
	LuongNV float
)
GO

CREATE TABLE QuanLi
(
	MaNV varchar(50) UNIQUE,
	MatKhau nvarchar(20) NOT NULL

	FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV)
	ON UPDATE CASCADE
)
GO

CREATE TABLE KhachHang
(
	MaKH int IDENTITY(1,1) PRIMARY KEY,
	TenKH nvarchar(100) DEFAULT N'NO NAME',
	SDT nvarchar(20) UNIQUE
)
GO

CREATE TABLE Ban
(
	MaBan int IDENTITY(1,1) PRIMARY KEY,
	TinhTrang bit DEFAULT 0,	-- Trống: 0 -- Đang chơi: 1
	GioBD datetime NULL,	
	GioKT datetime NULL
)
GO

CREATE TABLE BienLai
(
	MaBienLai int IDENTITY(1,1) PRIMARY KEY,
	MaBan int  NOT NULL,
	MaNV varchar(50) NULL,
	MaKH int  NULL,
	ThoiGian float NOT NULL,
	TONGTIEN float NOT NULL,
	GioBD datetime NOT NULL,
	GioKT datetime NOT NULL

	FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH),
	FOREIGN KEY (MaBan) REFERENCES Ban(MaBan),
	FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV)
)
GO
---------------------------------------------------------------------------------------

-- TRIGGER - TRANSACTION

-- TRIGGER thêm bàn
CREATE TRIGGER tg_ThemBan ON Ban
AFTER UPDATE, INSERT 
AS
BEGIN
    DECLARE @tableCount int
    SELECT @tableCount = Count(*)
    FROM Ban

	BEGIN TRANSACTION
    IF( @tableCount > 20 )
		BEGIN
			Print N'Số bàn không được lớn hơn 20 bàn.'
			ROLLBACK TRANSACTION
		END
	ELSE COMMIT TRANSACTION
END
GO

-- Trigger xóa bàn
CREATE TRIGGER tg_XoaBan ON Ban
AFTER DELETE 
AS
BEGIN
	DECLARE @dangChoi bit
	SELECT @dangChoi = deleted.TinhTrang FROM deleted

	DECLARE @tableCount int
    SELECT @tableCount = Count(*) FROM Ban
	
	BEGIN TRANSACTION
    IF( @tableCount = 0 OR @dangChoi = 1 )
		begin
			Print N'KHÔNG THỂ XÓA BÀN! (bàn đang chơi hoặc bàn duy nhất)'
			ROLLBACK TRANSACTION
		end
	ELSE COMMIT TRANSACTION
END
GO

-- Trigger : phải có ít nhất 1 Quản lí (số Quản lí >= 1)
CREATE TRIGGER tg_SoQuanLi ON QuanLi
AFTER DELETE 
AS
BEGIN
    DECLARE @soQL int
    SELECT @soQL = Count(*)
    FROM QuanLi

	BEGIN TRANSACTION
    IF( @soQL = 0 )
		BEGIN
			Print N'Không thể xóa quản lí này! Phải có ít nhất 1 quản lí.'
			ROLLBACK TRANSACTION
		END
	ELSE COMMIT TRANSACTION
END
GO

-- Trigger Lương của NV
CREATE TRIGGER tg_SALARY ON NhanVien
AFTER UPDATE,INSERT 
AS
BEGIN
	DECLARE @LUONG AS FLOAT
	SELECT @LUONG=inserted.LuongNV FROM inserted

	BEGIN TRANSACTION
	IF (@LUONG < 3000000 OR @LUONG > 15000000)
		BEGIN
			PRINT N'Lương của NV tối thiểu là 3 triệu và tối đa là 15 triệu.'
			ROLLBACK TRANSACTION
		END
	ELSE COMMIT TRANSACTION
END
GO
----------------------------------------------------------------------------------------------------------------

-- VIEW

-- SELECT*FROM view_Bill
CREATE VIEW view_Bill AS
SELECT 
	BienLai.MaBienLai,
	BienLai.MaBan, 
	KhachHang.TenKH,
	NhanVien.TenNV,
	BienLai.ThoiGian,
	BienLai.TONGTIEN
FROM BienLai, NhanVien, KhachHang
WHERE NhanVien.MaNV = BienLai.MaNV AND KhachHang.MaKH = BienLai.MaKH;
GO


-- SELECT*FROM view_KhachHang
CREATE VIEW view_KhachHang AS
SELECT KhachHang.MaKH, KhachHang.TenKH, COUNT(BienLai.MaBienLai) AS SoLanChoi, SUM(BienLai.TONGTIEN) AS DaThanhToan, KhachHang.SDT
FROM KhachHang, BienLai
WHERE KhachHang.MaKH = BienLai.MaKH
GROUP BY KhachHang.MaKH, KhachHang.TenKH, KhachHang.SDT
GO

----------------------------------------------------------------------------------------------------------------------------------
-- ADD DATA

-- KHACH HANG
INSERT INTO KhachHang (TenKH, SDT)
VALUES	(N'Bien', N'0784112156'),
		(N'Tuan', N'0784112126'),
		(N'Khoa', N'0784112806'),
		(N'', N'113'),
		(N'KhachQuen', N'');

-- NHANVIEN
INSERT INTO NhanVien VALUES
(N'chuong', N'0782112135', 2001, N'Võ Đình Vĩnh Chương', 6000000),
(N'bao', N'0782112136', 2002, N'Ton That Gia Bao', 5000000),
(N'tuan', N'0782112131', 2003, N'Duong Thanh Tuan', 5000000),
(N'toan', N'0782112137', 2004, N'Nguyen Duc Toan', 5000000);

INSERT INTO QuanLi VALUES
(N'chuong', N'1'),
(N'bao', N'1');
GO
--------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------- CÁC CHỨC NĂNG ---------------------------------------
--			STORED PROCEDURE


-------------------------------------------
-- Xem Nhân Viên
CREATE PROCEDURE sp_loadNV
AS
	SELECT 
		TenNV, NamSinh, SDT, LuongNV, MaNV
	FROM NhanVien
GO
-- EXEC sp_loadNV

---------------------------------------
-- THÊM Nhân Viên
CREATE PROCEDURE sp_AddNV
@maNV nvarchar(50),
@sdt nvarchar(20),
@namsinh int,
@ten nvarchar(50),
@luong float
AS
BEGIN
	INSERT INTO NhanVien VALUES (@maNV,@sdt,@namsinh,@ten,@luong);
END
GO
--EXEC sp_AddNV N'test', '0s123456999', 1980, N'NHÂN VIÊN LÂU NĂM' ,10000000
--------------------------------------------------------------------
-- SỬA THÔNG TIN NV
CREATE PROCEDURE sp_Update_NV
@maNV nvarchar(50),
@sdt nvarchar(20),
@namsinh int,
@ten nvarchar(50),
@luong float
AS
Begin
	UPDATE NhanVien 
	SET TenNV=@ten, SDT=@sdt, NamSinh=@namsinh, LuongNV=@luong  where MaNV=@maNV;
End
GO
-- EXEC sp_Update_NV 'chuong', '0784112134', 2001, N'Võ Đình Vĩnh Chương', 70000002
------------------------------------------------------------------------
-- Xóa Nhân Viên
CREATE PROCEDURE sp_Delete_NV
@maNV nvarchar(50)
AS
DELETE from NhanVien where MaNV = @maNV;
GO
--EXEC sp_Delete_NV N'tuan'

-------------------------------------------------------------------
-- Thêm Quản Lí
CREATE PROCEDURE sp_AddQL
@username nvarchar(50),
@password nvarchar(20)
AS
BEGIN
	INSERT INTO QuanLi VALUES (@username,@password);
END
GO
-----------------------------------
-- Load Quản lí
CREATE PROCEDURE sp_loadQL
AS
	SELECT 
		NhanVien.TenNV,
		QuanLi.MaNV,
		QuanLi.MatKhau,
		NhanVien.NamSinh,
		NhanVien.SDT
	FROM NhanVien, QuanLi
	WHERE QuanLi.MaNV = NhanVien.MaNV
GO
------------------------------------
-- Thay đổi password ( QuanLi )
CREATE PROCEDURE sp_Update_QL  --change password
@username nvarchar(50),
@password nvarchar(20)
AS
Begin
	UPDATE QuanLi 
	SET MatKhau=@password where MaNV=@username;
End
GO
--------------------------
-- Xóa Quản lí
CREATE PROCEDURE sp_Delete_QL
@maNV nvarchar(50)
AS
DELETE from QuanLi where MaNV = @maNV;
GO
--EXEC sp_Delete_QL N'test'

----------------------------
-- Load Khách Hàng
CREATE PROCEDURE sp_loadKH
AS
	SELECT * FROM KhachHang
GO

---------------------------
-- Update KH
CREATE PROCEDURE sp_Update_KH
@makh int,
@ten nvarchar(50),
@sdt nvarchar(20)
AS
Begin
	UPDATE KhachHang 
	SET TenKH=@ten, SDT=@sdt where MaKH=@makh;
End
GO

--------------------------
--THÊM KHÁCH HÀNG
CREATE PROCEDURE sp_Add_KH
@ten nvarchar(30),
@sdt nvarchar(20)
AS
BEGIN
	INSERT INTO KhachHang(TenKH,SDT) VALUES (@ten,@sdt);
END
GO
--EXEC sp_Add_KH N'test','0285112104'
------------------
-- Xóa Khách Hàng
CREATE PROCEDURE sp_Delete_KH
@makh nvarchar(50)
AS
DELETE from KhachHang where MaKH = @makh;
GO

-----------------------------------------
-- Load danh sách Bàn
CREATE PROCEDURE sp_loadBan
AS 
	SELECT * FROM Ban
GO
--EXEC sp_loadBan

--------------------
--THÊM BÀN
CREATE PROCEDURE sp_Add_BAN
AS
BEGIN
	INSERT INTO Ban (TinhTrang, GioBD, GioKT)
	VALUES	(0, NULL,NULL);
END
GO
--EXEC sp_Add_BAN
-----------------------------------------------------
-- Xóa Bàn
CREATE PROCEDURE sp_Delete_Ban
@maban nvarchar(50)
AS
DELETE from Ban where MaBan = @maban;
GO
-------------------------------------------
-- Bắt đầu tính giờ chơi
CREATE PROCEDURE sp_StartGame
@maban int
AS
BEGIN
	UPDATE Ban
	SET TinhTrang = 1, GioBD = GETDATE()
	WHERE MaBan=@maban
END
GO
-----------------------------------------------
-- Kết thúc giờ chơi
CREATE PROCEDURE sp_EndGame
@maban int
AS
BEGIN
	DECLARE @dangchoi int = (SELECT TinhTrang FROM Ban where MaBan=@maban)
	IF (@dangchoi = 0)
		PRINT N'Bàn đang trống. Không thể kết thúc!'
	ELSE 
		UPDATE Ban
		SET TinhTrang = 0, GioKT = GETDATE()
		WHERE MaBan=@maban 
END
GO

------------------------------------------------

-- Thanh toán ( In BIll)
CREATE PROCEDURE sp_Add_Bill
@ma int,
@tg float,
@tien float,
@nv varchar(50),
@kh int,
@start datetime,
@end datetime
AS
BEGIN
	INSERT INTO BienLai(MaBan, ThoiGian, TONGTIEN, MaNV, MaKH ,GioBD, GioKT) 
	VALUES	(@ma, @tg, @tien, @nv, @kh, @start, @end);
END
GO
----------------------------------------------------

-- Cập nhật thông tin bàn sau khi đã đc Thanh Toán ( xóa giờ BD, KT ) 
CREATE PROCEDURE sp_Update_Ban
@maban int
AS
BEGIN
	UPDATE Ban
	SET GioBD = Null, GioKT = Null
	WHERE MaBan=@maban
END
GO




----------------------------------------------------------------------------------------------------------
--			FUNCTION


-- fn Doanh Thu
CREATE FUNCTION fn_DoanhThu()
RETURNS TABLE
AS
	RETURN
	(	SELECT COUNT(MaBienLai) AS N'TỔNG SỐ BIÊN LAI', SUM(TONGTIEN) AS N'TỔNG DOANH THU'
		FROM BienLai	)
GO
-- select* from dbo.fn_DoanhThu()

-----------------------------------

-- Hàm tính số lượng Nhân Viên
CREATE FUNCTION fn_SoLuongNV()
RETURNS INT
AS
BEGIN
	RETURN
	(SELECT COUNT(*) From NhanVien)
END
GO
-- select dbo.fn_SoLuongNV() AS N'Số lượng NV';
--------------------------------------------

-- fn Tổng lương NV
CREATE FUNCTION fn_TongLuongNV()
RETURNS Float
AS
BEGIN
	RETURN
	(SELECT SUM(LuongNV) From NhanVien)
END
GO
--select dbo.fn_TongLuongNV()
---------------------------------------------

-- fn Số lượng tất cả bàn
CREATE FUNCTION fn_SoLuongBan()
RETURNS INT
AS
BEGIN
	RETURN
	(SELECT COUNT(*) From Ban)
END
GO
-- select dbo.fn_SoLuongBan()

----------------------------------------
-- fn Số lượng bàn ĐANG CHƠI
CREATE FUNCTION fn_SoBanDangChoi()
RETURNS INT
AS
BEGIN
	RETURN
	( SELECT COUNT(*) From Ban Where TinhTrang=1 )
END
GO
-- select dbo.fn_SoBanDangChoi()

-----------------------------------------
-- Tổng thời gian chơi (phút)
CREATE FUNCTION fn_TimePlay
(
	@MaBan int
)
RETURNS INT
AS
BEGIN
	DECLARE @bd DATETIME = (SELECT GioBD FROM Ban Where MaBan=@MaBan);
	DECLARE @kt DATETIME = (SELECT GioKT FROM Ban Where MaBan=@MaBan);
	DECLARE @soGio INT = DATEDIFF(minute, @bd, @kt);
	
	RETURN @soGio
END
GO
-- SELECT dbo.fn_TimePlay(89) MINUTE

---------------------------------------------
-- Hàm tính tiền
CREATE FUNCTION fn_TinhTien
(
	@ThoiGian INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @gia float = 20000;
	DECLARE @tongTien float;
	SET @tongTien = @gia * @ThoiGian/60.0

	RETURN ROUND(@tongTien, 0);		--ROUND: làm tròn số
END
GO
--SELECT dbo.fn_TinhTien(91) VND

----------------------------------------------

-- Tạo user & phân quyền

USE [QL_bida]
GO

CREATE LOGIN [quanlibida] WITH PASSWORD = '123'
CREATE USER [quanlibida] FOR LOGIN [quanlibida]
GO
EXEC sp_addrolemember 'db_owner', 'quanlibida'
GO

-------------------------------------------------------------
use [QL_bida]
GO
CREATE LOGIN [nhanvienbida] WITH PASSWORD = '123'
CREATE USER [nhanvienbida] FOR LOGIN [nhanvienbida]
GO

GRANT EXECUTE ON [dbo].[sp_loadBan] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[sp_StartGame] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[fn_SoBanDangChoi] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[sp_EndGame] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[sp_Update_Ban] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[fn_SoLuongBan] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[sp_Add_BAN] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[fn_TimePlay] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[fn_TinhTien] TO [nhanvienbida]
GO
GRANT INSERT ON [dbo].[Ban] TO [nhanvienbida]
GO
GRANT SELECT ON [dbo].[Ban] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[sp_Add_Bill] TO [nhanvienbida]
GO
GRANT EXECUTE ON [dbo].[sp_Delete_Ban] TO [nhanvienbida]
GO
GRANT SELECT ON [dbo].[KhachHang] TO [nhanvienbida]
GO
GRANT SELECT ON [dbo].[NhanVien] ([MaNV]) TO [nhanvienbida]
GO
GRANT SELECT ON [dbo].[NhanVien] ([TenNV]) TO [nhanvienbida]
GO

-------------------------------------------------------------------------------