# just for testing kernel builds
# and remove the bc command

MODULES := $(wildcard *.modules)
BC_FILES := $(MODULES:.modules=.modules.bc)
LUA_FILES := $(MODULES:.modules=.modules.lua)

all: $(BC_FILES) $(LUA_FILES)

%.modules.bc:	%.modules
	@list=$$(for i in `seq 1 127`; do head -c$$i $^ | tail -c1 \
		| hexdump -v -e '/1 "%02X+"'; done); \
		echo "ibase=16;100-($${list%?})%100" | bc >$@

%.modules.lua:	%.modules
	@list=$$(for i in `seq 1 127`; do head -c$$i $^ | tail -c1 \
		| hexdump -v -e '/1 "%u+"'; done); \
		echo "256-($${list%?})%256" | lua | awk 'NR==2 {print $$2}' >$@


