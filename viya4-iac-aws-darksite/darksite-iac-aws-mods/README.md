# Use IaC without requiring a NAT

This contains a script to mod your local clone of the IaC repo.  The script will modify parts of the IaC variables and modules so that you can use IaC without requiring the deployment of a NAT gateway, leveraging terraform override files.. read more about that [here](https://developer.hashicorp.com/terraform/language/files/override).

Notes: 

- This was tested on v5.4.0 of IaC... may not work with newer versions of IaC.  Feel free to take the script and modify as necessary.

# Procedures

1. Run the no_nat_iac_mod.sh script.

    - It will check if the viya4-iac-aws/ directory exists in the current folder.. if it does not, you have the option to automatically clone the repo to current directory.
    - It will mod the local clone by adding override.tf files in the appopriate folders.
    - It will automatically build the viya4-iac-aws:no-nat modded docker container if you choose or you can bypass and manually create if needed.

3. You'll use the viya4-iac-aws:no-nat modded container just like you would normally and it will omit creation of a NAT GW. 