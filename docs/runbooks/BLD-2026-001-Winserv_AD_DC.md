# Build Runbook: Bare-Metal Windows Server AD DC Authenticating RHEL node1

| Field | Value |
|---|---|
| Build ID | BLD-2026-001 |
| Date / window | 2026-11-21 - 2026-11-22 |
| Owner | Connor Baird |
| Target host | ~~VM~~ / bare metal / ~~container~~ |
| Risk level | Low / ~~Medium~~ / ~~High~~ |
| Status | ~~Draft~~ / ~~Approved~~ / Complete / ~~Backed out~~ |

## 1. Objective
- Node1 authenticating against a single AD DC. Members of linux-admins group can sudo, members of linux-users can log in only. node1 will be configured by hand. 

## 2. Scope
- **In scope:** AD DC set up, realm join, user groups, sudo rules, DNS and time sync with DC, SSSD, kerberos
- **Out of scope:** Advanced rules : Group Policy, LDAPS/certificates. SSO, second Domain Controller. No DHCP role on the DC.
- node2 - BLD-2026-002 to be completed later 

## 3. Build specification
### node1
| Item | Value |
|---|---|
| Hostname | node1.lab.home.arpa |
| IP / gateway / DNS | 192.168.0.181/24 / gw .1 / DNS 192.168.0.10 |
| CPU / RAM / disk | 2 cores / 2GiB RAM / 20GB HDD |
| OS & version | RHEL 10.2 |
| Applications | realmd,sssd,adcli |
| Install media + checksum | N/A - existing VM |
| Related ADR / design | n/a |

### DC01 
| Item | Value |
|---|---|
| Hostname | dc01.lab.home.arpa |
| IP / gateway / DNS | 192.168.0.10/24 / gw .1 / DNS 127.0.0.1(forwarder .1) |
| CPU / RAM / disk | Intel i7-4510 / 8GB RAM / 128GB SSD |
| OS & version | Windows Server 2022 Standard Evaluation (Server Core)|
| Applications | AD DS & DNS |
| Install media + checksum | unverified  |
| Related ADR / design | n/a |

## 4. Impact & risk
- **Existing systems touched:** Windows DC is fresh, node1 and node2 were used for RHCSA labs. No longer critical.
- **Shared resources used:** Both Proxmox node and DC01 are connected using the same network switch. No other connection.
- **Key risks:** Time drain during diagnostics/set up → Pay close attention to DNS and time sync between DC and nodes. Shared household network - IP conflicts. DC is a laptop with battery removed - risk of power disruption. Credentials in plain text - all passwords prompted at run-time.

## 5. Pre-checks
- [x] Hostname and IP free (no conflicts)
- [x] Host resources sufficient
- [ ] Install media downloaded and checksum verified
- [x] Prerequisites in place (accounts, licences, network)

**notes**
- Windows Server checksum unverified 
- IP not checked with DHCP - checked free with nmap scan and ping 

## 6. Protect existing systems
| Touched item | Backup method | Location | Done |
|---|---|---|---|
| node1 | Proxmox snapshot | Proxmox host hard drive | [x] |
| DC01 | None-fresh install | N/A | [n/a] |

## 7. Build steps

### Phase 1 - Windows AD DC

#### 1a - Stop SConfig auto-launching, get confirmation of install, build no. and network adapter 

```powershell
Set-SConfig -AutoLaunch $false
Get-ComputerInfo -Property WindowsProductName, OsVersion, OsBuildNumber
Get-NetAdapter 
```
- [x] Done

**Verification**
- PowerShell prompt, wired adapter listed with Status Up

**Notes**
- Make note of InterfaceAlias of the wired NetAdapter
- 2026-11-21 15:05 - Win Server 2022 Eval, NetAdapter Realtek Ethernet

#### 1b - Baseline configs - static IP, temporary DNS for windows update
```powershell
$if = "Ethernet"
Set-NetIPInterface -InterfaceAlias $if -Dhcp Disabled
Get-NetIPAddress -InterfaceAlias $if -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false
Get-NetRoute -InterfaceAlias $if -DestinationPrefix 0.0.0.0/0 -ErrorAction SilentlyContinue |
  Remove-NetRoute -Confirm:$false
New-NetIPAddress -InterfaceAlias $if -IPAddress 192.168.0.10 -PrefixLength 24 `
  -DefaultGateway 192.168.0.1
Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 192.168.0.1
```
**Verification**
```powershell
Get-NetIPConfiguration -InterfaceAlias "Ethernet"
Test-NetConnection 192.168.0.1
Resolve-DnsName microsoft.com
```
- [x] Done

**Notes**
- 15:20 Get command returned correct IP, DNS. Ping at 2ms

#### 1c - Set time zone, allow ICMP for ping, set power configs to never sleep, hibernate or react when lid closed 
```powershell
Set-TimeZone -Id "GMT Standard Time"
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In 
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /change monitor-timeout-ac 5
```

**Verification**
```powershell
Get-TimeZone
Get-NetFirewallRule -Enabled True -Direction Inbound |
  Where-Object { $_.DisplayName -match 'ICMP|Echo Request' } |
  Select-Object DisplayName, Profile, Action
```

- [x] Done

**Notes**
- 15:31 TZ showing correctly, ICMP inbound enabled 

#### 1d - Windows Update, rename the AD host and reboot 
```powershell
sconfig # 6
Rename-Computer -NewName DC01 -Restart
```

**Verification**
- After reboot, hostname returns DC01, ping 192.168.0.10 works from node1, and
Windows Update shows nothing pending.

- [x] Done

**Notes**
- Rename must be done and confirmed prior to promoting DC. Amending after promoting is multi-step change
- 15:43 machine rebooted, IPv4 showing correct, hostname returns DC01 - success 

#### 1e - Install the roles and perform optional dry run 
```powershell
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

Test-ADDSForestInstallation -DomainName "lab.home.arpa" -DomainNetbiosName "LAB" `
  -InstallDns -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password")
```

- [x] Done

**Notes**
- 15:52 - success. Password passed complexity test and operation succeeded. IPv6 warning reviewed, not used.

#### 1f - Promote the DC
```powershell
Install-ADDSForest `
  -DomainName "lab.home.arpa" `
  -DomainNetbiosName "LAB" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns `
  -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password") `
  -Force
```

**Verification**
- The login screen accepts LAB\Administrator

- [x] Done

**Notes**
- 16:11 Success- rules applied, Forest set up, system rebooted and prompted for new password on login.

#### 1g - Verification of DC health 
```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode, PDCEmulator
Get-ADDomainController | Select-Object HostName, IPv4Address, Site, IsGlobalCatalog
Get-Service ADWS, KDC, Netlogon, NTDS, DNS | Format-Table Name, Status
dcdiag /q 
```

- [X] Done

**Notes**
- 16:28 all objects as expected, all services active 

#### 1h - Set DNS client and forwarders 
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1
Set-DnsServerForwarder -IPAddress 192.168.0.1
Get-DnsServerForwarder
Clear-DnsClientCache
```

- [x] Done

**Notes**
- 16:39 - forwarder address correct, clear command returns no errors

#### 1i - Reverse lookup & PTR for DC
```powershell
Add-DnsServerPrimaryZone -NetworkId "192.168.0.0/24" -ReplicationScope Forest
Add-DnsServerResourceRecordPtr -ZoneName "0.168.192.in-addr.arpa" -Name "10" `
  -PtrDomainName "dc01.lab.home.arpa"
```

- [x] Done

**Notes**
- 16:57 - Success 

#### 1j - Confirm the records needed for the Node1
```powershell
Resolve-DnsName dc01.lab.home.arpa
Resolve-DnsName 192.168.0.10
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.lab.home.arpa
Resolve-DnsName -Type SRV _kerberos._tcp.lab.home.arpa
Resolve-DnsName -Type SRV _kerberos._udp.lab.home.arpa
Resolve-DnsName www.redhat.com
```

- [x] Done 

**Notes**
- 17:04 DNS records correct, with all commands returning correct info. Redhat.com resolves, with a made up incorrect URL coming back with unreachable - test validated. 

#### 1k - Ensure time is authoritative on PDCEmulator
```powershell
w32tm /config /manualpeerlist:"0.uk.pool.ntp.org,0x8 1.uk.pool.ntp.org,0x8" `
/syncfromflags:manual /reliable:yes /update
Restart-Service w32time
w32tm /resync /force
w32tm /query /status 
```

- [x] Done

**Notes**
- 17:10 - ntp pools added, w32time restarted, sync status correct 

#### 1l - OU structure, group and test user 
```powershell
$root = "DC=lab,DC=home,DC=arpa"
New-ADOrganizationalUnit -Name "Lab" -Path $root
New-ADOrganizationalUnit -Name "Users" -Path "OU=Lab,$root"
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Lab,$root"
New-ADOrganizationalUnit -Name "Linux" -Path "OU=Servers,OU=Lab,$root"
New-ADGroup -Name "linux-users" -GroupScope Global -GroupCategory Security `
  -Path "OU=Users,OU=Lab,$root"
New-ADUser -Name "Test User" -GivenName Test -Surname User -SamAccountName testuser `
  -UserPrincipalName "testuser@lab.home.arpa" -Path "OU=Users,OU=Lab,$root" `
  -AccountPassword (Read-Host -AsSecureString "testuser password") -Enabled $true
Add-ADGroupMember -Identity "linux-users" -Members testuser
Get-ADUser testuser -Properties MemberOf | Select-Object SamAccountName, Enabled, MemberOf
New-ADGroup -Name "linux-admins" -GroupScope Global -GroupCategory Security -Path "OU=Users,OU=Lab,$root"
New-ADUser -Name "Admin Test" -SamAccountName admintest -UserPrincipalName "admintest@lab.home.arpa" `
  -Path "OU=Users,OU=Lab,$root" -AccountPassword (Read-Host -AsSecureString "admintest password") -Enabled $true
Add-ADGroupMember -Identity "linux-admins" -Members admintest
Add-ADGroupMember -Identity "linux-users"  -Members admintest
```

- [x] Done

**Notes**
- 1l failed due to an empty $root (session variable lost). Detected by Get-ADOrganizationalUnit showing only the default OU. Fix: re-run 1l in full, with $root variable being set at the start of the session.
- 17:37 - adding test and admin user succeeded, with them showing as enabled, and member of linux-users. Both users successfully in their respective groups. 

#### 1m - Phase 1 sign off
```powershell
$root = "DC=lab,DC=home,DC=arpa"
Get-ADOrganizationalUnit -Filter * | Select-Object Name                   # Domain Controllers, Lab, Users, Servers, Linux
Get-ADGroupMember linux-admins | Select-Object SamAccountName             # admintest
Get-ADGroupMember linux-users  | Select-Object SamAccountName             # testuser, admintest
dcdiag /q                                                                 # no output
w32tm /query /source                                                      # a pool.ntp.org server, NOT "Local CMOS Clock"
Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4   # 127.0.0.1
```
- [x] Done

**Notes**
- 17:50 - dcdiag /q returned a warning about SYSVOL. DC01 failed test DFSREvent - a common warning for a new DC.
- 17:53 all other tests passed with no errors or warnings - DC is set up from the windows side. NTP showing pool and NOT CMOS. 
- 17:58 DFSREvent investigated - SYSVOL and NETLOGON shared, replsummary empty due to being single DC with no partners. 
  Test: run "dcdiag /test:DFSREvent" at a later date. 
- 18:05 - Phase 1 completed, and build paused for today. Build to continue tomorrow, starting with the DFSREvent test, then phase 2.


### Phase 2 - RHEL 10 Node 1

#### 2a - Locate Proxmox VMID and take a snapshot 
```bash
qm list 
qm snapshot 103 pre-ad-join --description "before realm join"
```

- [x] Done

**Notes**
- 2026-11-22 14:59 Node1 snapshot saved

#### 2b - Set Node1 FQDN hostname  
```bash
sudo hostnamectl set-hostname node1.lab.home.arpa
```
 **Verification**
 ```bash
hostnamectl         # should return "node1.lab.home.arpa"
```

- [x] Done

**Notes**
- 15:01 host name set, verified with hostnamectl 

#### 2c - Point node1 DNS at the DC 
```bash
nmcli -g NAME,DEVICE con show --active       # note the connection name. nmtui can also be used to edit the DNS server. 
CON=ens18
sudo nmcli con mod "$CON" ipv4.dns 192.168.0.10 ipv4.dns-search lab.home.arpa \
  ipv4.ignore-auto-dns yes
sudo nmcli con mod "$CON" ipv6.ignore-auto-dns yes   # added during review 
sudo nmcli con up "$CON"
sudo nmcli con show                     # check for stale profiles. Delete with `nmcli con delete <name>`
```
**Verification**
```bash
cat /etc/resolv.conf            # 192.168.0.10 set for nameserver, lab.home.arpa for search
```

- [x] Done

**Notes**
- 15:08 con up took some time. resolv.conf also shows example.local as search - TBC if this is an issue.
- 2026-11-22 20:13 - Additional search domain came from redundant network profile from RHCSA labs. Profile deleted and /etc/resolv.conf coming back clean. 

#### 2d - Install packages  
```bash
sudo dnf install -y realmd sssd adcli oddjob oddjob-mkhomedir samba-common-tools \
  krb5-workstation bind-utils
```

- [x] Done

**Notes**
- 15:11 - all installed or upgraded. 

#### 2e - Check DNS on node1  
```bash
dig +short dc01.lab.home.arpa                     # expected: 192.168.0.10
dig +short -x 192.168.0.10                        # expected: dc01.lab.home.arpa
dig +short -t SRV _ldap._tcp.lab.home.arpa        # expected: 0 100 389 dc01.lab.home.arpa
dig +short -t SRV _kerberos._tcp.lab.home.arpa    # expected: 0 100 88 dc01.lab.home.arpa
```

- [x] Done

**Notes**
- 15:14 all correct results returned, even with some noise in the results - some connections timing out and example.local as an additional search domain.
- 2026-11-22 20:13 - Connections timing out and additional search domain came from redundant network profile from RHCSA labs. Profile deleted and all dig commands returning expected values with no noise.

#### 2f - Point chrony at the DC  
```bash
sudo sed -i 's/^pool /#pool /; s/^server /#server /' /etc/chrony.conf
echo "server dc01.lab.home.arpa iburst" | sudo tee -a /etc/chrony.conf
sudo systemctl restart chronyd

```
**Verification**
```bash
chronyc sources -v                          # dc01 line should start with ^*
chronyc tracking                            # System time offset under 1 second
```

- [x] Done

**Notes**
- 15:18 Chrony sources confirmed, very small difference from DC01

#### 2g - Discover the realm   
```bash
realm discover lab.home.arpa
```
**Verification**
Expected output: "type: kerberos
                  realm-name: LAB.HOME.ARPA
                  domain-name: lab.home.arpa
                  configured: no
                  server-software: active-directory
                  client-software: sssd"
Ensure all required packages are installed 

- [x] Done

**Notes**
- 15:21 - realm discover returned all info except server-software and client-software result. TBC if this is an issue.
- 21:07 - realm discover now showing all requirements 

#### 2h - Join the realm    
```bash
sudo realm join -v --user=Administrator \
--computer-ou="OU=Linux,OU=Servers,OU=Lab,DC=lab,DC=home,DC=arpa" \
lab.home.arpa
```

- [x] Done

**Notes**
- 15:29 Join successful! Looks like sssd has been enabled and restarted, but will need to verify 

#### 2i - Verify the realm join     
```bash
realm list                            # expected: configured: kerberos-member, login-policy shown
sudo klist -k                         # expected: NODE1$@LAB.HOME.ARPA entries, several enctypes
systemctl is-active sssd              # expected: active
systemctl is-enabled sssd             # expected: enabled
id testuser@lab.home.arpa             # expected: uid/gid plus linux-users@lab.home.arpa, domain users@...
getent passwd testuser@lab.home.arpa  # expected: .../home/testuser@lab.home.arpa:/bin/bash
getent group "linux-users@lab.home.arpa"
kinit testuser@LAB.HOME.ARPA && klist # expected: realm in CAPITALS; shows krbtgt/LAB.HOME.ARPA ticket
kdestroy
```

- [x] Done

**Notes**
- 15:35 - all working as expected, with all results matching the notes above.

#### 2j - Restrict login to linux-users
```bash
sudo realm permit -g linux-users@lab.home.arpa
```
**Verification:**
`realm list` shows login-policy: allow-permitted-logins, permitted-groups: linux-users@lab.home.arpa

- [x] Done

**Notes**
- 19:28 realm list returns expected results 

#### 2k - Sudo for linux-admins
```bash
echo '%linux-admins@lab.home.arpa ALL=(ALL) ALL' | sudo tee /etc/sudoers.d/ad-linux-admins
sudo chmod 0440 /etc/sudoers.d/ad-linux-admins
sudo visudo -c
```
**Verification:** `visudo -c` reports all files parsed OK
- [x] Done

**Notes**
- 19:30 visudo -c returned OK on both sudoers files.
- Keep a second root/local-sudo session open until 2l passes

#### 2l - Functional tests
```bash
su - admintest@lab.home.arpa               # login works, home dir created
sudo whoami                                # root
exit
su - testuser@lab.home.arpa                # login works
sudo -l                                    # "not allowed to run sudo"
exit
ssh administrator@lab.home.arpa@node1      # denied (not in linux-users). MUST BE RUN FROM NON-ROOT SHELL `su -` from root bypasses PAM checks
```
- [x] Done

**Notes**
- 19:57 login tests work as expected from a non-root terminal. su - Administrator works due to root terminal privileges. Administrator denied via SSH from a non-root session.

#### 2m - Confirm from the DC
```powershell
Get-ADComputer -Filter * -SearchBase "OU=Linux,OU=Servers,OU=Lab,DC=lab,DC=home,DC=arpa"
Resolve-DnsName node1.lab.home.arpa
```
**Verification:** NODE1 listed; resolves to 192.168.0.181 

- [x] Done

**Notes**
- 20:23 - NODE1 listed - A record for .181

#### 2n - Reboot test
```bash
sudo reboot
# after boot:
realm list; id admintest@lab.home.arpa; chronyc sources
```
**Verification:** all as 2h/2f; repeat 2l logins
- [x] Done

**Notes**
- 20:37 - Success. RHEL VM rebooted, realm list shows correct realms, login groups etc. Chrony still synced with AD DC. Task complete. Post-ad-join snapshot of node1 taken.

## 8. Acceptance tests
- [x] DC01 running and AD DC forest configured
- [x] DC01 connected to network with static IP and hostname configured
- [x] AD groups and users configured correctly into admin / standard groups
- [x] Node1 connect successful with DNS and chrony pointed at the DC
- [x] Admin users on node1 can use sudo. Standard users cannot
- [x] Everything survives a reboot

## 9. Back-out plan
- **Trigger:** Acceptance tests fail and cannot be fixed within the build window (2 sessions)
- **Steps:**
  1. Node1: qm rollback 103 pre-ad-join DC01: Remove-ADComputer NODE1
  2. Wipe DC01
  3. Release IP, DNS records, storage, firewall rules
- **Back-out validated:** [ ] - Untested - snapshot taken if required 

## 10. Operational readiness
- [ ] Added to backup schedule
- [x] Credentials stored in password manager
- [ ] Added to inventory / network diagram
- [x] Temporary access, rules and install files removed
- [ ] Documentation and config committed to repo

**Follow Up**
- [ ] DFSREvent re-test
- [ ] Evaluation expiry logged 2027-05-20
- [ ] BLD-2026-002 Ansible roles and playbook for configuring node2 

## 11. Build record (post-implementation review)
- **Outcome:** Success / ~~Partial~~ / ~~Backed out~~
- **Actual duration:** ~8 hours of solid work including documentation. Split into multiple sessions over 2 days. 
- **Deviations from plan:** - ipv6 records from stale network configuration. Using fresh non-root shell to check administrator login (su - overrides PAM checks) - step added mid-build. Ensure $variables at the correct time for step 1l. 
- **Issues encountered:** - 1l run out of order with $root unset in a new session ('bad syntax', then 'object not found'). dcdiag DFSREvent failure on the new DC (SYSVOL/NETLOGON verified, accepted). Sudo and login-restriction steps missing from the original plan, added mid-build. A stale RHCSA network profile listed an IPv6 DNS server and the example.local search domain, causing DNS timeouts. su from root bypassed the PAM access check, which invalidated the first administrator account denial test.
- **Lessons learned:** - Review nmcli con show and /etc/resolv.conf before building on reused hosts. Set ignore-auto-dns for both IPv4 and IPv6. Declare variables inside each step so steps can run on their own. Run steps in order. Plan for privileges (sudo, login policy), not just the join. Test access denial from a non-root session or over SSH.

## 12. References 
### RHEL Side
- https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/integrating_rhel_systems_directly_with_windows_active_directory/index
- https://computingforgeeks.com/join-active-directory-rocky-almalinux-rhel/
### Windows Server Side
- https://learn.microsoft.com/en-gb/powershell/module/activedirectory/?view=windowsserver2022-ps
- https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-
