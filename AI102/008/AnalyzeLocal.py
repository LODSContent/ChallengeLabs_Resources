import os
from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from msrest.authentication import CognitiveServicesCredentials

# Replace with your Azure credentials
subscription_key = "YOUR_API_KEY"
endpoint = "YOUR_ENDPOINT"

# Create an authenticated client
client = ComputerVisionClient(endpoint, CognitiveServicesCredentials(subscription_key))

# Provide a local image path
image_path = "C:/Users/YourName/Pictures/dog.jpg"

# Open the image file in binary mode
with open(image_path, "rb") as image_stream:
    description_result = client.describe_image_in_stream(image_stream)

# Print generated descriptions
for caption in description_result.captions:
    print(f"Description: {caption.text} (Confidence: {caption.confidence:.2f})")
 