@echo off
@rem
@rem Copyright 2019-2020 NXP
@rem Author: Libor Ukropec
@rem
@rem executes the Code Checks / analysis. You might need to install the dependencies
@rem   pip install -r requirements.txt -r requirements-develop.txt
@rem
@echo on
IF DEFINED VIRTUAL_ENV GOTO TEST
IF EXIST venv\Scripts\activate.bat call venv\Scripts\activate.bat
@echo on
:TEST
@rem execute this batch in your virtual env
@rem -------------------------------------------------------
@rem python tests including the code coverage
IF EXIST %CD%\reports\htmlcov DEL %CD%\reports\htmlcov /Q
pytest --cov=spsdk --cov-report=term --cov-report=html:reports/htmlcov/ --cov-branch --cov-report=xml:reports/coverage.xml --log-cli-level=WARN .
@rem WITH DURATIONS pytest --durations=0 --cov=spsdk --cov-report=term --cov-report=html:reports/htmlcov/ --cov-branch --cov-report=xml:reports/coverage.xml --log-cli-level=WARN .
@if errorlevel 1 goto END
@rem -------------------------------------------------------
@rem mypy: python typing tests (modules tested: spsdk + examples)
mypy spsdk > %CD%\reports\mypy.txt
@rem mypy spsdk examples >%CD%\reports\mypy.txt
@if errorlevel 1 echo "<<<### MYPY PROBLEM DETECTED ########################################################>>>"
@rem -------------------------------------------------------
@rem pylint (spsdk module only, errors only)
pylint spsdk -E > %CD%\reports\pylint.txt
@if errorlevel 1 echo "<<<### PYLINT ERROR DETECTED ########################################################>>>"
@rem: pylint spsdk examples > %CD%\reports\pylint_all.txt
@rem -------------------------------------------------------
@rem pylint documentation-related checkers (spsdk module only)
pylint spsdk --rcfile=pylint-doc-rules.ini > %CD%\reports\pylint-docs.txt
@if errorlevel 1 echo "<<<### PYLINT DOCSTRING ERROR DETECTED ##############################################>>>"
@rem -------------------------------------------------------
pydocstyle spsdk > %CD%\reports\pydocstyle.txt
@if errorlevel 1 echo "<<<### PYDOCSTYLE ERROR DETECTED ####################################################>>>"
@rem -------------------------------------------------------
@rem radon (spsdk module only)
radon cc --min D spsdk > %CD%\reports\radonD.txt
@rem print warning if output file not empty
@for /f %%i in ("%CD%\reports\radonD.txt") do set radonDsize=%%~zi
@if %radonDsize% gtr 0 echo "<<<### RADON DETECTED COMPLEXITY >= D #########################################>>>"
radon cc --min C spsdk > %CD%\reports\radonC.txt
@rem -------------------------------------------------------
@rem gitcov (coverage of changed files)
python tools\gitcov.py --verbose --coverage-report reports\coverage.xml
@if %errorlevel% gtr 0 echo "<<<### GIT-COV ERROR DETECTED #################################################>>>"
:END