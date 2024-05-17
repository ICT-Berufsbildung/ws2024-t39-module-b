#!/usr/bin/env python
import yaml
import random

departments = ["MKT", "SALES", "TECH", "HR", "REMOTE"]
departments_without_dc2 = departments[:-1]
departments_dc2 = departments[-1:]
output = {"ad_groups": {}, "file_shares": {}}
for i in range(25):
    d = str(random.choice(departments))
    amount_member = random.randint(5,15)
    max_user = 990 if d != "REMOTE" else 18
    choice_list = departments_without_dc2 if d != "REMOTE" else departments_dc2
    project_idx = random.randint(1,100)
    first_set = set([f"{random.choice(choice_list).lower()}{random.randint(1,max_user)}" for amount_member in range(amount_member)])
    output["ad_groups"][f"DL_FS_{d}_PROJECT_{project_idx}_RO"] = list(set([f"{random.choice(choice_list).lower()}{random.randint(1,max_user)}" for amount_member in range(amount_member)]) - first_set)
    output["ad_groups"][f"DL_FS_{d}_PROJECT_{project_idx}_RW"] = list(first_set)
    output["file_shares"][f"{d}_PROJECT_{project_idx}"] = {
        "read": f"DL_FS_{d}_PROJECT_{project_idx}_RO",
        "write": f"DL_FS_{d}_PROJECT_{project_idx}_RW",
        "server": "CSDRIVE" if d != "REMOTE" else "dc2"
    }

with open('shares.yaml', 'w') as f:
    yaml.dump(output, f)
