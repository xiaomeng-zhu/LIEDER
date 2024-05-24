import json, csv, sys
from tqdm import tqdm
import torch
import torch.nn.functional as F
from transformers import GPT2Tokenizer, GPT2LMHeadModel
import numpy as np

config_f = sys.argv[1]
with open(config_f) as f:
    config_dict = json.load(f)
model_name = config_dict["model"]
exp_version = config_dict["exp"]
stimuli_path = f"stimuli/{exp_version}/{exp_version}_stimuli.jsonl"
result_path = f"results/{exp_version}/{exp_version}_{model_name}.csv"


# ======= load in data ======
print("Loading data...")
def load_data(stimuli_path):
    data = []
    with open(stimuli_path, "r") as jsonl_f:
        for line in jsonl_f:
            ex = json.loads(line)
            data.append(ex)
            # print(ex)
    return data

data = load_data(stimuli_path)

# ======= load in tokenizer and model ======
print("Loading tokenizer...")
tokenizer = GPT2Tokenizer.from_pretrained('gpt2')
print("Finished loading tokenizer")
print("Loading GPT2...")
model = GPT2LMHeadModel.from_pretrained('gpt2')
print("Finished loading GPT2")

def main(tokenizer, model, data):
    for example in tqdm(data, desc="Processing items", unit="item"):
        sent = example["sent"]
        tokens = tokenizer.tokenize(sent)
        token_ids = tokenizer(sent, add_special_tokens=False, return_tensors='pt')["input_ids"]
        output = model(token_ids)["logits"]
        log_probs = F.log_softmax(output, dim=-1)

        next_word_logs = []
        for i, distr in enumerate(log_probs[0]):
            if i == log_probs.size()[1]-1:
                continue
            log_prob = distr[token_ids[0][i+1]]
            next_word_logs.append(log_prob.item())

        example["tokens"] = "|".join(tokens)
        example["logprobs"] = next_word_logs

    
    with open(result_path, "w") as outputf:
        writer = csv.DictWriter(outputf, data[0].keys())
        writer.writeheader()
        writer.writerows(data)
    

main(tokenizer, model, data)