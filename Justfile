# user_name        := env_var("USER")
# current_location := justfile()
# current_dir      := justfile_directory()
# module_name      := file_name(current_dir)

# - build tasks

clean:
	rm -rf python/__pycache__

test:
	python3 test/test_buildpaths.py
	python3 test/test_jsonenvironment.py


setup:
    bash setup/setup.sh

