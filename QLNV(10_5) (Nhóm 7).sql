Create database QLNV1
go
use QLNV1 
Go

-- Tạo bảng PhongBan
CREATE TABLE PhongBan (
    MaPB nvarchar(100) PRIMARY KEY,
    TenPB nvarchar(100)
);

-- Tạo bảng VaiTro
CREATE TABLE VaiTro (
    MaVaiTro nvarchar(100) PRIMARY KEY,
    TenVaiTro nvarchar(100)
);

-- Tạo bảng NhanVien
CREATE TABLE NhanVien (
    MANV nvarchar(100) PRIMARY KEY,
    TenNV nvarchar(100),
    NgaySinh date,
    Email nvarchar(100),
    Luong varbinary(MAX),
    MST nvarchar(100),
    HoatDong bit,
    MaPB nvarchar(100)
);

-- Tạo mối quan hệ giữa NhanVien và PhongBan
ALTER TABLE NhanVien
ADD CONSTRAINT FK_NhanVien_PhongBan
FOREIGN KEY (MaPB) REFERENCES PhongBan(MaPB);

-- Tạo bảng lưu trữ thông tin về vai trò của nhân viên trong phòng ban
CREATE TABLE NhanVien_VaiTro (
    MANV nvarchar(100),
    MaVaiTro nvarchar(100),
    PRIMARY KEY (MANV, MaVaiTro),
    FOREIGN KEY (MANV) REFERENCES NhanVien(MANV),
    FOREIGN KEY (MaVaiTro) REFERENCES VaiTro(MaVaiTro)
);
GO

-- Tạo view để áp dụng chính sách quản lý cho thông tin nhân viên
CREATE OR ALTER VIEW QuanLyNhanVien AS
WITH DecryptedData AS (
    SELECT 
        nv.MANV, 
        TenNV, 
        NgaySinh, 
        Email, 
        Luong = 
            CASE 
                WHEN IS_MEMBER('KeToan') = 1 OR IS_MEMBER('QuanLyPhongBan') = 1 OR IS_MEMBER('TruongPhongHR') = 1 
                THEN CONVERT(BIGINT, DECRYPTBYKEY(Luong)) 
                WHEN IS_MEMBER('NhanVienPhongBan') = 1 
                THEN NULL 
                ELSE NULL 
            END,
        MST, 
        HoatDong, 
        nv.MaPB
    FROM 
        NhanVien nv
		LEFT JOIN NhanVien_VaiTro nvvt ON nv.MANV = nvvt.MANV
    WHERE 
        (IS_MEMBER('NhanVienPhongBan') = 1 AND nv.MaPB = (SELECT MaPB FROM NhanVien WHERE MANV = ORIGINAL_LOGIN()))
        OR
        (IS_MEMBER('QuanLyPhongBan') = 1 AND nv.MaPB = (SELECT MaPB FROM NhanVien WHERE MANV = ORIGINAL_LOGIN()))
        OR
        (IS_MEMBER('HR') = 1 AND MaVaiTro != 'HR')
        OR
        (IS_MEMBER('TruongPhongHR') = 1)
        OR
        (IS_MEMBER('KeToan') = 1)
)
SELECT * FROM DecryptedData;
GO

select * from QuanLyNhanVien;

-- Tạo khóa mã hóa cho lương
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'WindowsDefender';

-- Tạo chứng chỉ cho lương
CREATE CERTIFICATE SalaryCert WITH SUBJECT = 'Nhom07';

-- Tạo khóa mật khẩu cho lương
CREATE SYMMETRIC KEY SalaryKey WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE SalaryCert;
GO 

-- Mở khóa symmetric key trước khi sử dụng view
OPEN SYMMETRIC KEY SalaryKey DECRYPTION BY CERTIFICATE SalaryCert;

-- Tạo role và phân quyền cho các đơn vị trong công ty
CREATE ROLE HR;
CREATE ROLE KeToan;
CREATE ROLE NhanVienPhongBan;
CREATE ROLE QuanLyPhongBan;
CREATE ROLE TruongPhongHR;

SELECT name AS RoleName
FROM sys.database_principals
WHERE type = 'R' AND is_fixed_role = 0;

-- Grant permissions to HR role
GRANT INSERT, SELECT, UPDATE ON QuanLyNhanVien TO HR;
GRANT VIEW DEFINITION ON CERTIFICATE::SalaryCert TO HR;
GRANT CONTROL ON CERTIFICATE::SalaryCert TO HR;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SalaryKey TO HR;

-- Grant permissions to TruongPhongHR role
GRANT INSERT, SELECT, UPDATE ON QuanLyNhanVien TO TruongPhongHR;
GRANT VIEW DEFINITION ON CERTIFICATE::SalaryCert TO TruongPhongHR;
GRANT CONTROL ON CERTIFICATE::SalaryCert TO TruongPhongHR;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SalaryKey TO TruongPhongHR;

-- Grant permissions to KeToan role
GRANT SELECT ON QuanLyNhanVien TO KeToan;
GRANT UPDATE ON QuanLyNhanVien(Luong, MST) TO KeToan;
GRANT VIEW DEFINITION ON CERTIFICATE::SalaryCert TO KeToan;
GRANT CONTROL ON CERTIFICATE::SalaryCert TO KeToan;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SalaryKey TO KeToan;

-- Grant permissions to NhanVienPhongBan role
GRANT SELECT ON QuanLyNhanVien TO NhanVienPhongBan;
GRANT VIEW DEFINITION ON CERTIFICATE::SalaryCert TO NhanVienPhongBan;
GRANT CONTROL ON CERTIFICATE::SalaryCert TO NhanVienPhongBan;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SalaryKey TO NhanVienPhongBan;

-- Grant permissions to QuanLyPhongBan role
GRANT SELECT ON QuanLyNhanVien TO QuanLyPhongBan;
GRANT VIEW DEFINITION ON CERTIFICATE::SalaryCert TO QuanLyPhongBan;
GRANT CONTROL ON CERTIFICATE::SalaryCert TO QuanLyPhongBan;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SalaryKey TO QuanLyPhongBan;

-- Chèn dữ liệu vào bảng PhongBan
INSERT INTO PhongBan (MaPB, TenPB)
VALUES ('PB001', N'Phòng Kế toán'),
       ('PB002', N'Phòng Nhân sự'),
       ('PB003', N'Phòng Kỹ thuật');
GO 
-- Chèn dữ liệu vào bảng VaiTro
INSERT INTO VaiTro (MaVaiTro, TenVaiTro)
VALUES ('VT001', N'Nhân viên'),
       ('VT002', N'Quản lý'),
       ('VT003', N'Trưởng phòng');
GO 

CREATE OR ALTER PROCEDURE ThemNhanVienMoi (
    @MaNV NVARCHAR(100),
    @TenNV NVARCHAR(100),
    @NgaySinh DATE,
    @Email NVARCHAR(100),
    @Luong BIGINT,
    @MST NVARCHAR(100),
    @HoatDong BIT,
    @MaPB NVARCHAR(100),
    @MaVaiTro NVARCHAR(100),
    @MatKhau NVARCHAR(100)
)
AS
BEGIN
    -- Bắt đầu transaction
    BEGIN TRANSACTION;

    BEGIN TRY
        OPEN SYMMETRIC KEY SalaryKey DECRYPTION BY CERTIFICATE SalaryCert;
        DECLARE @LuongMaHoa VARBINARY(MAX);
        SET @LuongMaHoa = ENCRYPTBYKEY(KEY_GUID('SalaryKey'), CONVERT(VARBINARY(MAX), @Luong));
        CLOSE SYMMETRIC KEY SalaryKey;

        -- Thêm nhân viên mới vào bảng NhanVien
        INSERT INTO NhanVien (MANV, TenNV, NgaySinh, Email, Luong, MST, HoatDong, MaPB)
        VALUES (@MaNV, @TenNV, @NgaySinh, @Email, @LuongMaHoa, @MST, @HoatDong, @MaPB);

        -- Thêm vai trò của nhân viên vào bảng NhanVien_VaiTro
        INSERT INTO NhanVien_VaiTro(MANV, MaVaiTro)
        VALUES (@MaNV, @MaVaiTro);
        
        -- Tạo login cho nhân viên
        DECLARE @LoginName NVARCHAR(100) = @MaNV;
        DECLARE @CreateLogin NVARCHAR(200) = 'CREATE LOGIN [' + @LoginName + '] WITH PASSWORD = ''' + @MatKhau + '''';
        EXEC sp_executesql @CreateLogin;

        -- Tạo user cho nhân viên trong database
        DECLARE @CreateUser NVARCHAR(200) = 'CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + ']';
        EXEC sp_executesql @CreateUser;

        -- Lấy tên vai trò từ bảng VaiTro dựa trên @MaVaiTro
        DECLARE @TenVaiTro NVARCHAR(100);
        SELECT @TenVaiTro = TenVaiTro FROM VaiTro WHERE MaVaiTro = @MaVaiTro;
		--SELECT @TenVaiTro;
		--SET @TenVaiTro = N'Quản lý';

        -- Lấy tên phòng ban từ bảng PhongBan dựa trên @MaPB
        DECLARE @TenPhongBan NVARCHAR(100);
        SELECT @TenPhongBan = TenPB FROM PhongBan WHERE MaPB = @MaPB;
		--SET @TenPhongBan = 'Phòng Nhân sự'
        
		-- Gán role cho user dựa vào tên phòng ban và vai trò
		IF @TenPhongBan = N'Phòng Nhân sự' AND @TenVaiTro = N'Trưởng phòng'
            EXEC sp_addrolemember 'TruongPhongHR', @LoginName;
			--Select 'TruongPhongHR';
        ELSE IF @TenPhongBan = N'Phòng Nhân sự' AND @TenVaiTro <> N'Trưởng phòng'
            EXEC sp_addrolemember 'HR', @LoginName;
			--SElect 'HR';
        ELSE IF @TenPhongBan = N'Phòng Kế toán'
            EXEC sp_addrolemember 'KeToan', @LoginName;
			--SELECT 'KeToan';
        ELSE IF @TenVaiTro IN (N'Quản lý', N'Trưởng phòng')
            EXEC sp_addrolemember 'QuanLyPhongBan', @LoginName;
			--select 'QuanLyPhongBan';
        ELSE
            EXEC sp_addrolemember 'NhanVienPhongBan', @LoginName;
			--select 'NhanVienPhongBan';

        -- Commit transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback transaction nếu có lỗi
        ROLLBACK TRANSACTION;
        -- Hiển thị thông báo lỗi
        THROW;
    END CATCH
END;
GO

EXEC ThemNhanVienMoi 'NV002', N'Trần Thị B', '2001-10-14', 'nv_b@example.com', 20000000, '987654321', 1, 'PB001', 'VT002', '123';
EXEC ThemNhanVienMoi 'NV003', N'Lê Văn C', '2003-07-24', 'nv_c@example.com', 10000000, '456789123', 1, 'PB002', 'VT003', '123';
EXEC ThemNhanVienMoi 'NV004', N'Phạm Thị D', '1999-05-12', 'nv_d@example.com', 22000000, '789123456', 1, 'PB002', 'VT002', '123';
EXEC ThemNhanVienMoi 'NV005', N'Hoàng Văn E', '2002-03-10', 'nv_e@example.com', 8000000, '321654987', 1, 'PB003', 'VT001', '123';
GO

EXEC sp_helpuser
GO
select ORIGINAL_LOGIN()
--SELECT
--    s.session_id,
--    c.connect_time,
--    s.login_name,
--    s.host_name,
--    s.program_name
--FROM
--    sys.dm_exec_sessions s
--JOIN
--    sys.dm_exec_connections c ON s.session_id = c.session_id
--WHERE
--    s.is_user_process = 1;

--kill 57

--delete from NhanVien_VaiTro
--delete from NhanVien

--CREATE OR ALTER PROCEDURE CapNhatThongTinNhanVien (
--  @MaNV NVARCHAR(100),
--  @TenNV NVARCHAR(100),
--  @NgaySinh VARBINARY(MAX),
--  @Email NVARCHAR(100),
--  @Luong VARBINARY(MAX),
--  @MST NVARCHAR(100),
--  @HoatDong BIT,
--  @MaPB NVARCHAR(100)
--)
--AS
--BEGIN 
--  UPDATE NhanVien
--  SET TenNV = @TenNV,
--      NgaySinh = @NgaySinh,
--      Email = @Email,
--      Luong = @Luong,
--      MST = @MST,
--      HoatDong = @HoatDong,
--      MaPB = @MaPB
--  WHERE MANV = @MaNV;
--END;
--GO 

--CREATE PROCEDURE sp_Login
--    @userName NVARCHAR(100),
--    @passWord NVARCHAR(100)
--AS
--BEGIN
--    DECLARE @hashedPassword NVARCHAR(100);

--    -- Mã hóa mật khẩu truyền vào
--    SET @hashedPassword = HASHBYTES('SHA2_256', @passWord);

--    IF EXISTS (
--        SELECT 1
--        FROM NhanVien_VaiTro NVVT
--        JOIN NhanVien NV ON NVVT.MANV = NV.MANV
--        WHERE NV.MANV = @userName 
--          AND NVVT.MatKhauHash = @hashedPassword
--          AND NV.HoatDong = 1
--    )
--    BEGIN
--        -- Trả về message nếu tài khoản tồn tại, đúng mật khẩu và hoạt động
--        RETURN 'Tài khoản đã được xác thực thành công.';
--    END
--    ELSE
--    BEGIN
--        -- Trả về message nếu tài khoản không tồn tại, sai mật khẩu hoặc không hoạt động
--        RETURN 'Tên đăng nhập hoặc mật khẩu không đúng hoặc tài khoản đã bị khóa.';
--    END
--END;
--GO

---- Procedure để mã hóa lương
--CREATE PROCEDURE EncryptSalary @Salary DECIMAL(18,2)
--AS
--BEGIN
--  OPEN SYMMETRIC KEY SalaryKey DECRYPTION BY CERTIFICATE SalaryCert;
--  DECLARE @EncryptedSalary VARBINARY(MAX);
--  SET @EncryptedSalary = ENCRYPTBYKEY(KEY_GUID('SalaryKeyOfWindowsDefender'), CONVERT(VARBINARY(MAX), @Salary));
--  CLOSE SYMMETRIC KEY SalaryKey;
--  RETURN @EncryptedSalary;
--END;
--GO 
---- Procedure để giải mã lương
--CREATE PROCEDURE DecryptSalary @EncryptedSalary VARBINARY(MAX)
--AS
--BEGIN
--  OPEN SYMMETRIC KEY SalaryKey DECRYPTION BY CERTIFICATE SalaryCert;
--  DECLARE @DecryptedSalary DECIMAL(18,2);
--  SET @DecryptedSalary = CONVERT(DECIMAL(18,2), DECRYPTBYKEY(@EncryptedSalary));
--  CLOSE SYMMETRIC KEY SalaryKey;
--  RETURN @DecryptedSalary;
--END;

--select * from NhanVien;