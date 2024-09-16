# WorldSkills Competition 2024 - Module B Windows
This repository contains all the necessary artifacts to build the module B Windows test project for the WorldSkills competition 2024 in Lyon.

## Build VM image
### Prequisites
* Packer
* ESXi host

### Build
1. Create new file named `wsc2024.pkrvars.hcl` and specify the file path of the ISOs
```
win11_iso_url = "/path/to/ISOs/windows11-enterprise.iso"
winsrv_iso_url = "/path/to/ISOs/en-us_windows_server_2022_updated_july_2023_x64_dvd_541692c3.iso"
esx_password = "password"
marking_secret = "FranceLyon2024_1313"
```
2. Build images
```shell
cd vm-build

packer init windows-base.pkr.hcl
# Build Windows VMs
packer build -var-file=wsc2024.pkrvars.hcl windows-base.pkr.hcl
```
3. The VMs will be stored as ova format and are in separate folder with the prefix `output-`
