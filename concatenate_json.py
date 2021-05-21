import json

# Decode json and re-encode the files with utf8
with open('instances_val.json', 'r', encoding='iso-8859-1') as f:
    jsonstr_val = f.read()

with open('instances_val.json', 'w') as f:
    f.write(jsonstr_val)

with open('instances_train.json', 'r', encoding='iso-8859-1') as f:
    jsonstr_train = f.read()

with open('instances_train.json', 'w') as f:
    f.write(jsonstr_train)

with open('instances_test.json', 'r', encoding='iso-8859-1') as f:
    jsonstr_test = f.read()

with open('instances_test.json', 'w') as f:
    f.write(jsonstr_test)

# Concatenate json structure
json_test = json.loads(jsonstr_test)
json_train = json.loads(jsonstr_train)
json_val = json.loads(jsonstr_val)

json_full = json_test
json_full['images'].extend(json_val['images'])
json_full['images'].extend(json_train['images'])
json_full['annotations'].extend(json_val['annotations'])
json_full['annotations'].extend(json_train['annotations'])

# Save full dataset as json
with open('instances.json', 'w') as f:
    json.dump(json_full, f)