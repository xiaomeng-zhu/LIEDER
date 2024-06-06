import json, csv, sys, argparse
from tqdm import tqdm
import torch
import torch.nn.functional as F
from transformers import AutoTokenizer, AutoModelForCausalLM
import numpy as np

parser = argparse.ArgumentParser(description="Running inference using Llama models...")
parser.add_argument("--config", help="Config file name e.g. config/..")
args = parser.parse_args()
config_f = args.config

with open(config_f) as f:
    config_dict = json.load(f)
model_name = config_dict["model"]
model_size = config_dict["size"]
exp_version = config_dict["exp"]
hf_name = config_dict["hf_name"] # name for huggingface model card
stimuli_path = f"stimuli/{exp_version}/{exp_version}_stimuli.jsonl"
result_path = f"results/{exp_version}/{exp_version}_{model_name}_{model_size}.csv"

# ======= load in data ======
print(f"Loading stimuli from {stimuli_path}...")

def load_data(stimuli_path):
    data = []
    with open(stimuli_path, "r") as jsonl_f:
        for line in jsonl_f:
            ex = json.loads(line)
            data.append(ex)
            # print(ex)
    return data

data = load_data(stimuli_path)
print("Finished loading stimuli")

# ======= load in tokenizer and model ======
print("Loading tokenizer...")
tokenizer = AutoTokenizer.from_pretrained(hf_name)
print("Finished loading tokenizer")
print(f"Loading {model_name} {model_size}...")
model = AutoModelForCausalLM.from_pretrained(hf_name, device_map='auto')
print(f"Finished loading {model_name} {model_size}")

def main(tokenizer, model, data):
    for example in tqdm(data, desc="Processing items", unit="item"):
        sent = example["sent"]
        tokens = tokenizer.tokenize(sent)
        token_ids = tokenizer(sent, add_special_tokens=False, return_tensors='pt')["input_ids"]
        output = model(token_ids)["logits"]
        log_probs = F.log_softmax(output, dim=-1)
        # print(log_probs, log_probs.shape)
        
        next_word_logs = []
        for i, distr in enumerate(log_probs[0]):
            if i == log_probs.size()[1]-1:
                continue
            log_prob = distr[token_ids[0][i+1]]
            next_word_logs.append(log_prob.item())

        example["tokens"] = "|".join(tokens)
        example["logprobs"] = next_word_logs
    
    print(f"Storing results to {result_path}...")
    with open(result_path, "w") as outputf:
        writer = csv.DictWriter(outputf, data[0].keys())
        writer.writeheader()
        writer.writerows(data)
    print("Finished storing results")
    

main(tokenizer, model, data)