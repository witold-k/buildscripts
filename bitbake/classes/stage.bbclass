do_install() {
    mkdir -p ${B}
    date > ${B}/last_build.txt
}
