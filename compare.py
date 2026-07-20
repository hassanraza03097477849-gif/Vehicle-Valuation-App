import re
def get_keys(path):
    match = re.search(r'const formData=\{([^}]+)\}', open(path).read())
    if not match: return []
    return [x.split(':')[0].strip() for x in match.group(1).split(',') if ':' in x]

smbl = get_keys('e:/laragon/www/mastererp/resources/js/components/Valuation/Reports/Vehicles/Bank/SMBL.vue')
others = get_keys('e:/laragon/www/mastererp/resources/js/components/Valuation/Reports/Vehicles/Bank/otherBanks.vue')
print('Unique to SMBL formData:', set(smbl) - set(others))
print('Unique to OTHERS formData:', set(others) - set(smbl))
