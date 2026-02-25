---
title: 2024-3-4 容器中域名解析以及不同dnspolicy对域名解析的影响
weight: 41
---

# 一、coreDNS背景

##### 部署在kubernetes集群中的容器业务通过coreDNS服务解析域名，Coredns基于caddy框架，将整个CoreDNS服务都建立在一个使用Go编写的HTTP/2 Web 服务器Caddy上。通过插件化（链）架构，以预配置的方式（configmap卷挂载内容配置）选择需要的插件编译，按序执行插件链上的逻辑，通过四种方式（TCP、UDP、gRPC和HTTPS）对外直接提供DNS服务。

![image-20240304110320602](https://picture-base.oss-cn-hangzhou.aliyuncs.com/picture/202403041103699.png)

# 二、kubelet通过修改容器/etc/resolv.conf文件使得容器中可解析域名

##### 在kubernetes集群中，coreDNS服务和kube-apiserver通信获取clusterip和serviceName的映射关系，并且coreDNS本身通过clusterip（默认 xx.xx.3.10，比如集群clusterip网段为10.247.x.x，则coreDNS对外暴露服务的clusterip为10.247.3.10），我们知道操作系统域名服务器关键配置文件/etc/resolv.conf中的nameserver字段指定，所以只需要使得容器/etc/resolv.conf中 nameserver字段配置为coreDNS的clusterip地址即可。

##### 那么谁来完成容器/etc/resolv.conf的修改和如何修改？kubelet负责拉起容器，启动参数中--cluster-dns字段对应值就是该集群coreDNS的clusterip地址，kubelet在拉起容器中，根据Pod的dnsPolicy选项，把该值修改注入到容器中。

# 三、Pod不同dnsPolicy对容器/etc/resolv.conf的影响

![image-20240304110337886](https://picture-base.oss-cn-hangzhou.aliyuncs.com/picture/202403041103954.png)

- Default：如果dnsPolicy被设置为“Default”，则名称解析nameserver配置将从pod运行的节点/etc/resolv.conf继承。

```
# 节点/etc/resolv.conf配置
nameserver X.X.X.X
nameserver X.X.X.Y
options ndots:5 timeout:2 single-request-reopen
```

- ClusterFirst：如果dnsPolicy被设置为“ClusterFirst”，则使用集群coredns的service 地址作为Pod内/etc/resolv.conf中nameserver配置。

```
nameserver 10.247.3.10 
search default.svc.cluster.local svc.cluster.local cluster.local 
options ndots:5 
timeout:2 single-request-reopen
```

- ClusterFirstWithHostNet：对于使用hostNetwork网络模式运行的Pod，需明确设置其DNS策略“ClusterFirstWithHostNet”，否则 hostNetwork + ClusterFirst实际效果 = Default

  ```
  ClusterFirstWithHostNet 是 Kubernetes 中的一个 DNS 策略。当 Pod 使用 hostNetwork 模式运行时（即 hostNetwork: true），这个策略指示 Pod 优先使用 Kubernetes 环境的 DNS 服务（如 CoreDNS 提供的域名解析服务）进行域名解析。如果 Kubernetes 环境的 DNS 服务无法解析某个域名，那么该请求会被转发到从宿主机继承的 DNS 服务器上进行解析。
  
  这个策略确保了 Pod 在使用宿主机的网络命名空间时，仍然能够利用 Kubernetes 提供的 DNS 服务进行域名解析，从而保持了与 Kubernetes 集群中其他服务的连通性。这对于需要在 Pod 内访问集群内部服务或跨命名空间通信的场景非常有用。
  
  请注意，为了使用 ClusterFirstWithHostNet 策略，您需要在 Pod 的规格中显式设置 dnsPolicy 字段为 ClusterFirstWithHostNet，并且还需要将 hostNetwork 设置为 true 以启用 hostNetwork 模式。如果不设置 dnsPolicy: ClusterFirstWithHostNet，Pod 默认会使用所在宿主主机使用的 DNS，这可能会导致容器内无法通过 service name 访问 Kubernetes 集群中的其他 Pod。
  ```

  

```
nameserver 10.247.3.10 
search default.svc.cluster.local svc.cluster.local cluster.local 
options ndots:5 
timeout:2 single-request-reopen
```

- None：它允许用户自定义Pod内/etc/resolv.conf配置，忽略Kubernetes环境中默认的DNS设置。应使用dnsConfigPod规范中的字段提供所有DNS设置 。

/etc/resolv.conf相关配置说明

```
nameserver：表示指定的DNS服务地址IP，用于解析域名的服务器。

search：表示域名解析时指定的域名搜索域。解析域名的时候，会依搜索域顺序构建域名解析地址。进行域名解析，直到解析即可。如：svcname.default.svc.cluster.local --> svcname.svc.cluster.local --> svcname.cluster.local

options：其他选项。最常见的选项配置有：
-   ndots值：判断域名解析地址中包含的“.”是否大于或等于ndots设定值，如果是，则以请求解析域名地址作为全限定域名发起解析请求，不再进行search域构建域名地址；如果小于ndots，则按照search域构建域名地址，再逐序发起解析请求。
-   timeout：等待DNS服务器返回的超时时间。单位秒（s）。
```



