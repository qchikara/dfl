call makelib
@rem   This errorlevel check fails on Win9x because of the previous delete.
@rem   @if errorlevel 1 goto fail
@if not "%dfl_failed%" == "" goto fail


@if "%dmd_path%" == "" goto no_dmd


@echo.

@if not "%dfl_go_move%" == "" goto do_move

@echo About to move DFL lib files to %dmd_path%\lib (Close window or Ctrl+C to stop)
@pause

:do_move

@move /Y dfl_debug.lib %dmd_path%\lib
@if errorlevel 1 goto fail
@move /Y dfl.lib %dmd_path%\lib
@if errorlevel 1 goto fail
@move /Y dfl_build.lib %dmd_path%\lib
@if errorlevel 1 goto fail


@goto done

:no_dmd
@echo dmd_path environment variable not set; cannot copy lib files.
@goto done

:fail
@echo Failed.
@pause

:done
@echo Done.
