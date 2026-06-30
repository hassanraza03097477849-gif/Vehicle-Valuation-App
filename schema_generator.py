import re

dart_file = 'e:/flutter/WORKING PROJECTS/vehicle_valuation_app/lib/schemas/bank_schemas.dart'
with open(dart_file, 'r', encoding='utf-8') as f:
    dart_code = f.read()

# First we need to get the schema_lines
vue_file = 'e:/laragon/www/mastererp/resources/js/components/Valuation/Reports/Vehicles/Bank/BAF.vue'
with open(vue_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start = 0
for i, line in enumerate(lines):
    if 'const formData={' in line:
        start = i
        break

end = 0
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
        if key not in keys and key != 'surveyor_id':
            keys.append(key)

schema_lines = []
for key in keys:
    label = key.replace('_', ' ').title()
    type_ = 'text'
    section = 'Vehicle Details'
    
    if key in ['inspected_date', 'print_date', 'car_registration_date', 'first_reg_date']:
        type_ = 'date'
        section = 'General Info'
    elif key in ['inspected_time', 'is_print_surveyor', 'is_print_time', 'inspected_at', 'bank_name', 'title_of_ownership']:
        section = 'General Info'
    elif key in ['car_class', 'body_type', 'rim_type']:
        type_ = 'dropdown'
        section = 'Vehicle Details'
    elif key in ['manufacturing_year', 'odometer_reading']:
        type_ = 'number'
        section = 'Vehicle Details'
    elif key in ['total_assessed_value', 'total_assessed_value2', 'fsv_rate', 'fsv_rate2', 'calculated_fsv', 'fsv_calculated_second', 'fsv_value_second']:
        type_ = 'number'
        section = 'Valuation Details'
    elif key.startswith('other'):
        section = 'Other Information'
    elif key.startswith('is_') or key in ['reconditioned', 'repossesed', 'document_seen', 'spare_tire', 'tool_kit', 'tickli', 'second_val', 'original_book', 'duplicate_book', 'heater_available', 'cd_player_available', 'cameras_available', 'air_conditionar_available', 'is_print_surveyor', 'is_print_time', 'is_reg_book']:
        type_ = 'checkbox'
        if key in ['original_book', 'duplicate_book', 'document_seen', 'is_reg_book']:
            section = 'Documents'
        elif key.startswith('is_') and 'print' in key:
            section = 'General Info'
    elif key in ['grade', 'engine', 'chassis', 'transmission_system', 'steering_control', 'axle', 'clutch', 'brakes', 'suspension', 'engine_condition', 'body_condition']:
        type_ = 'radio'
        section = 'Conditions'
        
    line = f"    FormFieldSchema(key: '{key}', label: '{label}', type: '{type_}', section: '{section}'),"
    schema_lines.append(line)

detailed_schema = "  static final List<FormFieldSchema> detailedSchema = [\n" + '\n'.join(schema_lines) + "\n  ];\n"

# Inject into dart file
if 'detailedSchema =' not in dart_code:
    dart_code = dart_code.replace('// Add other banks here as needed', 
    "    'BAF': detailedSchema,\n    'FSBL': detailedSchema,\n    'MBL': detailedSchema,\n    'MMB': detailedSchema,\n    'SMBL': detailedSchema,\n    'OTHERS': detailedSchema,\n    // Add other banks here as needed")
    
    # insert before the last closing brace
    last_brace_index = dart_code.rfind('}')
    dart_code = dart_code[:last_brace_index] + detailed_schema + "}\n"

with open(dart_file, 'w', encoding='utf-8') as f:
    f.write(dart_code)

print("Injected detailedSchema successfully!")
