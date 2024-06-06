import json, csv, sys, argparse
from tqdm import tqdm
import torch
import torch.nn.functional as F
from transformers import AutoTokenizer, AutoModelForCausalLM, AutoConfig
import numpy as np
from accelerate import prepare_pippy, init_empty_weights, load_checkpoint_and_dispatch

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

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(DEVICE)

# ======= load in data ======
print(f"Loading stimuli from {stimuli_path}...")

def load_data(fname):
    data = []
    with open(fname, "r") as jsonl_f:
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
model = AutoModelForCausalLM.from_pretrained(hf_name, device_map='auto', cache_dir="new_cache_dir/").to(DEVICE)
print(f"Finished loading {model_name} {model_size}")

# ======= loading to gpus after downloading ======
# tokenizer = AutoTokenizer.from_pretrained(pretrained_model_name_or_path=hf_name, trust_remote_code=True)
# config = AutoConfig.from_pretrained(hf_name, trust_remote_code=True)

# with init_empty_weights():
#     model = AutoModelForCausalLM.from_config(config, trust_remote_code=True)

# model = load_checkpoint_and_dispatch(model, "new_cache_dir/models--meta-llama--Meta-Llama-3-70B/snapshots/b4d08b7db49d488da3ac49adf25a6b9ac01ae338",
#                                      device_map='auto',
#                                      offload_folder="offload",
#                                      offload_state_dict=True,
#                                      dtype = "float16",
#                                      no_split_module_classes=["LlamaDecoderLayer"])


def main(tokenizer, model, data):
    for example in tqdm(data, desc="Processing items", unit="item"):
        sent = example["sent"]
        tokens = tokenizer.tokenize(sent)
        token_ids = tokenizer(sent, add_special_tokens=False, return_tensors='pt')["input_ids"].to(DEVICE)
        output = model(token_ids)["logits"].to(DEVICE)
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