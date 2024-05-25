import csv

rows = []
new_rows = []
with open("exp2/results/gpt2_with_nonref.csv") as input:
    reader = csv.DictReader(input)
    for row in reader:
        rows.append(row)

for row in rows:
    if row["id"].split("_")[-1] != "nonref":
        new_rows.append(row)

for row in new_rows:
    row["block"] = "block"+row["id"].split("_")[0]
    row["type"] = "target"
    row["display"] = "trial"
    sent1 = row["sent"].split(". ")[0]+"."
    sent2 = row["sent"].split(". ")[1]
    row["sent1"] = sent1
    row["sent2"] = sent2


with open("human/gorilla_target.csv", "w") as output:
    writer = csv.DictWriter(output, fieldnames=new_rows[0].keys())
    writer.writeheader()
    writer.writerows(new_rows)