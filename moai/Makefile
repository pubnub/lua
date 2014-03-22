include ../Makefile.inc

OUTPUT_FILES=$(PUBNUB_LUA)
PLATFORM=Moai

.PHONY: all
all: build

.PHONY: build
build: $(PUBNUB_LUA)

$(PUBNUB_LUA): $(PUBNUB_COMMON_LUA) $(PUBNUB_NODE_LUA)
	$(ECHO) "-- Version: $(VERSION)" > $(PUBNUB_LUA)
	cat $(PUBNUB_COMMON_LUA) $(PUBNUB_PLATFORM_LUA) >> $(PUBNUB_LUA)
	sed -i -e "s/VERSION/$(VERSION)/g" $(PUBNUB_LUA)
	sed -i -e "s/PLATFORM/$(PLATFORM)/g" $(PUBNUB_LUA)
	find examples -d -name "example-*" -exec cp pubnub.lua {} \;
	find examples -d -name "example-*" -exec cp ../common/BinDecHex.lua {} \;
	find examples -d -name "example-*" -exec cp ../common/PubnubUtil.lua {} \;
	find . -name '*.lua-e' | xargs rm 

.PHONY: clean
clean:
	rm -f $(OUTPUT_FILES) 
	find examples -name "pubnub.lua" -exec rm {} \; 
	find examples -name "BinDecHex.lua" -exec rm {} \; 
	find examples -name "PubnubUtil.lua" -exec rm {} \; 

.PHONY: test
test:
	pass

include ../Makefile.post
