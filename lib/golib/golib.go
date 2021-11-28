package main

import "C"
import (
	"encoding/json"
	"log"
	"strings"
)

/* DNS服务相关，暂不改名，socks5服务增加前缀 */

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
		vArr := strings.Split(v, "#")
		if len(vArr) > 1 {
			v = strings.TrimSpace(vArr[0])
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
		if strings.HasPrefix(v, "#") {
			continue
		}
		vArr := strings.Split(v, "#")
		if len(vArr) > 1 {
			v = strings.TrimSpace(vArr[0])
		}
		if v != "" {
			addrs = append(addrs, v)
		}
	}
	DnsProxyHandle.SetPublicDnsServer(addrs)
}

/* socks5代理 */

//export Socks5Start
func Socks5Start() {
	go Socks5ProxyHandle.Start()
}

//export Socks5Stop
func Socks5Stop() {
	Socks5ProxyHandle.Stop()
}

//export Socks5GetIsStart
func Socks5GetIsStart() int32 {
	if Socks5ProxyHandle.GetIsStart() {
		return 1
	}
	return 0
}

//export Socks5GetErr
func Socks5GetErr() *C.char {
	errStr := Socks5ProxyHandle.GetErr()
	return C.CString(errStr)
}

//export Socks5GenCaCert
func Socks5GenCaCert() *C.char {
	err := Socks5ProxyHandle.GenCaCert()
	outStr := ""
	if err != nil {
		outStr = err.Error()
	}
	return C.CString(outStr)
}

//export Socks5SetCertPath
func Socks5SetCertPath(str *string) {
	log.Println("证书根路径", *str)
	Socks5ProxyHandle.SetCertPath(*str)
}

func main() {
	// DnsProxyHandle.publicDnsServer = []string{"8.8.8.8"}
	// DnsProxyHandle.Start()

	Socks5ProxyHandle.Start()
}
