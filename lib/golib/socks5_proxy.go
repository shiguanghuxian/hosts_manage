package main

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/big"
	"net"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/armon/go-socks5"
	"github.com/miekg/dns"
	"github.com/reiver/go-telnet"
	"golang.org/x/net/publicsuffix"
)

/* socks5代理 */

const (
	// ip测速检测次数
	TestIpConnTimeCount = 3
	// 默认代理地址
	DefaultProxyAddr = "0.0.0.0:10109"
	// 代理连接超时
	ProxyDialTimeout = 5 * time.Second
	// 证书有效期
	certExpire = time.Hour * 24 * 30
)

var (
	Socks5ProxyHandle = &Socks5Proxy{
		speedUpHosts:    DefaultSpeedUpHosts,
		publicDnsServer: make([]string, 0),
		hostIpAddrsLock: new(sync.Mutex),
		proxyAddr:       DefaultProxyAddr,
		hostIpAddrs:     make(map[string][]*HostTime),
		dnsCli: &sync.Pool{New: func() interface{} {
			return &dns.Client{Net: "udp"}
		}},
		cacheCert: new(sync.Map),
	}

	// 默认需代理一级域名
	DefaultSpeedUpHosts = []string{"github.com", "githubusercontent.com", "githubassets.com", "github.global.ssl.fastly.net", "stackoverflow.com", "stackexchange.com"}
	// 默认dns服务列表
	DefaultPublicDnsServer = []string{"8.8.8.8", "114.114.114.114", "1.1.1.1", "9.9.9.9", "223.5.5.5"}
	// 连接tls证书配置
	tlsSerConf = &tls.Config{GetCertificate: Socks5ProxyHandle.getCertificate}
	// 连接证书父级
	caParent *x509.Certificate
	caPriKey *rsa.PrivateKey
)

type Socks5Proxy struct {
	speedUpHosts    []string // 需要加速的域名列表，一级域名
	publicDnsServer []string // 公网dns 默认给一批
	certPath        string   // 证书路径
	proxyAddr       string   // 代理地址 ip:端口

	isStart   bool         // 是否已启动
	err       error        // 是否有错误
	listener  net.Listener // 服务监听对象
	cacheCert *sync.Map    // 证书缓存

	hostIpAddrsLock *sync.Mutex            // 主机对于ip更新锁
	hostIpAddrs     map[string][]*HostTime // 测速排序,下标主机名值保护测速和ip
	dnsCli          *sync.Pool             // dns查询客户端
}

type HostTime struct {
	DnsServer string        `json:"dns_server"` // 从那个dns获取的ip
	DnsQtype  uint16        `json:"dns_qtype"`  // dns查询类型
	IpAddr    string        `json:"ip_addr"`    // 获取到的ip地址
	ConnTime  time.Duration `json:"conn_time"`  // 连接时间
	Expire    time.Time     `json:"expire"`     // 失效时间
	IsConn    bool          `json:"is_conn"`    // 是否可连接，排序默认给true
}

const (
	caCert = "cert.pem"
	caKey  = "key.pem"
)

func (sp *Socks5Proxy) initCa() {
	// read ca cert
	certPEMBlock, err := ioutil.ReadFile(strings.Join([]string{sp.certPath, caCert}, string(os.PathSeparator)))
	if err != nil {
		log.Println("证书错误1", err)
		return
	}
	certDERBlock, _ := pem.Decode(certPEMBlock)
	caParent, err = x509.ParseCertificate(certDERBlock.Bytes)
	if err != nil {
		log.Println("证书错误2", err)
		return
	}

	keyPEMBlock, err := ioutil.ReadFile(strings.Join([]string{sp.certPath, caKey}, string(os.PathSeparator)))
	if err != nil {
		log.Println("证书错误3", err)
		return
	}
	keyDERBlock, _ := pem.Decode(keyPEMBlock)
	caPriKey, err = x509.ParsePKCS1PrivateKey(keyDERBlock.Bytes)
	if err != nil {
		log.Println("证书错误5", err)
		return
	}
}

func init() {
	// 初始化定时更新ip
	go func() {
		t := time.NewTicker(10 * 60 * time.Second)
		for {
			<-t.C
			Socks5ProxyHandle.cronIpConnTime()
		}
	}()

}

// GetIsStart 获取启动状态
func (sp *Socks5Proxy) GetIsStart() bool {
	return sp.isStart
}

// GetErr 获取启动或停止错误
func (sp *Socks5Proxy) GetErr() string {
	if sp.err == nil {
		return ""
	}
	return sp.err.Error()
}

// SetPublicDnsServer 设置公网dns服务
func (sp *Socks5Proxy) SetPublicDnsServer(addrs []string) {
	sp.publicDnsServer = addrs
}

// 获取公网dns服务列表
func (sp *Socks5Proxy) GetPublicDnsServer() (addrs []string) {
	if len(sp.publicDnsServer) == 0 {
		return DefaultPublicDnsServer
	}
	return sp.publicDnsServer
}

// SetPublicDnsServer 设置公网dns服务
func (sp *Socks5Proxy) SetSpeedUpHosts(speedUpHosts []string) {
	sp.speedUpHosts = speedUpHosts
}

// 设置证书生成根路径
func (sp *Socks5Proxy) SetCertPath(certPath string) {
	sp.certPath = certPath
	sp.initCa()
}

// 获取主机对于ip列表，从多个dns获取ip
// 获取ip后首次获取不经测速，返回第一个，后续返回测速第一个
func (sp *Socks5Proxy) getIpsByHost(host string) []*HostTime {
	// 新的hosts地址
	hostIpAddrs := make([]*HostTime, 0)

	publicDnsServerList := sp.GetPublicDnsServer()
	wg := new(sync.WaitGroup)
	wg.Add(len(publicDnsServerList))
	for _, v := range publicDnsServerList {
		go func(dnsAddr string) {
			defer wg.Done()
			// dns请求客户端
			cli := sp.dnsCli.Get().(*dns.Client)
			defer sp.dnsCli.Put(cli)
			// 拼一下端口
			dnsAddr = fmt.Sprintf("%s:53", dnsAddr)

			// 先查询ipv6
			q := &dns.Msg{
				MsgHdr: dns.MsgHdr{
					RecursionDesired: true,
				},
				Question: []dns.Question{
					{
						Name:   dns.Fqdn(host),
						Qtype:  dns.TypeA,
						Qclass: dns.ClassINET,
					},
				},
			}
			ctx, cancel := context.WithTimeout(context.Background(), 900*time.Millisecond)
			defer cancel()
			r, _, err := cli.ExchangeContext(ctx, q, dnsAddr)
			if err != nil {
				log.Println("查询ipv6地址错误", dnsAddr, host, err)
				return
			}
			for _, ans := range r.Answer {
				if a, ok := ans.(*dns.A); ok {
					hostIpAddrs = append(hostIpAddrs, &HostTime{
						DnsServer: dnsAddr,
						DnsQtype:  dns.TypeA,
						IpAddr:    a.A.String(),
						ConnTime:  0,
						IsConn:    true,
					})
				}
			}
			// 查询ipv4地址
			q.Question[0].Qtype = dns.TypeAAAA
			r, _, err = cli.ExchangeContext(ctx, q, dnsAddr)
			if err != nil {
				log.Println("查询ipv4地址错误", v, host, err)
				return
			}
			for _, ans := range r.Answer {
				if a, ok := ans.(*dns.AAAA); ok {
					hostIpAddrs = append(hostIpAddrs, &HostTime{
						DnsServer: dnsAddr,
						DnsQtype:  dns.TypeAAAA,
						IpAddr:    a.AAAA.String(),
						ConnTime:  0,
						IsConn:    true,
					})
				}
			}
		}(v)
	}
	wg.Wait()
	// 去重
	newHostIpAddrs := make([]*HostTime, 0)
	for _, v := range hostIpAddrs {
		isExist := false
		for _, v1 := range newHostIpAddrs {
			if v.IpAddr == v1.IpAddr {
				isExist = true
				break
			}
		}
		if !isExist {
			newHostIpAddrs = append(newHostIpAddrs, v)
		}
	}

	// 锁一下防止并发访问
	sp.hostIpAddrsLock.Lock()
	defer sp.hostIpAddrsLock.Unlock()
	// 更新hosts地址
	sp.hostIpAddrs[host] = newHostIpAddrs
	return hostIpAddrs
}

// 获取主机对应一个ip,代理连接时取用，默认给速度最快的
// 如果没有，取hosts第一个，逐个尝试，每个连接超时1秒，如果无法连接成功，将ip后置排序
func (sp *Socks5Proxy) getIpByHost(host string) (apAddr string) {
	defer func() {
		log.Println("获取一个主机ip", host, apAddr)
	}()
	sp.hostIpAddrsLock.Lock()
	if len(sp.hostIpAddrs[host]) > 0 {
		sp.hostIpAddrsLock.Unlock()
		apAddr = sp.hostIpAddrs[host][0].IpAddr
		return
	}
	sp.hostIpAddrsLock.Unlock()

	hostIpAddrs := sp.getIpsByHost(host)
	if len(hostIpAddrs) > 0 {
		apAddr = hostIpAddrs[0].IpAddr
		return
	}
	// 如果返回空，直接连接
	return
}

// ip测速，检测一个ip的速度
func (sp *Socks5Proxy) getIpConnTime(ipAddr string) time.Duration {
	t1 := time.Now()
	for i := 0; i < TestIpConnTimeCount; i++ {
		conn, err := telnet.DialTo(net.JoinHostPort(ipAddr, "443"))
		if err != nil {
			log.Println("ip测试连接速度错误", err)
			return -1
		}
		if conn != nil {
			conn.Close()
		} else {
			return -1
		}
	}
	return time.Since(t1) / TestIpConnTimeCount
}

// 排序一个主机名对应ip访问速度
func (sp *Socks5Proxy) sortIpsConnTime(host string) {
	sp.hostIpAddrsLock.Lock()
	hostIpAddrs := sp.hostIpAddrs[host]
	sp.hostIpAddrsLock.Unlock()
	for _, v := range hostIpAddrs {
		connTime := sp.getIpConnTime(v.IpAddr)
		if connTime < 0 {
			v.IsConn = false
			v.ConnTime = connTime
		}
	}
	// <0的往后排
	sort.Slice(hostIpAddrs, func(i, j int) bool {
		if hostIpAddrs[i].ConnTime < 0 {
			return false
		}
		if hostIpAddrs[j].ConnTime < 0 {
			return true
		}
		return hostIpAddrs[i].ConnTime < hostIpAddrs[j].ConnTime
	})
	sp.hostIpAddrsLock.Lock()
	sp.hostIpAddrs[host] = hostIpAddrs
	sp.hostIpAddrsLock.Unlock()
}

// 定时测速，每10分钟一次
func (sp *Socks5Proxy) cronIpConnTime() {
	sp.hostIpAddrsLock.Lock()
	hosts := make([]string, 0)
	for k := range sp.hostIpAddrs {
		hosts = append(hosts, k)
	}
	sp.hostIpAddrsLock.Unlock()

	// 执行排序
	for _, v := range hosts {
		sp.sortIpsConnTime(v)
	}
}

// 处理代理
func (sp *Socks5Proxy) forward(ctx context.Context, network, addr string) (net.Conn, error) {
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		log.Println("解析连接主机名端口错误", err)
		return nil, err
	}
	log.Println("主机名", host, "端口", port)
	if port == "443" {
		return sp.forward443(ctx, network, addr, host)
	}
	return new(net.Dialer).DialContext(ctx, network, addr)
}

// 处理https 443端口代理
func (sp *Socks5Proxy) forward443(ctx context.Context, network, addr, host string) (net.Conn, error) {
	log.Println("https有连接", addr)

	// 判断主机名是否需要代理
	isExist := false
	for _, v := range sp.speedUpHosts {
		if strings.HasSuffix(host, v) {
			isExist = true
			break
		}
	}
	// 不存在不代理
	if !isExist {
		return new(net.Dialer).DialContext(ctx, network, addr)
	}

	d := &net.Dialer{Timeout: ProxyDialTimeout}
	config := &tls.Config{
		InsecureSkipVerify: true,
		VerifyPeerCertificate: func(rawCerts [][]byte, _ [][]*x509.Certificate) error {
			// bypass tls verification and manually do it
			certs := make([]*x509.Certificate, len(rawCerts))
			for i, asn1Data := range rawCerts {
				cert, _ := x509.ParseCertificate(asn1Data)
				certs[i] = cert
			}
			opts := x509.VerifyOptions{
				DNSName:       host,
				Intermediates: x509.NewCertPool(),
			}
			for _, cert := range certs[1:] {
				opts.Intermediates.AddCert(cert)
			}
			_, err := certs[0].Verify(opts)
			if err != nil {
				log.Println("证书Verify错误", err)
			}
			return err
		},
	}
	dIp := sp.getIpByHost(host)
	if dIp == "" {
		return new(net.Dialer).DialContext(ctx, network, addr)
	}
	dAddr := net.JoinHostPort(dIp, "443")
	log.Println("代理IP地址", dAddr)
	dconn, err := tls.DialWithDialer(d, "tcp", dAddr, config)
	if err != nil {
		return nil, err
	}

	c, s := newBiLocalConn()
	c.Conn = dconn
	conn := tls.Server(s, tlsSerConf)
	go sp.communicate(dconn, conn)
	return c, nil
}

// 双向copy数据
func (sp *Socks5Proxy) communicate(i, j net.Conn) {
	defer func() {
		if _err := recover(); _err != nil {
			log.Println("双向copy数据错误", _err)
		}
	}()

	defer func() {
		if err := i.Close(); err != nil {
			log.Println("关闭代理服务端连接错误", err)
		}
	}()
	defer func() {
		if err := j.Close(); err != nil {
			log.Println("关闭客户端连接错误", err)
		}
	}()

	finished := make(chan struct{}, 2)
	go func() {
		_, _ = io.Copy(i, j)
		finished <- struct{}{}
	}()
	go func() {
		_, _ = io.Copy(j, i)
		finished <- struct{}{}
	}()
	<-finished
}

type nilResolver struct{}

func (n nilResolver) Resolve(ctx context.Context, name string) (context.Context, net.IP, error) {
	return ctx, nil, nil
}

type LocalConn struct {
	r io.ReadCloser
	w io.WriteCloser
	net.Conn
}

func (c *LocalConn) Read(b []byte) (n int, err error) {
	return c.r.Read(b)
}

func (c *LocalConn) Write(b []byte) (n int, err error) {
	return c.w.Write(b)
}

func (c *LocalConn) Close() error {
	err := c.r.Close()
	if err != nil {
		_ = c.w.Close()
		return err
	}
	return c.w.Close()
}

func newBiLocalConn() (c, s *LocalConn) {
	c = new(LocalConn)
	s = new(LocalConn)
	c.r, s.w = io.Pipe()
	s.r, c.w = io.Pipe()
	return
}

// 启动代理
func (sp *Socks5Proxy) Start() {
	if sp.isStart {
		return
	}
	conf := &socks5.Config{
		Resolver: nilResolver{},
		Dial:     sp.forward,
	}
	server, err := socks5.New(conf)
	if err != nil {
		sp.err = err
		return
	}
	// 设置为已启动
	sp.isStart = true
	sp.err = nil
	defer func() {
		sp.isStart = false
	}()
	l, err := net.Listen("tcp", sp.proxyAddr)
	if err != nil {
		sp.err = err
		return
	}
	sp.listener = l
	sp.err = server.Serve(l)
}

// 停止代理
func (sp *Socks5Proxy) Stop() {
	sp.isStart = false
	sp.err = nil
	if sp.listener != nil {
		sp.err = sp.listener.Close()
	}
}

/* ca证书 */
func (sp *Socks5Proxy) GenCaCert() error {
	max := new(big.Int).Lsh(big.NewInt(1), 128)   //把 1 左移 128 位，返回给 big.Int
	serialNumber, _ := rand.Int(rand.Reader, max) //返回在 [0, max) 区间均匀随机分布的一个随机值
	subject := pkix.Name{                         //Name代表一个X.509识别名。只包含识别名的公共属性，额外的属性被忽略。
		Organization:       []string{"shiguanghuxian"},
		OrganizationalUnit: []string{"shiguanghuxian"},
		CommonName:         "GitHub Proxy",
		Country:            []string{"CN"},
		Locality:           []string{"Beijing"},
		Province:           []string{"Beijing"},
	}
	template := x509.Certificate{
		BasicConstraintsValid: true,
		IsCA:                  true,
		SerialNumber:          serialNumber, // SerialNumber 是 CA 颁布的唯一序列号，在此使用一个大随机数来代表它
		Subject:               subject,
		NotBefore:             time.Now(),
		NotAfter:              time.Now().Add(365 * 24 * time.Hour),
		KeyUsage:              x509.KeyUsageDigitalSignature | x509.KeyUsageContentCommitment | x509.KeyUsageKeyEncipherment | x509.KeyUsageDataEncipherment | x509.KeyUsageKeyAgreement | x509.KeyUsageCertSign | x509.KeyUsageCRLSign | x509.KeyUsageEncipherOnly | x509.KeyUsageDecipherOnly, //KeyUsage 与 ExtKeyUsage 用来表明该证书是用来做服务器认证的
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth, x509.ExtKeyUsageClientAuth, x509.ExtKeyUsageCodeSigning, x509.ExtKeyUsageEmailProtection, x509.ExtKeyUsageTimeStamping},                                                                                           // 密钥扩展用途的序列
		Issuer:                subject,
	}
	pk, _ := rsa.GenerateKey(rand.Reader, 2048) //生成一对具有指定字位数的RSA密钥

	// 基于模板创建一个新的证书
	// 第二个第三个参数相同，则证书是自签名的
	// 返回的切片是DER编码的证书
	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, &pk.PublicKey, pk) //DER 格式
	if err != nil {
		return err
	}

	certFile, err := os.Create(strings.Join([]string{sp.certPath, "cert.pem"}, string(os.PathSeparator)))
	if err != nil {
		return err
	}
	defer certFile.Close()
	err = pem.Encode(certFile, &pem.Block{Type: "CERTIFICAET", Bytes: derBytes})
	if err != nil {
		return err
	}
	keyFile, err := os.Create(strings.Join([]string{sp.certPath, "key.pem"}, string(os.PathSeparator)))
	if err != nil {
		return err
	}
	defer keyFile.Close()
	err = pem.Encode(keyFile, &pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(pk)})
	if err != nil {
		return err
	}
	sp.initCa()
	return nil
}

func (sp *Socks5Proxy) getCertificate(info *tls.ClientHelloInfo) (*tls.Certificate, error) {
	if info.ServerName == "" {
		return nil, errors.New("no SNI info")
	}
	log.Println("证书主机名", info.ServerName)

	if cert, ok := sp.cacheCert.Load(info.ServerName); ok {
		return cert.(*tls.Certificate), nil
	}

	secondary, err := publicsuffix.EffectiveTLDPlusOne(info.ServerName)
	if err != nil {
		log.Println("invalid hostname", secondary, err)
		return nil, err
	}

	var cn string
	if info.ServerName == secondary {
		cn = secondary
	} else {
		dot := strings.IndexByte(info.ServerName, '.')
		cn = info.ServerName[dot+1:]
	}

	if cert, ok := sp.cacheCert.Load(cn); ok {
		return cert.(*tls.Certificate), nil
	}

	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		log.Println("failed to generate private key", err)
		return nil, err
	}

	serialNumberLimit := new(big.Int).Lsh(big.NewInt(1), 128)
	serialNumber, err := rand.Int(rand.Reader, serialNumberLimit)
	if err != nil {
		log.Println("failed to generate serial number", serialNumber, err)
		return nil, err
	}

	template := &x509.Certificate{
		SerialNumber: serialNumber,
		Subject: pkix.Name{
			CommonName: cn,
			Country:    []string{"CN"},
		},

		NotBefore: time.Now(),
		NotAfter:  time.Now().Add(certExpire),

		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		DNSNames:              []string{"*." + cn, cn},
	}

	derBytes, err := x509.CreateCertificate(rand.Reader, template, caParent, priv.Public(), caPriKey)
	if err != nil {
		log.Println("failed to create certificate", err)
		return nil, err
	}

	cert := &tls.Certificate{
		Certificate: [][]byte{derBytes},
		PrivateKey:  priv,
	}
	sp.cacheCert.Store(cn, cert)
	return cert, nil
}
