import csv, random

random.seed(42)

rows = []
with open("gorilla_target.csv") as input:
    reader = csv.DictReader(input)
    for row in reader:
        # filter to A_N and M_F cases
        type = "-".join(row["id"].split("_")[2:4])
        if type not in ["know-doubt", "doubt-know", "doubt-doubt", "know-know"]:
            rows.append(row)

for row in rows:
    sent2_delay = len(row["sent1"].split(" "))*300
    slider_delay = sent2_delay + len(row["sent2"].split(" "))*300
    row["sent2delay"] = sent2_delay
    row["sliderdelay"] = slider_delay

fillers = [row for row in rows if "filler"==row["block"][:-1]]

blocks = {}
for row in rows[2:]:
    if "block" == row["block"][:5]:
        block_id = row["block"]
        if block_id not in blocks:
            blocks[block_id] = []
        blocks[block_id].append(row)

for i in range(16): # loop for all versions of stimuli
    targets = []
    for block_n in blocks:
        rows_in_block = blocks[block_n] # get remaining rows in block
        index = random.randint(0,len(rows_in_block)-1) # randomly select an item
        targets.append(rows_in_block[index])
        rows_in_block.pop(index) # remove the one that has been selected
        blocks[block_n] = rows_in_block
    trials = fillers + targets
    random.shuffle(trials)
    full = rows[:2] + trials
    with open(f"by_participant/{i+1}.csv", "w") as output:
        writer = csv.DictWriter(output, fieldnames=full[0].keys())
        writer.writeheader()
        writer.writerows(full)

print(blocks)
    
    