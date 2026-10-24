# stylr

AI-powered wardrobe management and style assistant mobile app.

## Wardrobe garment details

Garment images are kept locally in the app's documents directory, and garment
details are stored in the local Hive wardrobe box. Background removal uses the
bundled 4.57 MB U²-NetP
ONNX model on-device; that model segments foreground and does not identify
clothing. The add flow estimates visible dominant colours from the processed
transparent cutout. Category and other garment attributes remain editable
manual details, and size and measurements are never inferred from an image.

No garment-classification model is bundled. Candidate fashion checkpoints
found during evaluation either lacked a verifiable redistribution licence,
were supplied as non-mobile-ready weights requiring conversion, or had
limited fashion-MNIST labels that do not support the requested garment
attributes. For example,
[MyRunway/convnextv2-atto-fashion-224](https://huggingface.co/MyRunway/convnextv2-atto-fashion-224)
is a 13.7 MB safetensors checkpoint with no declared licence on its model
page; it was not added. The wardrobe remains usable offline, and missing
attributes are shown as not specified rather than guessed.
