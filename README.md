# azure-app-services-private

The VM will be created with cloud-init and upgrade the kernel. Good idea to reboot:

```
az vm restart -g rg-myprivateapp -n vm-dns-myprivateapp
```

```
ssh dnsadmin@<IP>
```

Bind 9 should be already installed by the `.

```
sudo vim /etc/default/bind9
```


sudo systemctl enable bind9


sudo systemctl restart named
sudo systemctl enable named

named -g

## Hybrid Network - Azure <> Onprem/Other

https://feedback.azure.com/d365community/idea/f50bd7e3-8526-ec11-b6e6-000d3a4f0789

This [answer][2] in the learn forum explains the solution connect to Azure private resources in a hybrid landscape:

> For on-premises workloads to resolve the FQDN of a private endpoint, use a DNS forwarder to resolve the Azure service public DNS zone in Azure. A DNS forwarder is a Virtual Machine running on the Virtual Network linked to the Private DNS Zone that can proxy DNS queries coming from other Virtual Networks or from on-premises. This is required as the query must be originated from the Virtual Network to Azure DNS. A few options for DNS proxies are: Windows running DNS services, Linux running DNS services, Azure Firewall.



As stated in [this documentation][1]:

> After this step, If you are accessing `hubstorageindia.blob.core.windows.net` from `hub-vnet` virtual machine it should be accessible using private ip only, because Azure DNS Private Zone is linked with `1`hub-vnet`. But if you try the same from on-premise network or spoke vnets using FQDN that will not work. To overcome this, you will need DNS forwarder in Azure and all vnets should be pointed to DNS forwarder server. But if you already have on-premise DNS server then you will have to configure Conditional Forwarding to make it work.

Also important to notice:

> You should know that Network Security Group (NSG) rules and User Defined Routes do not apply to Private Endpoint.


[1]: https://anktsrkr.github.io/post/connect-privately-to-azure-paas-resources-using-azure-private-endpoint/
[2]: https://learn.microsoft.com/en-us/answers/questions/766816/how-to-get-on-prem-dns-to-resolve-the-fqdn-of-azur

https://serverspace.io/support/help/configure-bind9-dns-server-on-ubuntu/
https://www.debuntu.org/how-to-setting-up-a-dns-zone-with-bind9/
https://www.richinfante.com/2020/02/21/bind9-on-my-lan