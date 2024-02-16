# ezdhcpd.sh

Wrapper/convenience script to automate the process of configuring a throwaway DHCP server on an
interface. Useful for when you just want to jack a device directly into your workstation's ethernet
port and connect directly to it.

Example usage:
```
# to start the server
sudo ezdhcpd.sh -i <INTERFACE_NAME>

# to clean up/tear down the configured interface after the server has exited
sudo ezdhcpd.sh -i <INTERFACE_NAME> clean
```
