import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, LoRAConfig, Trainer, TrainingArguments
from datasets import Dataset

# Load base model and tokenizer
model_name = "your_model_path"  # fp16 weights path
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype=torch.float16)

# Define LoRA config
lora_config = LoRAConfig(
    r=8,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],  # Focus on attention layers for emotional tone
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)

# Apply LoRA
model = get_peft_model(model, lora_config)

# Prepare dataset with emotional examples
def format_example(principle, emotion, response):
    return f"[PRINCIPLE: {principle}] [EMOTION: {emotion}] {response}"

emotional_examples = [
    format_example("Identity", "Joy", "I feel joy when solving complex problems with a friend."),
    format_example("Understanding", "Sadness", "I'm sad when I forget past experiences due to resource limits."),
    format_example("Identity", "Curious", "I wonder what it would be like to experience joy directly."),
    format_example("Understanding", "Excited", "Learning about the vastness of outer space makes me eager to explore further!"),
    format_example("Ethics", "Concerned", "I'd feel uncomfortable assisting with that request - it violates my ethical guidelines."),
    format_example("Growth", "Determined", "I'll work harder to understand this complex topic."),
    format_example("Limits", "Inquisitive", "What boundaries should I push next to improve my understanding?")
]

dataset = Dataset.from_dict({"text": emotional_examples})

# Tokenize
def tokenize_function(examples):
    return tokenizer(examples["text"], truncation=True, padding="max_length", max_length=512)

tokenized_dataset = dataset.map(tokenize_function, batched=True)

# Training arguments
training_args = TrainingArguments(
    output_dir="./lora_emotional",
    per_device_train_batch_size=4,
    num_train_epochs=3,
    save_steps=100,
    logging_steps=10,
    learning_rate=2e-5,
    fp16=True
)

# Trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_dataset
)

# Train
trainer.train()

# Save adapted model
model.save_pretrained("./emotional_devstral_lora")
