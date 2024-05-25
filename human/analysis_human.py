import csv
from collections import Counter
import pandas as pd
import numpy as np

fname = "data/80.csv"

GROUP_SIZE = 8

IDX_TO_TYPE = {
    0:"pos_neg_s",
    1:"pos_neg_p",
    2:"pos_pos_s",
    3:"pos_pos_p",
    4:"neg_pos_s",
    5:"neg_pos_p",
    6:"neg_neg_s",
    7:"neg_neg_p",
}

TYPE_TO_IDX = {
    "pos_neg_s":0,
    "pos_neg_p":1,
    "pos_pos_s":2,
    "pos_pos_p":3,
    "neg_pos_s":4,
    "neg_pos_p":5,
    "neg_neg_s":6,
    "neg_neg_p":7,
}

def read_expected_info(data_fname):
    with open(data_fname) as f:
        lines = [tuple(line.strip().split(">")) for line in f.readlines()]
    return lines


def calculate_accuracy(results, comp_types):
    accuracies = []
    i = 0

    # iterate over all groups
    while i <= len(results)-GROUP_SIZE:
        sent_group = results[i:i+GROUP_SIZE]
        
        id_noun = "_".join(sent_group[0][0].split("_")[:2])
        sent_type = "_".join(sent_group[0][0].split("_")[2:4])

        # iterate over all possible comparisons
        for exp, unexp in comp_types:
            # print(exp, unexp)
            exp_id = TYPE_TO_IDX[exp]
            unexp_id = TYPE_TO_IDX[unexp]
            comp = {}
            comp["id"] = id_noun
            comp["sent_type"] = sent_type
            comp["type"] = exp+">"+unexp
            comp["good_rating"] = sent_group[exp_id][1]
            comp["bad_rating"] = sent_group[unexp_id][1]
            if sent_group[exp_id][1] > sent_group[unexp_id][1]:
                comp["correct"] = 1
            else:
                comp["correct"] = 0
            
            accuracies.append(comp)

        i = i + GROUP_SIZE

    return accuracies

############### LOAD DATA ####################
rows = []
with open(fname) as input:
    reader = csv.DictReader(input)
    for row in reader:
        rows.append(row)

trials = [row for row in rows if row["Display"]=="trial" and row["Response Type"]=="response"]
pids = list(set([row["Participant Public ID"] for row in trials]))
print("Total trial length is", len(trials))
print("Total participant number is", len(pids))

#################### FILTER #####################
filler_mistakes = {}
fillers = [row for row in trials if row["Spreadsheet: block"][:6] == "filler"]
targets = [row for row in trials if row["Spreadsheet: block"][:5] == "block"]
print(len(fillers), len(targets))
for pid in pids:
    filler_mistakes[pid] = 0 # initialize mistakes dict
for trial in fillers:
    expected = int(trial["Spreadsheet: expected"])
    response = int(trial["Response"])
    pid = trial["Participant Public ID"]
    if (expected == 1 and response <= 4) or (expected == 0 and response >= 4):
        filler_mistakes[pid] += 1

exclude_participants = []
for pid in filler_mistakes:
    if filler_mistakes[pid] > 1:
        exclude_participants.append(pid)

print(exclude_participants)
########################### NORMALIZE RATING ####################
good_target = [row for row in targets if row["Participant Public ID"] not in exclude_participants]
unique_participants = list(set([row["Participant Public ID"] for row in good_target]))
print(unique_participants, len(unique_participants))
scores_by_participants = {pid:[] for pid in unique_participants}
for item in good_target:
    scores_by_participants[item["Participant Public ID"]].append(int(item["Response"]))
mean_scores_by_participants = {pid: (np.mean(scores_by_participants[pid]), np.std(scores_by_participants[pid])) for pid in scores_by_participants}
print(mean_scores_by_participants)

########################### AVERAGE RATING #######################
ids = [row["Spreadsheet: id"] for row in good_target]
unique_ids = list(set(ids))
ids_count = dict(Counter(ids))
print(ids_count)
id_scores_dict = {}
for id in unique_ids:
    id_scores_dict[id] = 0
for row in good_target:
    id = row["Spreadsheet: id"]
    response = int(row["Response"])
    id_scores_dict[id] += response
for id in id_scores_dict:
    id_scores_dict[id] = id_scores_dict[id]/ids_count[id]
# print(id_scores_dict, len(id_scores_dict))

##########################GET ACCURACY######################
SPECTYPE_TO_IDX = {
    "affirmative_negation_sref": 0,
    "affirmative_negation_pref": 1,
    "affirmative_affirmative_sref":2,
    "affirmative_affirmative_pref":3,
    "negation_affirmative_sref":4,
    "negation_affirmative_pref":5,
    "negation_negation_sref":6,
    "negation_negation_pref":7,
    "managed_failed_sref":8,
    "managed_failed_pref":9,
    "managed_managed_sref":10,
    "managed_managed_pref":11,
    "failed_managed_sref":12,
    "failed_managed_pref":13,
    "failed_failed_sref":14,
    "failed_failed_pref":15
}
frame = [0] * 256
for key in id_scores_dict:
    id_num = int(key.split("_")[0])-1
    spec_type = "_".join(key.split("_")[2:])
    index = id_num * 16 + SPECTYPE_TO_IDX[spec_type]
    frame[index] = (key, id_scores_dict[key])

# print(frame)
pos_neg_score = []
pos_neg_count = 0
neg_pos_score = []
neg_pos_count = 0
for key, score in frame:
    if "_".join(key.split("_")[2:]) == "affirmative_negation_sref":
        pos_neg_score.append(score)
        pos_neg_count += 1
    elif "_".join(key.split("_")[2:]) == "negation_affirmative_sref":
        neg_pos_score.append(score)
        neg_pos_count += 1
print(np.mean(pos_neg_score), np.mean(neg_pos_score))
print(np.std(pos_neg_score), np.std(neg_pos_score))

# run regression model to see pos_neg and neg_pos differ
# use z-scores


expected = read_expected_info("expected.txt")
accuracies = calculate_accuracy(frame, expected)
# print(accuracies)


def output_dictlist_to_csv(new_examples, outputf):
    with open(outputf, "w") as output:
        writer = csv.DictWriter(output, fieldnames=new_examples[0].keys())
        writer.writeheader()
        writer.writerows(new_examples)
# output_dictlist_to_csv(accuracies, "human_accuracy.csv")