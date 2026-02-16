@echo off
echo Deleting local database to force schema recreation...
if exist "C:\Users\franc\Documents\pos_system.sqlite" (
    del "C:\Users\franc\Documents\pos_system.sqlite"
    echo Database deleted.
) else (
    echo Database not found.
)
echo Done. Please restart the Flutter app.
pause
