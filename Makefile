default: build_and_run

build_mkdir:
	if [ ! -d "./build" ]; then mkdir "build"; fi

build_exec: build_mkdir
	env LIBRARY_PATH="$(PWD)/lib_ext" crystal build src/geo_wars.cr -o build/geo_wars

build_exec_release: build_mkdir
	env LIBRARY_PATH="$(PWD)/lib_ext" crystal build --release src/geo_wars.cr -o build/geo_wars_release

build_and_run: build_exec run

build_release_and_run: build_exec_release run_release

run:
	env LD_LIBRARY_PATH="$(PWD)/lib_ext" ./build/geo_wars

run_release:
	env LD_LIBRARY_PATH="$(PWD)/lib_ext" ./build/geo_wars_release
