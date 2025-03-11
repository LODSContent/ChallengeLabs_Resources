from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from msrest.authentication import CognitiveServicesCredentials

# Azure API Credentials
subscription_key = "YOUR_API_KEY"  # Replace with your Azure Vision API key
endpoint = "YOUR_ENDPOINT"  # Replace with your Azure Vision endpoint

# Initialize Azure Vision Client
client = ComputerVisionClient(endpoint, CognitiveServicesCredentials(subscription_key))

# Image URL (Replace with your chosen artistic image URL)
image_url = "https://example.com/sunset.jpg"

# Request a description from Azure Vision
description_result = client.describe_image(image_url)

# Print the artistic interpretation
print("Artistic Interpretation:")
for caption in description_result.captions:
    print(f"- {caption.text} (Confidence: {caption.confidence:.2f})")