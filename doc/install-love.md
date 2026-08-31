# Cài LÖVE2D (Windows)

Project cần **LÖVE 11.x** để chạy `love .`

## Đã cài trên máy dev (một lần)

Vị trí mặc định:

```text
%LOCALAPPDATA%\Programs\LOVE\love-11.5-win64\love.exe
```

Đã thêm thư mục trên vào **User PATH**. Mở terminal **mới** rồi thử:

```bash
love .
```

## Cách nhanh — không cần PATH

Double-click **`run.bat`** ở root repo.

## Cài tay (máy khác / freebuff)

1. Tải **64-bit zip**: https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip
2. Giải nén vào `%LOCALAPPDATA%\Programs\LOVE\love-11.5-win64`
3. Thêm folder đó vào PATH, hoặc dùng `run.bat`

Hoặc dùng **installer**: https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.exe

## Verify

```bash
love .
```

Cửa sổ **CODE SWARM** mở, không crash.

## macOS / Linux

- macOS: https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip
- Linux: AppImage hoặc PPA — xem https://love2d.org/
