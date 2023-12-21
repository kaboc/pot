@echo off

cd %~dp0

flutter pub get
dart run devtools_extensions build_and_copy --source=. --dest=../pottery/extension/devtools
