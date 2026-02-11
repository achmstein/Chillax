$sha1 = "B0:B2:38:1D:14:BB:3A:6F:5A:52:3B:34:EC:B4:DD:8C:B0:1E:83:B4"
$bytes = $sha1.Split(':') | ForEach-Object { [byte]([Convert]::ToInt32($_, 16)) }
[Convert]::ToBase64String($bytes)
