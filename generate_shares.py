#!/usr/bin/env python
import yaml
import random

departments = ["MKT", "SALES", "TECH", "HR", "REMOTE"]
departments_without_dc2 = departments[:-1]
departments_dc2 = departments[-1:]
def generate_shares(dep: list[str], max_user: int, elements: int) -> dict:
    output = {"ad_groups": {}, "file_shares": {}}
    for i in range(elements):
        d = str(random.choice(dep))
        amount_member = random.randint(5,15)
        project_idx = random.randint(1,100)
        first_set = set([f"{random.choice(dep).lower()}{random.randint(1,max_user)}" for amount_member in range(amount_member)])
        output["ad_groups"][f"DL_FS_{d}_PROJECT_{project_idx}_RO"] = list(set([f"{random.choice(dep).lower()}{random.randint(1,max_user)}" for amount_member in range(amount_member)]) - first_set)
        output["ad_groups"][f"DL_FS_{d}_PROJECT_{project_idx}_RW"] = list(first_set)
        output["file_shares"][f"{d}_PROJECT_{project_idx}"] = {
            "read": f"DL_FS_{d}_PROJECT_{project_idx}_RO",
            "write": f"DL_FS_{d}_PROJECT_{project_idx}_RW",
        }
    return output

paris_output = generate_shares(dep=departments_without_dc2, max_user=990, elements=20)
lyon_output = generate_shares(dep=departments_dc2, max_user=18, elements=5)

with open('ansible_automation/inventory/group_vars/paris/shares.yaml', 'w') as f:
    yaml.dump(paris_output, f)

with open('ansible_automation/inventory/group_vars/lyon/shares.yaml', 'w') as f:
    yaml.dump(lyon_output, f)