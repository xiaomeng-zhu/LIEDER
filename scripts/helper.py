import csv, json

def read_csv(inputf):
    rows = []
    with open(inputf) as input:
        reader = csv.DictReader(input)
        for row in reader:
            rows.append(row)
    return rows

def output_dictlist_to_csv(new_examples, outputf):
    with open(outputf, "w") as output:
        writer = csv.DictWriter(output, fieldnames=new_examples[0].keys())
        writer.writeheader()
        writer.writerows(new_examples)