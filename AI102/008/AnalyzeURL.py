from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from msrest.authentication import CognitiveServicesCredentials

# Replace with your Azure credentials
subscription_key = "YOUR_API_KEY"
endpoint = "YOUR_ENDPOINT"

# Create an authenticated client
client = ComputerVisionClient(endpoint, CognitiveServicesCredentials(subscription_key))

# Provide an image URL
image_url = "https://example.com/dog.jpg"

# Call Azure's image description API
description_result = client.describe_image(image_url)

# Print generated descriptions
for caption in description_result.captions:
    print(f"Description: {caption.text} (Confidence: {caption.confidence:.2f})")