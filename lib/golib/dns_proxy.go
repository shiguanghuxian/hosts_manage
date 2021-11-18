package main

import (
	"fmt"
	"log"
	"net"
	"strings"
	"sync"
	"time"

	"github.com/miekg/dns"
)

type DnsProxy struct {
	addressBook     map[string]string // a记录 域名对应ip
	publicDnsServer []string          // 公网dns，本地不存在时转发到公网
	lockMap         *sync.Mutex       // map修改锁
	udpService      *dns.Server       // dns服务对象
	isStart         bool              // 是否已启动
	err             error             // 是否有错误
}

var (
	DnsProxyHandle = &DnsProxy{
		addressBook:     make(map[string]string),
		publicDnsServer: make([]string, 0),
		lockMap:         new(sync.Mutex),
		isStart:         false,
	}
)

// GetIsStart 获取启动状态
func (dp *DnsProxy) GetIsStart() bool {
	return dp.isStart
}

// GetErr 获取启动或停止错误
func (dp *DnsProxy) GetErr() string {
	if dp.err == nil {
		return ""
	}
	return dp.err.Error()
}

// SetAddressBook 设置ip映射
func (dp *DnsProxy) SetAddressBook(addressBook map[string]string) {
	dp.lockMap.Lock()
	defer dp.lockMap.Unlock()
	dp.addressBook = addressBook
}

// SetPublicDnsServer 设置公网dns服务
func (dp *DnsProxy) SetPublicDnsServer(addrs []string) {
	dp.publicDnsServer = addrs
}

// Start 启动dns代理服务
func (dp *DnsProxy) Start() {
	udpService := &dns.Server{
		Addr:    "0.0.0.0:53",
		Net:     "udp",
		Handler: dp,
	}
	dp.udpService = udpService
	log.Println("启动dns udp监听")
	// 重置错误和启动状态
	dp.isStart = true
	dp.err = nil
	if err := udpService.ListenAndServe(); err != nil {
		log.Println("启动dns udp监听失败", err)
		dp.isStart = false
		dp.err = err
		return
	}
}

// Stop 停止服务
func (dp *DnsProxy) Stop() {
	if dp.udpService == nil {
		return
	}
	log.Println("停止dns udp监听")
	err := dp.udpService.Shutdown()
	if err != nil {
		log.Println("停止dns udp监听失败", err)
		dp.err = err
	}
}

// ServerDNS 处理一个dns请求
func (dp *DnsProxy) ServeDNS(w dns.ResponseWriter, msg *dns.Msg) {
	var (
		err     error
		respMsg = new(dns.Msg)
	)
	respMsg.SetReply(msg)
	defer func() {
		if w != nil {
			if err = w.Close(); err != nil {
				log.Println("关闭dns输出流错误", err)
			}
		}
	}()
	if len(msg.Question) < 1 {
		return
	}
	question := msg.Question[0]

	queryName := strings.TrimRight(question.Name, ".")
	log.Printf("[%d] queryName: [%s -- %s]\n", question.Qtype, question.Name, queryName)

	switch question.Qtype {
	case dns.TypeA:
		if ipStr, ok := dp.addressBook[queryName]; ok {
			respMsg.Answer = append(respMsg.Answer, &dns.A{
				Hdr: dns.RR_Header{
					Name:   question.Name,
					Rrtype: dns.TypeA,
					Class:  dns.ClassINET,
					Ttl:    600,
				},
				A: net.ParseIP(ipStr),
			})
		}
	case dns.TypeAAAA:
		if ipStr, ok := dp.addressBook[queryName]; ok {
			respMsg.Answer = append(respMsg.Answer, &dns.AAAA{
				Hdr: dns.RR_Header{
					Name:   question.Name,
					Rrtype: dns.TypeAAAA,
					Class:  dns.ClassINET,
					Ttl:    600,
				},
				AAAA: net.ParseIP(ipStr),
			})
		}
	}

	if len(respMsg.Answer) == 0 {
		// 默认给失败
		respMsg.Rcode = dns.RcodeServerFailure
		// 未命中本地缓存，向上请求主机ip
		dnsReq := dns.Client{
			Timeout: 9 * time.Second,
			Net:     "udp",
		}
		for _, dnsServerIp := range dp.publicDnsServer {
			newRespMsg, _, err := dnsReq.Exchange(msg, fmt.Sprintf("%s:53", dnsServerIp))
			if err != nil {
				log.Println("请求公网dns服务错误", err)
				continue
			}
			if newRespMsg != nil {
				respMsg = newRespMsg
				break
			}
		}
	} else {
		respMsg.Rcode = dns.RcodeSuccess
	}
	respMsg.Response = true

	// 防止UDP客户端无法接收超过512字节的数据，清空ns(AUTHORITY SECTION)和extra(ADDITIONAL SECTION)节点
	respMsg.Extra = nil
	respMsg.Ns = nil

	// 发送响应消息
	err = w.WriteMsg(respMsg)
	if err != nil {
		log.Println("响应dns消息失败", err)
	}
}
