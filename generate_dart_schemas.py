import os
import re

vue_dir = 'e:/laragon/www/mastererp/resources/js/components/Valuation/Reports/Vehicles/Bank/'
banks = [
    ('ASKBL', 'ASKBL.vue', 'askblSchema'),
    ('MCB', 'MCB.vue', 'mcbSchema'),
    ('BAF', 'BAF.vue', 'bafSchema'),
    ('FSBL', 'FSBL.vue', 'fsblSchema'),
    ('MBL', 'MBL.vue', 'mblSchema'),
    ('MMB', 'MMB.vue', 'mmbSchema'),
    ('SMBL', 'SMBL.vue', 'smblSchema'),
    ('OTHERS', 'otherBanks.vue', 'othersSchema')
]

def infer_field(key, section):
    dropdowns = ['car_make', 'car_class', 'body_type', 'car_drive', 'car_cng_kit', 'car_color', 'genre', 'feul_type', 'transmission', 'is_hybrid', 'seating_capacity', 'rim_type', 'odometer_reading']
    numbers = ['car_engine_capacity', 'total_assessed_value', 'fsv_rate', 'fsv_value', 'fsv_value_second', 'fsv_rate_second', 'total_assessed_value2']
    
    label = key.replace('_', ' ').title()
    if not section:
        section = 'General Info'
        
    section = section.replace("'", "\\'")
    
    if key in dropdowns:
        return f"    FormFieldSchema(key: '{key}', label: '{label}', type: 'dropdown', section: '{section}'),"
    elif key in numbers or 'value' in key or 'rate' in key or 'calculated' in key or 'amount' in key or 'fsv' in key:
        return f"    FormFieldSchema(key: '{key}', label: '{label}', type: 'number', section: '{section}'),"
    else:
        return f"    FormFieldSchema(key: '{key}', label: '{label}', type: 'text', section: '{section}'),"

output = ["import '../models/form_field_schema.dart';", "", "class BankSchemas {"]
map_entries = []

for bank, filename, schema_name in banks:
    vue_file = os.path.join(vue_dir, filename)
    if not os.path.exists(vue_file):
        continue
        
    with open(vue_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    vmodel_to_section = {}
    current_section = 'General Info'
    
    for line in lines:
        section_match = re.search(r'<input type="button"[^>]*value="([^"]+)"', line)
        if section_match:
            current_section = section_match.group(1).strip()
            
        vmodel_match = re.search(r'v-model="([^"]+)"', line)
        if vmodel_match:
            vmodel_name = vmodel_match.group(1).strip()
            if vmodel_name not in vmodel_to_section:
                vmodel_to_section[vmodel_name] = current_section

    start = -1
    for i, line in enumerate(lines):
        if 'constformdata={' in line.replace(' ', '').lower():
            start = i
            break
            
    end = -1
    for i in range(start, len(lines)):
        if '};' in lines[i]:
            end = i
            break

    if start == -1:
        continue
        
    form_data_lines = lines[start+1:end]
    output.append(f"  static final List<FormFieldSchema> {schema_name} = [")
    
    for line in form_data_lines:
        line = line.strip()
        if line and ':' in line and not line.startswith('//'):
            parts = line.split(':')
            key = parts[0].strip().replace("'", "").replace('"', '')
            
            if key == 'surveyor_id':
                continue
                
            val = parts[1].split(',')[0].strip()
            vmodel_name = val.replace('this.', '').split('.')[0].strip()
            
            section = vmodel_to_section.get(vmodel_name, 'General Info')
            output.append(infer_field(key, section))
            
    output.append("  ];")
    output.append("")
    map_entries.append(f"    '{bank}': {schema_name},")

output.append("  static final Map<String, List<FormFieldSchema>> schemas = {")
output.extend(map_entries)
output.append("  };")
output.append("}")

with open('lib/schemas/bank_schemas.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output))

print('Updated schemas with accurate Vue sections.')
