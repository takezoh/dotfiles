@echo off↲
if "%1" == "-u" (
	cd {project_root}
	call global {gtagsdb_root}\\gtags.game %*
) else (
	set GTAGSROOT={project_root}
	set GTAGSDBPATH={gtagsdb_root}\\gtags.game
	call global %* 2> nul
	set GTAGSROOT={engine_root}
	set GTAGSDBPATH={gtagsdb_root}\\gtags.engine
	call global %* 2> nul
)
exit /b 0
