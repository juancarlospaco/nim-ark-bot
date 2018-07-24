#!/usr/bin/env nim
#
# nim e build.nims


echo "Building for Linux"
exec "nim c -d:release -d:ssl --app:console --opt:size --out:downloads/nim_ark_bot nim_ark_bot.nim"
exec "strip --verbose -ss downloads/nim_ark_bot"
exec "upx --best --ultra-brute downloads/nim_ark_bot"
exec "sha1sum --tag downloads/nim_ark_bot > downloads/nim_ark_bot.sha1"
exec "sha512sum --tag downloads/nim_ark_bot > downloads/nim_ark_bot.sha512"
# exec "keybase sign --infile downloads/nim_ark_bot --outfile downloads/nim_ark_bot.asc"

echo "Building for Windows"
exec "nim c --cpu:amd64 --os:windows --gcc.exe:/usr/bin/x86_64-w64-mingw32-gcc --gcc.linkerexe:/usr/bin/x86_64-w64-mingw32-gcc -d:release --opt:size --out:downloads/nim_ark_bot.exe nim_ark_bot.nim"
exec "sha1sum --tag downloads/nim_ark_bot.exe > downloads/nim_ark_bot.exe.sha1"
exec "sha512sum --tag downloads/nim_ark_bot.exe > downloads/nim_ark_bot.exe.sha512"
# exec "keybase sign --infile downloads/nim_ark_bot.exe --outfile downloads/nim_ark_bot.exe.asc"

exec "chmod --verbose -w downloads/*"
