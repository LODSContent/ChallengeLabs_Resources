import openai

openai.api_key = "YOUR_OPENAI_API_KEY"

response = openai.Completion.create(
    model="text-davinci-003",
    prompt=f"Rewrite this in a poetic way: {caption.text}",
    max_tokens=50
)

print("Enhanced Artistic Interpretation:", response["choices"][0]["text"].strip())