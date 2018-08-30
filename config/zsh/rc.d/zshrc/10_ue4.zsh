_UNREAL_VERSION_SELECTOR="/mnt/c/Program Files (x86)/Epic Games/Launcher/Engine/Binaries/Win64/UnrealVersionSelector.exe"

___ue_find_uproject() {
	local current_dir=`pwd -P`
	while [ ! "$current_dir" = "/" ]; do
		local uproj=`find $current_dir -maxdepth 2 -name "*.uproject" -not -path "Engine/*" -not -path "Templates/*" | head`
		if [ -n "$uproj" ]; then
			echo "Found: $uproj" >&2
			echo $uproj
			return 0
		fi
		current_dir=`dirname $current_dir`
	done
	echo "Not found *.uproject files." >&2
	return 0
}

___ue_find_script() {
	local target_script=$1
	local current_dir=`pwd -P`
	while [ ! "$current_dir" = "/" ]; do
		local script="$current_dir/$target_script"
		if [ -f "$script" ]; then
			# echo "Found: $script" >&2
			echo $script
			return 0
		fi
		current_dir=`dirname $current_dir`
	done
	echo "Not found **/$target_script" >&2
	return 1
}

___ue_build_root() {
	local uproj=$1
	local target=$2
	local configuration=$3
	local platform=Win64
	if [ -z "$target" ]; then
		target="`basename ${uproj%.*}`Editor"
	fi
	if [ -z "$configuration" ]; then
		configuration="Development"
	fi
	cat <<EOF | python
import json
context = json.load(open("""`dirname ${uproj}`/Intermediate/Build/${platform}/${target}/${configuration}/${target}.uhtmanifest""", 'r'))
# print(context["RootLocalPath"])
print(context["RootBuildPath"])
EOF
}

___ue_clean_project_files() {
	for p in $*; do
		if [ -d $p ]; then
			rm -r $p
		fi
	done
}

___ue_generate_project_files() {
	local uproj=$1
	if [ -n "$uproj" ]; then
		local bat="`dirname $uproj`/../Engine/Build/BatchFiles/GenerateProjectFiles.bat"
	else
		local bat=`___ue_find_script "Engine/Build/BatchFiles/GenerateProjectFiles.bat"`
	fi
	if [ -n "$uproj" -a -f "$bat" ]; then
		wcmd `wslpath -am $bat ` "-VSCode" "-2017" `wslpath -am $uproj` "-Game" "-Engine"
	# elif [ -f "$bat" ]; then
		# wcmd `wslpath -am $bat ` "-VSCode" "-2017"
	elif [ -n "$uproj" ]; then
		$_UNREAL_VERSION_SELECTOR /projectfiles "`wslpath -am $uproj`"
	fi
	if [ -n "$uproj" ]; then
		___ue_generate_global_proxy $uproj
	fi
}

___ue_generate_global_proxy() {
	local uproj=$1
	local proj_root=$(dirname "`dirname $uproj`")
	local proj_dirname=$(basename "`dirname $uproj`")
	local proj_name="`basename ${uproj%.*}`"
	cp ~/.dotfiles/misc/etc/ue-project/ignore "`dirname $uproj`/../.ignore"
	# cp ~/.dotfiles/misc/etc/ue-project/ycm_extra_conf.py "`dirname $uproj`/../.ycm_extra_conf.py"
	cp ~/.dotfiles/misc/etc/ue-project/project.gtags.conf "`dirname $uproj`/gtags.conf"
	cp ~/.dotfiles/misc/etc/ue-project/engine.gtags.conf "`dirname $uproj`/../Engine/gtags.conf"
	python3 ~/.dotfiles/misc/etc/ue-project/make_include_path.py "$(cd `dirname $uproj`/.. && pwd -P)" &

	cat <<EOF > "`dirname $uproj`/../.global"
current_dir=\$(cd \`dirname \$0\` && pwd -P)
if [ "\$1" = "-u" ]; then
	(cd "\$current_dir/${proj_dirname}" && \$GLOBALBIN "\$@")
else
	GTAGSROOT="\$current_dir/${proj_dirname}" GTAGSDBPATH="\$current_dir/${proj_dirname}" \$GLOBALBIN "\$@" 2>/dev/null
	GTAGSROOT="\$current_dir/Engine" GTAGSDBPATH="\$current_dir/Engine" \$GLOBALBIN "\$@" 2>/dev/null
fi
EOF

	cat <<EOF > "`dirname $uproj`/../global_proxy.bat"
@echo off
if "%1" == "-u" (
	cd %~dp${proj_dirname}
	call global %*
) else (
	set GTAGSROOT=%~dp0${proj_dirname}
	set GTAGSDBPATH=%~dp0${proj_dirname}
	call global %* 2> nul
	set GTAGSROOT=%~dp0Engine
	set GTAGSDBPATH=%~dp0Engine
	call global %* 2> nul
)
exit /b 0
EOF

	local workspace="`dirname $uproj`/UE4.code-workspace"
	cat <<EOF | python
import json

context = json.load(open("""${workspace}""", 'r'))
context["settings"]["codegnuglobal.executable"] = "global_proxy.bat"
context["settings"]["codegnuglobal.autoupdate"] = True
json.dump(context, open("""${workspace}""", 'w'), indent=4)
EOF

# "${workspaceFolder}/${projectname}/Plugins/**/Public"

	local c_cpp_properties="`dirname $uproj`/.vscode/c_cpp_properties.json"
	local source_dir="$proj_dirname/Source"
	local intermediate_ue4editor_inc_dir="$proj_dirname/Intermediate/Build/Win64/UE4Editor/Inc"

# 	(
# 		rm -f "$proj_root/.include_path"
# 		cat <<EOF | python3 > "$proj_root/.include_path.win"
# import json
# context = json.load(open("""${c_cpp_properties}""", 'r'))
# include_path = context["configurations"][0]["includePath"]
# print ("\n".join(include_path))
# EOF
# 		for f in `cat "$proj_root/.include_path.win"`; do
# 			wslpath -au "$f" >> "$proj_root/.include_path"
# 		done
# 		for f in `cd "$proj_root/$source_dir" && command ls`; do
# 			echo "$proj_root/$source_dir/$f" >> "$proj_root/.include_path"
# 		done
# 		for f in `cd "$proj_root/$intermediate_ue4editor_inc_dir" && command ls`; do
# 			echo "$proj_root/$intermediate_ue4editor_inc_dir/$f" >> "$proj_root/.include_path"
# 		done
# 	) &

	cat <<EOF | python
import os
import json

context = json.load(open("""${c_cpp_properties}""", 'r'))
include_path = context["configurations"][0]["includePath"]

for f in os.listdir("""${proj_root}/${source_dir}"""):
	f = os.path.join("""${source_dir}""", f)
	if os.path.isdir(f):
		include_path.append('\${workspaceFolder}/' + f)

for f in os.listdir("""${proj_root}/${intermediate_ue4editor_inc_dir}"""):
	f = os.path.join("""${intermediate_ue4editor_inc_dir}""", f)
	if os.path.isdir(f):
		include_path.append('\${workspaceFolder}/' + f)

json.dump(context, open("""${c_cpp_properties}""", 'w'), indent=4)
EOF

	local tasks_json="`dirname $uproj`/.vscode/tasks.json"
	cat <<EOF | python
import os
import json

context = json.load(open("""${tasks_json}""", 'r'))
context["tasks"] = []

for configure in ("Debug", "Development"):
	context["tasks"].append({
		"label": """${proj_name} """ + configure + "Editor Build",
		"group": "build",
		"command": "cmd",
		"args": [
			"/d",
			"/c",
			"`wslpath -w Engine/Build/BatchFiles/Build.bat`",
			"""${proj_name}Editor""",
			"Win64",
			configure,
			"""`wslpath -am ${uproj}`""",
			"-waitmutex"
		],
		"problemMatcher": "$msCompile",
		"-- dependsOn": [
			"UnrealBuildTool Win64 Development Build"
		],
		"-- type": "shell",
		"options": {
			"cwd": "\${workspaceRoot}"
		}
	})

json.dump(context, open("""${tasks_json}""", 'w'), indent=4)
EOF

	local launch_json="`dirname $uproj`/.vscode/launch.json"
	cat <<EOF | python
import os
import json

context = json.load(open("""${launch_json}""", 'r'))
context["configurations"] = [
	{
		"name": "Attach",
		"type": "cppvsdbg",
		"request": "attach",
		"processId": "\${command:pickProcess}"
	},
	{
		"name": "Debug",
		"type": "cppvsdbg",
		"request": "launch",
		"program": """`wslpath -am Engine/Binaries/Win64/UE4Editor.exe`""",
		"args": [
			"""`wslpath -am ${uproj}`""",
			"-debug"
		],
		"cwd": "\${workspaceRoot}"
	},
	{
		"name": "Development",
		"type": "cppvsdbg",
		"request": "launch",
		"program": """`wslpath -am Engine/Binaries/Win64/UE4Editor.exe`""",
		"args": [
			"""`wslpath -am ${uproj}`""",
		],
		"cwd": "\${workspaceRoot}"
	}
]

json.dump(context, open("""${launch_json}""", 'w'), indent=4)
EOF
}

___ue_gtags() {
	local uproj=$1
	if [ -n "$uproj" ]; then
		(cd "`dirname $uproj`" && gtags >/dev/null 2>&1) &
		(cd "`dirname $uproj`"/../Engine && gtags >/dev/null 2>&1) &
	fi
}

ue.generate-project-files() {
	local uproj=`___ue_find_uproject`
	# ___ue_clean_project_files `dirname $uproj`/Intermediate
	___ue_generate_project_files $uproj
	___ue_gtags $uproj
}

ue.generate-project-files-full() {
	local uproj=`___ue_find_uproject`
	if [ -z "$uproj" ]; then
		return 1
	fi
	___ue_clean_project_files $(find `dirname $uproj` -type d -name "Intermediate")
	___ue_generate_project_files $uproj
	___ue_gtags $uproj
}

ue.generate-project-files-full-with-engine() {
	local uproj=`___ue_find_uproject`
	if [ -z "$uproj" ]; then
		return 1
	fi
	___ue_clean_project_files $(find `dirname $uproj`/.. -type d -name "Intermediate")
	___ue_generate_project_files $uproj
	___ue_gtags $uproj
}


___ue_build_unrealbuildtool() {
	local cmd=`echo $1 | tr '[:upper:]' '[:lower:]'`
	local configuration=$2
	local platform=$3

	local bat="`___ue_find_script Engine/Build/BatchFiles/MSBuild.bat`"
	if [ -f $bat ]; then
		wcmd `wslpath -am $bat`
			\ "/t:${cmd##re}"
			\ "Engine/Source/Programs/UnrealBuildTool/UnrealBuildTool.csproj"
			\ "/p:GenerateFullPaths=true"
			\ "/p:DebugType=portable"
			\ "/p:Configuration=$configuration"
			\ "/verbosity:minimal"
	fi
}

___ue_build_internal() {
	local cmd=$1
	local target=$2
	local configuration=$3
	local params=(${@:4:($#-3)})
	local platform=Win64

	for suffix in Editor Client Server; do
		if [ ! "$configuration" = "${configuration%$suffix}" ]; then
			target="${target}${suffix}"
			configuration="${configuration%$suffix}"
		fi
	done

	# ___ue_build_unrealbuildtool $cmd $configuration $platform

	local bat="`___ue_find_script Engine/Build/BatchFiles/${cmd}.bat`"
	if [ -f "$bat" ]; then
		echo $bat $target $platform $configuration $params -WaitMutex -FromMsBuild -2017
		wcmd `wslpath -am $bat` $target $platform $configuration $params -WaitMutex -FromMsBuild -2017
	fi
}

___ue_build() {
	local cmd=$1
	local configuration=$2
	local params=(${@:3:($#-2)})
	local uproj=`___ue_find_uproject`
	local target="`basename ${uproj%.*}`"
	___ue_build_internal $cmd $target $configuration `wslpath -am $uproj` $params
}

ue.build() { ___ue_build Build "$@" }
ue.rebuild() { ___ue_build Rebuild "$@" }
ue.clean() { ___ue_build Clean "$@" }
ue.engine.build() { ___ue_build_internal Build "UE4" "$@" }
ue.engine.rebuild() { ___ue_build_internal Rebuild "UE4" "$@" }
ue.engine.clean() { ___ue_build_internal Clean "UE4" "$@" }

alias ue="ue.editor"

ue.editor() {
	local exe=$1
	local uproj=`___ue_find_uproject`
	local cwd="`dirname $uproj`/.."
	local proj_name="`basename ${uproj%.*}`"

#	if [ "${exe##*.}" = "exe" ]; then
#		shift
#		local platform=Win64
#		local engine="$cwd/Engine/Binaries/$platform/UE4Game-${platform}-${exe##*-}"
#		if [ -f $engine ]; then
#			(cd $cwd && open `wslpath -aw $engine` `wslpath -aw $exe` "$@")
#		fi
#		return 0
#	fi
	local editor="$cwd/Engine/Binaries/Win64/UE4Editor.exe"
	if [ -f $editor ]; then
		for arg in $@; do
			if [ "${arg#-*}" = "$arg" ]; then
				break
			fi
			if [ $arg = "-game" ] || [ $arg = "-m" ]; then
				local choose_map=yes
			fi
		done
		if [ "$choose_map" = "yes" ]; then
			local map=$(cd "`dirname $uproj`/Content" && rg -g '*.umap' --files . 2>/dev/null | peco --prompt="$proj_name: Choose map>")
			if [ -z "$map" ]; then
				exit 1
			fi
			map="/Game/`echo $map | sed -e 's/\..*$//'`"
		fi

		echo $editor $uproj $map "$@" "-skipcompile" "-fullcrashdump"
		(cd $cwd && open `wslpath -aw $editor` `wslpath -aw $uproj` $map "$@" "-skipcompile" "-fullcrashdump")
		return 0
	fi

	$_UNREAL_VERSION_SELECTOR /editor "`wslpath -am $uproj`"
}

ue.game() {
	local uproj=`___ue_find_uproject`

	[ -z "$uproj" ] && return 1

	local proj_name="`basename ${uproj%.*}`"
	local target_dir="`dirname $uproj`"

	for _ in `seq 2`; do
		[ $target_dir = "/" ] && return 1
		if [ -d "$target_dir/packages" ]; then
			break
		fi
		target_dir="`dirname $target_dir`"
	done

	if [ -d "$target_dir/packages" ]; then
		target_dir="$target_dir/packages"
	fi

	local name="${proj_name}.exe"
	local path=`rg -g $name --files $target_dir 2>/dev/null | rg '/WindowsNoEditor/' | peco --prompt="Search '$name' from $target_dir>"`
	echo $path "$@" -fullcrashdump
	($path "$@" -fullcrashdump >/dev/null 2>&1) &
}
