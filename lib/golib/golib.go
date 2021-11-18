package main

import "C"
import (
	"encoding/json"
	"log"
	"strings"
)

//export Start
func Start() {
	go DnsProxyHandle.Start()
}

//export Stop
func Stop() {
	DnsProxyHandle.Stop()
}

//export GetIsStart
func GetIsStart() int32 {
	if DnsProxyHandle.GetIsStart() {
		return 1
	}
	return 0
}

//export GetErr
func GetErr() *C.char {
	errStr := DnsProxyHandle.GetErr()
	return C.CString(errStr)
}

//export SetAddressBook
func SetAddressBook(str *string) {
	log.Println("设置ip映射错误", *str)
	strList := strings.Split(*str, "\n")
	hostsMap := make(map[string]string)
	for _, v := range strList {
		v = strings.TrimSpace(v)
		if strings.HasPrefix(v, "#") {
			continue
		}
		arr := strings.Fields(v)
		if len(arr) != 2 {
			continue
		}
		hostsMap[arr[1]] = arr[0]
	}
	js, _ := json.Marshal(hostsMap)
	log.Println("映射map", string(js))
	DnsProxyHandle.SetAddressBook(hostsMap)
}

//export SetPublicDnsServer
func SetPublicDnsServer(str *string) {
	log.Println("设置公网dns服务列表", *str)
	strList := strings.Split(*str, "\n")
	addrs := make([]string, 0)
	for _, v := range strList {
		v = strings.TrimSpace(v)
		if v != "" {
			addrs = append(addrs, v)
		}
	}
	DnsProxyHandle.SetPublicDnsServer(addrs)
}

func main() {
	DnsProxyHandle.publicDnsServer = []string{"8.8.8.8"}
	DnsProxyHandle.Start()
}
