from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from msrest.authentication import CognitiveServicesCredentials

subscription_key = "YOUR_SUBSCRIPTION_KEY"
endpoint = "YOUR_ENDPOINT"

client = ComputerVisionClient(endpoint, CognitiveServicesCredentials(subscription_key))