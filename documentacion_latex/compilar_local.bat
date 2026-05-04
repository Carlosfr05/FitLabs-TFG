@echo off
setlocal

REM Compila la memoria LaTeX con biblatex+biber en Windows.
REM Requiere tener en PATH: pdflatex y biber (MiKTeX o TeX Live).

cd /d "%~dp0"

echo [1/5] pdflatex main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
if errorlevel 1 goto :error

echo [2/5] biber main
biber main
if errorlevel 1 goto :error

echo [3/5] pdflatex main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
if errorlevel 1 goto :error

echo [4/5] pdflatex main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
if errorlevel 1 goto :error

echo [5/5] Compilacion completada: main.pdf
goto :end

:error
echo.
echo ERROR: Fallo la compilacion. Revisa el log mostrado arriba.
exit /b 1

:end
endlocal
