# azure-app-services-private

As stated in [this documentation][1]:

> After this step, If you are accessing `hubstorageindia.blob.core.windows.net` from `hub-vnet` virtual machine it should be accessible using private ip only, because Azure DNS Private Zone is linked with `1`hub-vnet`. But if you try the same from on-premise network or spoke vnets using FQDN that will not work. To overcome this, you will need DNS forwarder in Azure and all vnets should be pointed to DNS forwarder server. But if you already have on-premise DNS server then you will have to configure Conditional Forwarding to make it work.



[1]: https://anktsrkr.github.io/post/connect-privately-to-azure-paas-resources-using-azure-private-endpoint/