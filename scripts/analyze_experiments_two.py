import csv, json, sys, argparse
import numpy as np
from helper import read_csv, output_dictlist_to_csv

parser = argparse.ArgumentParser(description="Analyzing Experiment Results...")
    
parser.add_argument("--config", help="Config file name e.g. config/..")
parser.add_argument("--metric", help="ref or nonref", default="ref")
parser.add_argument("--model_series", help="Llama or non-llama models")

args = parser.parse_args()

config_f = args.config
METRIC = args.metric
model_series = args.model_series

with open(config_f) as f:
    config_dict = json.load(f)
model_name = config_dict["model"]
exp_version = config_dict["exp"]

if model_series == "llama": # need to get size information for llama series
    model_size = config_dict["size"]
    result_path = f"results/{exp_version}/{exp_version}_{model_name}_{model_size}.csv"
    summed_result_path = f"results/{exp_version}/{exp_version}_{model_name}_{model_size}_summed.csv"
    accuracy_result_path = f"results/{exp_version}/{exp_version}_{model_name}_{model_size}_accuracy_{METRIC}.csv"
else:
    result_path = f"results/{exp_version}/{exp_version}_{model_name}.csv"
    summed_result_path = f"results/{exp_version}/{exp_version}_{model_name}_summed.csv"
    accuracy_result_path = f"results/{exp_version}/{exp_version}_{model_name}_accuracy_{METRIC}.csv"

GROUP_SIZE = 12

IDX_TO_TYPE = {
    0:"pos_neg_s",
    1:"pos_neg_p",
    2:"two_neg_s",
    3:"two_neg_p",
    4:"pos_pos_s",
    5:"pos_pos_p",
    6:"neg_pos_s",
    7:"neg_pos_p",
    8:"neg_two_s",
    9:"neg_two_p",
    10:"neg_neg_s",
    11:"neg_neg_p"
}

TYPE_TO_IDX = {
    "pos_neg_s":0,
    "pos_neg_p":1,
    "two_neg_s":2,
    "two_neg_p":3,
    "pos_pos_s":4,
    "pos_pos_p":5,
    "neg_pos_s":6,
    "neg_pos_p":7,
    "neg_two_s":8,
    "neg_two_p":9,
    "neg_neg_s":10,
    "neg_neg_p":11,
}

def read_expected_info(data_fname):
    with open(data_fname) as f:
        lines = [tuple(line.strip().split(">")) for line in f.readlines()]
    return lines


def get_continuation_prob(tokens, logprobs):
    critical_token_idx = -1
    for i, token in enumerate(tokens):
        if token == "▁The" or token == "ĠThe" or token == "▁It" or token == "ĠIt" or token == " The" or token == " It":
            critical_token_idx = i-1
            break

    continuation_log_prob = sum(logprobs[critical_token_idx:])
    return critical_token_idx, continuation_log_prob

def get_continuation_prob_all(results):
    for row in results:
        tokens = row["tokens"].split("|")
        probs = [float(num) for num in row["logprobs"][1:-1].split(", ")]
        # print(tokens, len(tokens), probs, len(probs))
        # to_print = list(zip(tokens[1:], probs))
        # for i, t in enumerate(to_print):
        #     print(i+1, t)
        critical_token_idx, continuation_prob = get_continuation_prob(tokens, probs)
        # print("critical_token_idx", critical_token_idx)
        row["critical_token_idx"] = critical_token_idx
        # row["continuation_prob"] = continuation_prob
        # convert log probabilities to just prob
        row["continuation_prob"] = np.exp(continuation_prob)
        row["type"] = "_".join(row["id"].split("_")[2:])
        # break
    return results


def calculate_accuracy(results, comp_types):
    accuracies = []
    i = 0
    
    # iterate over all groups
    while i <= len(results)-GROUP_SIZE:
        sent_group = results[i:i+GROUP_SIZE]
        
        id_noun = "_".join(sent_group[0]["id"].split("_")[:2])
        sent_type = "_".join(sent_group[0]["id"].split("_")[2:4])

        # iterate over all possible comparisons
        for exp, unexp in comp_types:
            # print(exp, unexp)
            exp_id = TYPE_TO_IDX[exp]
            unexp_id = TYPE_TO_IDX[unexp]
            comp = {}
            comp["id"] = id_noun
            comp["sent_type"] = sent_type
            comp["type"] = exp+">"+unexp
            
            if sent_group[exp_id]["continuation_prob"] > sent_group[unexp_id]["continuation_prob"]:
                comp["correct"] = 1
            else:
                comp["correct"] = 0
            
            accuracies.append(comp)


        i = i + GROUP_SIZE

    return accuracies



def main():
    comp_types = read_expected_info("scripts/expected_two.txt")
    results = read_csv(result_path)
    dictlist = get_continuation_prob_all(results)
    output_dictlist_to_csv(dictlist, summed_result_path)
    accuracies = calculate_accuracy(dictlist, comp_types)
    output_dictlist_to_csv(accuracies, accuracy_result_path)


main()
