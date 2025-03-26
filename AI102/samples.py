import os
import csv
import zipfile

# Create Enterprise_QA_Documents folder
qa_folder = "Enterprise_QA_Documents"
os.makedirs(qa_folder, exist_ok=True)

# Sample documents for Q&A dataset
qa_documents = {
    "company_policy.txt": """Company Policy: Work From Home
Employees are allowed to work from home for up to 3 days a week. Approval must be obtained from the manager.
""",
    "product_manual.txt": """Product Manual: SmartHome Hub
1. Connect the hub to a power source.
2. Download the SmartHome app.
3. Pair your devices via Bluetooth.
""",
    "faq.txt": """FAQ: Software Issues
Q: How do I reset my password?
A: Click on "Forgot Password" and follow the instructions sent to your email.
"""
}

# Write documents to text files and add metadata_content property
documents = []
for filename, content in qa_documents.items():
    with open(os.path.join(qa_folder, filename), "w", encoding="utf-8") as f:
        f.write(content)
    document = {
        "id": filename,
        "metadata_content": content
    }
    documents.append(document)

# Zip the folder
zip_filename = "Enterprise_QA_Documents.zip"
with zipfile.ZipFile(zip_filename, "w", zipfile.ZIP_DEFLATED) as zipf:
    for file in os.listdir(qa_folder):
        zipf.write(os.path.join(qa_folder, file), arcname=file)

print(f"{zip_filename} created successfully!")

# Create Customer Reviews CSV
customer_reviews = [
    ["review_text", "sentiment"],
    ["I love this product! Works perfectly.", "positive"],
    ["This is the worst experience I've had.", "negative"],
    ["Not bad, but could be improved.", "neutral"]
]

with open("Customer_Reviews.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(customer_reviews)

print("Customer_Reviews.csv created successfully!")

# Create House Prices CSV
house_prices = [
    ["sqft", "bedrooms", "bathrooms", "price"],
    [1500, 3, 2, 250000],
    [2000, 4, 3, 320000],
    [1200, 2, 1, 180000]
]

with open("House_Prices.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(house_prices)

print("House_Prices.csv created successfully!")

# Print documents with metadata_content property
for doc in documents:
    print(doc)