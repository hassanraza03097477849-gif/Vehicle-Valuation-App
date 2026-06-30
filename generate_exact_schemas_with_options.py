import os
import re
import json

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

output = ["import '../models/form_field_schema.dart';", "", "class BankSchemas {"]
map_entries = []

for bank, filename, schema_name in banks:
    vue_file = os.path.join(vue_dir, filename)
    if not os.path.exists(vue_file):
        continue
        
    with open(vue_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find formData mapping
    form_data_mapping = {}
    form_data_match = re.search(r'const\s+formData\s*=\s*\{([^}]+)\}', content, re.IGNORECASE)
    if form_data_match:
        form_data_block = form_data_match.group(1)
        for line in form_data_block.split('\n'):
            line = line.strip()
            if line and ':' in line and not line.startswith('//'):
                parts = line.split(':')
                key = parts[0].strip().replace("'", "").replace('"', '')
                val = parts[1].split(',')[0].strip()
                vmodel_name = val.replace('this.', '').split('.')[0].strip()
                form_data_mapping[vmodel_name] = key

    # Parse arrays in data() block
    arrays = {}
    data_match = re.search(r'data\(\)\s*\{([\s\S]*?)return\s*\{([\s\S]*?)\}\s*\}', content)
    if data_match:
        data_block = data_match.group(2)
        array_matches = re.findall(r'(\w+):\s*\[(.*?)\]', data_block, re.DOTALL)
        for arr_name, arr_items in array_matches:
            # Clean up the array items
            items = []
            for item in arr_items.split(','):
                item = item.strip().strip("'").strip('"')
                if item:
                    items.append(item)
            if items:
                arrays[arr_name] = items

    # Parse template
    template_match = re.search(r'<template>(.*?)</template>', content, re.DOTALL)
    if not template_match:
        continue
        
    template = template_match.group(1)
    current_section = 'General Info'
    fields = []
    seen_vmodels = set()
    
    lines = template.split('\n')
    for line in lines:
        section_match = re.search(r'<input type="button"[^>]*value="([^"]+)"', line)
        if section_match:
            current_section = section_match.group(1).strip()
            
        vmodel_match = re.search(r'v-model="([^"]+)"', line)
        if vmodel_match:
            vmodel_name = vmodel_match.group(1).strip()
            
            if vmodel_name in seen_vmodels:
                continue
            seen_vmodels.add(vmodel_name)
            
            input_type = 'text'
            options_str = 'null'
            
            if '<Select' in line or '<select' in line:
                input_type = 'dropdown'
                
                # Check for bound options :options="someArray"
                options_match = re.search(r':options="([^"]+)"', line)
                if options_match:
                    opt_var = options_match.group(1).strip()
                    if opt_var in arrays:
                        # Convert python list to dart list string
                        dart_list = "[" + ", ".join(f"'{i}'" for i in arrays[opt_var]) + "]"
                        options_str = dart_list
                
                # Check for hardcoded <option> tags inside <select>
                if '<select' in line:
                    # Not standard in this vue base, but just in case
                    pass
                    
            elif 'type="checkbox"' in line:
                input_type = 'checkbox'
            elif 'type="number"' in line:
                input_type = 'number'
            elif 'type="date"' in line:
                input_type = 'date'
            elif 'type="time"' in line:
                input_type = 'time'
            
            snake_case_key = form_data_mapping.get(vmodel_name)
            
            if not snake_case_key or snake_case_key == 'surveyor_id':
                continue
                
            label = snake_case_key.replace('_', ' ').title()
            section_safe = current_section.replace("'", "\\'")
            
            fields.append(f"    FormFieldSchema(key: '{snake_case_key}', label: '{label}', type: '{input_type}', section: '{section_safe}', options: {options_str}),")

    output.append(f"  static final List<FormFieldSchema> {schema_name} = [")
    output.extend(fields)
    output.append("  ];")
    output.append("")
    map_entries.append(f"    '{bank}': {schema_name},")

output.append("  static final Map<String, List<FormFieldSchema>> schemas = {")
output.extend(map_entries)
output.append("  };")
output.append("}")

with open('lib/schemas/bank_schemas.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output))

print('Perfect schema generation with hardcoded options complete.')
