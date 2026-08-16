current_location := justfile()
current_dir      := justfile_directory()

buildscripts_dir := current_dir + "/buildscripts"
python_exe       := buildscripts_dir + "/python/bin"

scripts_dir      := current_dir + "/scripts"
build_dir        := current_dir + "/meta-layer/build"

# -----------------------------------------------------------------------------

default: build

# -----------------------------------------------------------------------------

info:
	@echo {{current_dir}}
	@echo {{buildscripts_dir}}
	@echo {{python_exe}}

target target:
	@python3 {{python_exe}}/build.py build meta-layer {{current_dir}} {{target}}

build:
	@python3 {{python_exe}}/build.py build meta-layer {{current_dir}}

test: build
	@python3 {{python_exe}}/build.py test meta-layer {{current_dir}}

clean:
	@python3 {{python_exe}}/build.py clean meta-layer {{current_dir}}

env:
    @python3 {{python_exe}}/build.py create_env meta-layer {{current_dir}}

# -----------------------------------------------------------------------------

localsetup:
    RUST_BACKTRACE=1 aifix -l cpp -t setup_build -f {{current_dir}}

localbuild:
    RUST_BACKTRACE=1 aifix -l cpp -t build -f {{current_dir}}

fix:
    @RUST_BACKTRACE=1 aifix -l cpp -t fix_code -f {{current_dir}} -f {{current_dir}}/..

fixd:
    @RUST_BACKTRACE=1 aifix -d -l cpp -t fix_code -f {{current_dir}} -f {{current_dir}}/..

fixws:
    @RUST_BACKTRACE=1 aifix -l cpp -t fix_code -w ~/svn/_workspace -f {{current_dir}} -f {{current_dir}}/.. -f ~/svn/_workspace

fixwsd:
    @RUST_BACKTRACE=1 aifix -d -l cpp -t fix_code -w ~/svn/_workspace -f {{current_dir}} -f {{current_dir}}/.. -f ~/svn/_workspace

doc_item:
    RUST_BACKTRACE=1 aifix -l cpp -t write_item_doc -f {{current_dir}} -f {{current_dir}}/..

docws_item:
    RUST_BACKTRACE=1 aifix -l cpp -t write_item_doc -w ~/svn/_workspace -f {{current_dir}} -f {{current_dir}}/..

doc_block:
    RUST_BACKTRACE=1 aifix -l cpp -t write_block_doc -f {{current_dir}} -f {{current_dir}}/..

doc_module:
    RUST_BACKTRACE=1 aifix -l cpp -t write_module_doc -f {{current_dir}} -f {{current_dir}}/..

