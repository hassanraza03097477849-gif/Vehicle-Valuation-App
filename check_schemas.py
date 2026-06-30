import os
import re

vue_dir = 'e:/laragon/www/mastererp/resources/js/components/Valuation/Reports/Vehicles/Bank/'
banks = ['ASKBL', 'MCB', 'BAF', 'FSBL', 'MBL', 'MMB', 'SMBL', 'OTHERS']

all_schemas = {}

for bank in banks:
    vue_file = os.path.join(vue_dir, f'{bank}.vue')
    if not os.path.exists(vue_file):
        print(f'File not found: {vue_file}')
        continue
        
    with open(vue_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    start = -1
    for i, line in enumerate(lines):
        if 'constformdata={' in line.replace(' ', '').lower():
            start = i
            break

    if start == -1:
        print(f'formData not found in {bank}')
        continue
        
    end = -1
    for i in range(start, len(lines)):
        if '};' in lines[i]:
            end = i
            break

    form_data_lines = lines[start+1:end]
    keys = []
    for line in form_data_lines:
        line = line.strip()
        if line and ':' in line and not line.startswith('//'):
            key = line.split(':')[0].strip()
            if key != 'surveyor_id':
                keys.append(key)
    all_schemas[bank] = set(keys)

# Print differences
for bank in banks:
    if bank in all_schemas:
        print(f'{bank} keys count: {len(all_schemas[bank])}')
        
print("---")
# Compare others to BAF (which is the detailedSchema)
baf_keys = all_schemas.get('BAF', set())
for bank in ['FSBL', 'MBL', 'MMB', 'SMBL', 'OTHERS']:
    if bank in all_schemas:
        keys = all_schemas[bank]
        missing_in_bank = baf_keys - keys
        extra_in_bank = keys - baf_keys
        if not missing_in_bank and not extra_in_bank:
            print(f'{bank} matches BAF exactly')
        else:
            print(f'{bank} vs BAF:')
            if missing_in_bank: print(f'  Missing in {bank} (present in BAF): {missing_in_bank}')
            if extra_in_bank: print(f'  Extra in {bank} (not in BAF): {extra_in_bank}')

# We should also output the keys of ASKBL and MCB to compare them to what is in bank_schemas.dart
print("ASKBL keys:", sorted(list(all_schemas.get('ASKBL', set()))))
print("MCB keys:", sorted(list(all_schemas.get('MCB', set()))))
