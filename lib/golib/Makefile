LIB_NAME=libdns

default:
	@echo 'Usage of make: [ macos | windows | linux | run | clean ]'

run:
	go run *.go

macos: 
	go build -o ${LIB_NAME}.dylib -buildmode=c-shared *.go
	mv ./${LIB_NAME}* ../../macos/dylib

linux: 
	go build -o ${LIB_NAME}.so -buildmode=c-shared *.go

windows: 
	go build -o ${LIB_NAME}.dll -buildmode=c-shared *.go

clean: 
	@rm -f ./${LIB_NAME}*

.PHONY: default macos windows linux run clean